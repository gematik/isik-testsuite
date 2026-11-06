#!/usr/bin/env python3
"""Prepare or import ISiK fixtures through standard FHIR R4 transactions (Python 3.10+)."""
import argparse
from contextlib import contextmanager
from copy import deepcopy
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parents[2]
IDENTITY = re.compile(r"([A-Z][A-Za-z]+)/([A-Za-z0-9.-]{1,64})")
FORBIDDEN = {"SearchParameter", "CapabilityStatement", "StructureDefinition", "ImplementationGuide"}


class ImportProblem(RuntimeError):
    pass


def require(condition, message):
    if not condition:
        raise ImportProblem(message)


def normalize_base(value):
    value = value.rstrip("/")
    url = urllib.parse.urlsplit(value)
    require(url.scheme in {"http", "https"} and url.hostname and not url.username and not url.password
            and not url.query and not url.fragment and not any(c.isspace() for c in value),
            "FHIR URL must be an HTTP(S) base without credentials, query or fragment")
    return value


def save(path, value):
    """Replace an owned output atomically; persist state before submitting a transaction."""
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    content = value if isinstance(value, str) else json.dumps(value, indent=2, ensure_ascii=False) + "\n"
    descriptor, temporary = tempfile.mkstemp(dir=path.parent, prefix=".writing-")
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


@contextmanager
def lock(output):
    output.mkdir(parents=True, exist_ok=True, mode=0o700)
    path = output / ".lock"
    try:
        stream = path.open("x")
    except FileExistsError:
        raise ImportProblem(f"Output is locked: {path}. Check for an active importer before removing a stale lock.") from None
    try:
        with stream:
            stream.write(str(os.getpid()))
        yield
    finally:
        path.unlink(missing_ok=True)


def pointer_parts(pointer):
    require(pointer.startswith("/"), "Resource link paths must be JSON pointers starting with /")
    return [part.replace("~1", "/").replace("~0", "~") for part in pointer[1:].split("/")]


def at_pointer(resource, pointer, replacement=None):
    parts = pointer_parts(pointer)
    node = resource
    try:
        for part in parts[:-1]:
            node = node[int(part)] if isinstance(node, list) else node[part]
        key = int(parts[-1]) if isinstance(node, list) else parts[-1]
        old = node[key]
        if replacement is not None:
            node[key] = replacement
        return old
    except (KeyError, IndexError, ValueError, TypeError):
        raise ImportProblem(f"Resource link path does not exist: {pointer}") from None


def references(value, path=""):
    if isinstance(value, dict):
        for key, child in value.items():
            child_path = path + "/" + key.replace("~", "~0").replace("/", "~1")
            if key == "reference" and isinstance(child, str):
                yield child_path, child
            else:
                yield from references(child, child_path)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from references(child, path + "/" + str(index))


def yaml_lines(text):
    """Read the suite's flat scalar maps without coercing identifiers or dates."""
    result = {}
    for index, line in enumerate(text.splitlines(keepends=True)):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        match = re.fullmatch(r"([A-Za-z0-9_.-]+):[ \t]*(.*?)\s*", line)
        require(match is not None, "Only flat YAML scalar maps are supported")
        key, value = match.groups()
        require(key not in result, f"Duplicate YAML key: {key}")
        if value.startswith('"'):
            value = json.loads(value)
        elif value.startswith("'"):
            require(value.endswith("'"), f"Invalid quoted YAML value: {key}")
            value = value[1:-1].replace("''", "'")
        result[key] = (index, value)
    return result


def load_inputs(bundle_path, mapping_path, config_dir):
    bundle_bytes, mapping_bytes = bundle_path.read_bytes(), mapping_path.read_bytes()
    bundle, mapping = json.loads(bundle_bytes), json.loads(mapping_bytes)
    require(bundle.get("resourceType") == "Bundle" and bundle.get("type") == "transaction"
            and bundle.get("entry"), "Input must be a nonempty transaction Bundle")
    resources, aliases = {}, {}
    for entry in bundle["entry"]:
        resource = entry.get("resource", {})
        identity = f"{resource.get('resourceType', '')}/{resource.get('id', '')}"
        require(IDENTITY.fullmatch(identity) is not None, "Each fixture needs a valid ResourceType/id")
        require(resource["resourceType"] not in FORBIDDEN, f"Dataset must not install {resource['resourceType']}")
        require(identity not in resources, f"Duplicate fixture: {identity}")
        require(entry.get("request") == {"method": "PUT", "url": identity},
                f"Source entry must PUT its fixture identity: {identity}")
        resources[identity] = resource
        for alias in {identity, entry.get("fullUrl", identity)}:
            require(alias not in aliases or aliases[alias] == identity, "Duplicate fixture fullUrl")
            aliases[alias] = identity
    require(mapping.get("schemaVersion") == 1 and isinstance(mapping.get("configuration"), dict),
            "Mapping requires schemaVersion 1 and a configuration object")
    links = []
    for identity, resource in resources.items():
        contained = {item.get("id") for item in resource.get("contained", [])}
        for pointer, value in references(resource):
            if value.startswith("#"):
                require(value[1:] in contained, f"Missing contained target in {identity}: {pointer}")
                continue
            require(value in aliases, f"Reference outside the fixture bundle in {identity}: {pointer}")
            links.append({"resource": identity, "path": pointer, "target": aliases[value]})
    for link in mapping.get("resourceLinks", []):
        identity, pointer, target = link["resource"], link["path"], link["target"]
        require(identity in resources and target in resources, "Mapped resource link has an unknown resource")
        require(aliases.get(at_pointer(resources[identity], pointer)) == target,
                f"Resource link no longer matches mapping: {identity} {pointer}")
        require(not any(item["resource"] == identity and item["path"] == pointer for item in links),
                "Resource link is mapped more than once")
        links.append(link)
    configs, hashes = {}, {"bundle": hashlib.sha256(bundle_bytes).hexdigest(),
                           "mapping": hashlib.sha256(mapping_bytes).hexdigest()}
    for filename, fields in mapping["configuration"].items():
        require(Path(filename).name == filename and filename.endswith(".yaml") and filename != "connect.yaml",
                "Mapping filenames must be clinical module YAML basenames; Connect is provisioned separately")
        raw = (config_dir / filename).read_bytes()
        configs[filename] = raw.decode("utf-8")
        hashes[filename] = hashlib.sha256(raw).hexdigest()
        values = yaml_lines(configs[filename])
        for key, field in fields.items():
            require(field["resource"] in resources and field["format"] in {"id", "reference"},
                    f"Invalid configuration mapping: {filename} {key}")
            expected = field["resource"] if field["format"] == "reference" else field["resource"].split("/")[1]
            require(key in values and values[key][1] == expected,
                    f"Configuration differs from fixture mapping: {filename} {key}")
    return resources, links, mapping, configs, hashes


def make_transaction(resources, links, base, mode):
    urls = {identity: ("urn:uuid:" + str(uuid.uuid4()) if mode == "server-assigned" else base + "/" + identity)
            for identity in resources}
    copied = deepcopy(resources)
    for link in links:
        at_pointer(copied[link["resource"]], link["path"], urls[link["target"]])
    entries = []
    for identity, resource in copied.items():
        if mode == "server-assigned":
            resource.pop("id")
        request = {"method": "POST", "url": identity.split("/")[0]} if mode == "server-assigned" else {"method": "PUT", "url": identity}
        entries.append({"fullUrl": urls[identity], "resource": resource, "request": request})
    return {"resourceType": "Bundle", "type": "transaction", "entry": entries}


class NoRedirects(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class FhirClient:
    def __init__(self, base, token, timeout):
        require(not token or not any(c.isspace() for c in token), "Token must not contain whitespace")
        self.base, self.token, self.timeout = base, token, timeout
        self.opener = urllib.request.build_opener(NoRedirects())

    def request(self, method, path, resource=None):
        headers = {"Accept": "application/fhir+json"}
        if self.token:
            headers["Authorization"] = "Bearer " + self.token
        body = None
        if resource is not None:
            headers.update({"Content-Type": "application/fhir+json", "Prefer": "return=minimal"})
            body = json.dumps(resource).encode("utf-8")
        req = urllib.request.Request(self.base + "/" + path, data=body, headers=headers, method=method)
        try:
            with self.opener.open(req, timeout=self.timeout) as response:
                result = json.loads(response.read())
                require(isinstance(result, dict), "FHIR response must be a JSON object")
                return result
        except urllib.error.HTTPError as error:
            # Do not copy HTTP bodies, headers, credentials or response URLs into output.
            status = error.code
            error.close()
            raise ImportProblem(f"FHIR {method} {path or '[base]'} returned HTTP {status}; inspect server diagnostics") from None
        except (urllib.error.URLError, TimeoutError, OSError):
            raise ImportProblem(f"FHIR {method} {path or '[base]'} failed at the network layer") from None
        except (ValueError, UnicodeError):
            raise ImportProblem("Server returned an invalid JSON response") from None


def check_capabilities(capability, resources, mode):
    require(capability.get("resourceType") == "CapabilityStatement"
            and capability.get("fhirVersion", "").startswith("4.0."), "Server must advertise FHIR R4 (4.0.x)")
    require(any(value.lower() in {"json", "application/json", "application/fhir+json"}
                for value in capability.get("format", [])), "Server must advertise JSON support")
    rest = [item for item in capability.get("rest", []) if item.get("mode") == "server"]
    require(any(i.get("code") == "transaction" for item in rest for i in item.get("interaction", [])),
            "Server does not advertise transaction support")
    types = {identity.split("/")[0] for identity in resources}
    for kind in sorted(types):
        supported = [item for server in rest for item in server.get("resource", []) if item.get("type") == kind]
        operations = {i.get("code") for item in supported for i in item.get("interaction", [])}
        required = {"read", "create" if mode == "server-assigned" else "update"}
        require(required <= operations, f"Server does not advertise {', '.join(sorted(required))} for {kind}")
        if mode == "preserve":
            require(any(item.get("updateCreate") is True for item in supported),
                    f"Server does not advertise updateCreate for {kind}; use server-assigned mode")


def local_identity(location, base, expected_type):
    require(isinstance(location, str), "Transaction response is missing a resource location")
    if location.startswith(base + "/"):
        location = location[len(base) + 1:]
    parts = location.split("/")
    require(len(parts) == 2 or (len(parts) == 4 and parts[2] == "_history" and parts[3]),
            "Response location must identify a resource on the configured FHIR base")
    identity = "/".join(parts[:2])
    require(IDENTITY.fullmatch(identity) is not None and parts[0] == expected_type,
            "Response location has an invalid resource type or ID")
    return identity


def response_mapping(response, resources, base, mode):
    entries = response.get("entry", [])
    require(response.get("resourceType") == "Bundle" and response.get("type") == "transaction-response"
            and len(entries) == len(resources), "Expected one transaction response entry for every fixture")
    result = {}
    for original, entry in zip(resources, entries):
        details = entry.get("response", {})
        require(re.fullmatch(r"2\d\d(?: .*)?", details.get("status", "")) is not None,
                f"Transaction entry did not succeed: {original}")
        identity = local_identity(details.get("location"), base, original.split("/")[0])
        require(mode != "preserve" or identity == original, f"Server did not preserve fixture identity: {original}")
        require(identity not in result.values(), "Server mapped multiple fixtures to the same resource")
        result[original] = identity
    return result


def verify_resources(client, resources, links, identities):
    for original in resources:
        identity = identities[original]
        resource = client.request("GET", identity)
        require(f"{resource.get('resourceType')}/{resource.get('id')}" == identity,
                f"Read-back returned a different resource: {identity}")
        for link in (item for item in links if item["resource"] == original):
            target = identities[link["target"]]
            value = at_pointer(resource, link["path"])
            require(local_identity(value, client.base, target.split("/")[0]) == target,
                    f"Read-back reference was not resolved: {identity} {link['path']}")


def write_configs(output, configs, mapping, identities):
    for filename, text in configs.items():
        lines, values = text.splitlines(keepends=True), yaml_lines(text)
        for key, field in mapping["configuration"][filename].items():
            identity = identities[field["resource"]]
            value = identity if field["format"] == "reference" else identity.split("/")[1]
            index = values[key][0]
            lines[index] = key + ": " + json.dumps(value) + "\n"
        save(output / "configs" / filename, "".join(lines))


def run(args):
    os.umask(0o077)
    base = normalize_base(args.fhir_url)
    require(args.timeout > 0, "Timeout must be positive")
    mapping_path = args.mapping or args.bundle.parent / "config-mapping.json"
    resources, links, mapping, configs, hashes = load_inputs(args.bundle, mapping_path, args.config_dir)
    specification = {"fhirBase": base, "idMode": args.id_mode, "inputHashes": hashes}
    output = args.output.resolve()
    with lock(output):
        path = output / "manifest.json"
        if path.exists():
            manifest = json.loads(path.read_text())
            require(manifest.get("schemaVersion") == 1 and manifest.get("inputs") == specification,
                    "Output manifest belongs to different inputs or server; use its original inputs")
            require(manifest.get("state") in {"planned", "imported", "complete"},
                    "Previous submission has an uncertain outcome. Do not resubmit or use a new output directory "
                    "until the server resources have been reconciled; this prevents duplicate imports.")
            transaction = json.loads((output / "transaction.json").read_text())
            require(hashlib.sha256(json.dumps(transaction, sort_keys=True).encode()).hexdigest()
                    == manifest.get("transactionSha256"), "Prepared transaction changed; refusing to submit it")
        else:
            require(not any(p.name != ".lock" for p in output.iterdir()), "Output directory must be empty for a new plan")
            transaction = make_transaction(resources, links, base, args.id_mode)
            manifest = {"schemaVersion": 1, "state": "planned", "inputs": specification,
                        "resources": len(resources), "configurationFields": sum(map(len, mapping["configuration"].values())),
                        "transactionSha256": hashlib.sha256(json.dumps(transaction, sort_keys=True).encode()).hexdigest()}
            save(output / "transaction.json", transaction)
            save(path, manifest)
        if not args.execute:
            print(f"Dry run: {len(resources)} resources, {len(links)} links, {manifest['configurationFields']} YAML mappings.")
            print(f"State: {manifest['state']}. No server requests sent. Output: {output}")
            print("Use the same command with --execute to import or resume verification.")
            return
        client = FhirClient(base, os.environ.get(args.token_env, ""), args.timeout)
        if manifest["state"] == "planned":
            check_capabilities(client.request("GET", "metadata"), resources, args.id_mode)
            manifest["state"] = "submitting"
            save(path, manifest)
            # A timeout, lost response or invalid response may follow a committed
            # transaction. Persist the uncertain state; never automatically POST again.
            response = client.request("POST", "", transaction)
            identities = response_mapping(response, resources, base, args.id_mode)
            manifest.update(state="imported", idMap=identities)
            save(path, manifest)
        identities = manifest["idMap"]
        require(set(identities) == set(resources), "Saved ID map is incomplete")
        for original, identity in identities.items():
            require(local_identity(identity, base, original.split("/")[0]) == identity, "Invalid saved ID map")
        print(f"Verifying {len(resources)} resources and their references…", flush=True)
        verify_resources(client, resources, links, identities)
        write_configs(output, configs, mapping, identities)
        save(output / "id-map.json", identities)
        manifest.update(state="complete", readBackVerified=True)
        save(path, manifest)
        print(f"Verified {len(resources)} resources. Configurations: {output / 'configs'}")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fhir-url", required=True, help="FHIR base endpoint, without credentials")
    parser.add_argument("--bundle", type=Path, default=ROOT / "testdata/Stufe5/fixtures/bundle.json")
    parser.add_argument("--mapping", type=Path, help="Defaults to config-mapping.json beside the bundle")
    parser.add_argument("--config-dir", type=Path, default=ROOT / "testdata/Stufe5")
    parser.add_argument("--output", type=Path, required=True, help="Persistent directory for the plan, manifest and generated YAML")
    parser.add_argument("--id-mode", choices=("server-assigned", "preserve"), default="server-assigned")
    parser.add_argument("--token-env", default="FHIR_TOKEN", help="Environment variable containing a bearer token; unset for unauthenticated servers")
    parser.add_argument("--timeout", type=float, default=300, help="Timeout in seconds per HTTP request")
    parser.add_argument("--execute", action="store_true", help="Import into the configured server; without this flag, prepare files offline only")
    args = parser.parse_args(argv)
    try:
        run(args)
        return 0
    except (ImportProblem, OSError, ValueError, KeyError, TypeError) as error:
        # Input parse errors never include response bodies or credentials.
        print(f"Error: {error}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        print("Interrupted. Keep the output manifest before attempting another import.", file=sys.stderr)
        return 130


if __name__ == "__main__":
    sys.exit(main())
