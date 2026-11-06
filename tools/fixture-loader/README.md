# ISiK fixture preparation tool

This draft CLI imports the synthetic Stufe 5 dataset into a FHIR R4 server and
generates configuration files containing the assigned resource IDs. It uses standard
FHIR transactions and has no THP dependency. Python 3.10 or newer is sufficient;
there are no third-party Python dependencies. A Docker image packages the same CLI
and the dataset.

The default is an **offline dry run**. Add `--execute` to make server requests and
import the data. Use a disposable test environment with the required profiles,
terminology and permissions already configured. See the
[dataset requirements and known conflicts](../../testdata/Stufe5/fixtures/README.md).

## Prepare and execute locally

From the repository root:

```sh
python3 tools/fixture-loader/prepare_isik_data.py \
  --fhir-url http://localhost:8080/fhir \
  --output output/prepared-isik \
  --id-mode server-assigned
```

Inspect `output/prepared-isik/transaction.json` and `manifest.json`. The plan contains
130 resources and explicit mappings for 206 configuration fields in eight clinical
module files. It does not contact the server or generate runnable YAML files yet.

Set `FHIR_TOKEN` in the environment to an authorized bearer token, or leave it unset
for an unauthenticated test server. Repeat the command with `--execute`:

```sh
python3 tools/fixture-loader/prepare_isik_data.py \
  --fhir-url http://localhost:8080/fhir \
  --output output/prepared-isik \
  --id-mode server-assigned \
  --execute
```

The tool checks the CapabilityStatement, submits one transaction, records the ID map,
and reads back every resource to verify its ID and the mapped references. Only then
does it write the generated YAML files and mark the manifest complete.

The two ID modes are:

| Mode | Import behaviour | Required resource interactions |
| --- | --- | --- |
| `server-assigned` (default) | Remove top-level fixture IDs; use `POST` with UUID fullUrls and references | `create`, `read` |
| `preserve` | Use `PUT ResourceType/id` and retain the dataset IDs | `update`, `read`, `updateCreate: true` |

Both modes require FHIR R4, JSON and transaction support. In `preserve` mode, existing
resources at the fixture IDs are updated. This corresponds to the existing THP fixture
loading approach. A different ID mode or target server requires its own output directory.

## Run with Docker

Build from the repository root:

```sh
docker build -f tools/fixture-loader/Dockerfile -t isik-fixture-loader:local .
```

The image contains the CLI, fixture bundle, explicit mapping, clinical YAML templates
and license notices. It excludes Connect configuration, reports and local scripts.
It runs as a non-root user and does not need a writable container filesystem.

Prepare a plan without network access:

```sh
mkdir -p output/prepared-isik
docker run --rm --read-only --network none \
  --user "$(id -u):$(id -g)" \
  --mount "type=bind,source=$PWD/output/prepared-isik,target=/output" \
  isik-fixture-loader:local \
  --fhir-url http://host.docker.internal:8080/fhir \
  --output /output
```

On Docker Desktop, `host.docker.internal` reaches a service on the host. On Linux,
use a reachable host address, add `--add-host host.docker.internal:host-gateway`, or
join the server's Docker network and use its service name. Keep the FHIR URL identical
between planning and execution. `localhost` inside the container identifies the
container itself.

Execute the prepared plan, passing the token through the environment:

```sh
docker run --rm --read-only \
  --user "$(id -u):$(id -g)" \
  --env FHIR_TOKEN \
  --mount "type=bind,source=$PWD/output/prepared-isik,target=/output" \
  isik-fixture-loader:local \
  --fhir-url http://host.docker.internal:8080/fhir \
  --output /output \
  --execute
```

For another compatible dataset or edited configuration, mount a directory read-only
and pass `--bundle`, `--mapping` and `--config-dir` pointing into that mount. The
default mapping file is `config-mapping.json` beside the input bundle. Authentication
currently supports a bearer token or an unauthenticated endpoint; `--token-env NAME`
selects another environment variable. Tokens are never written into generated files
or error reports. HTTP redirects are refused, so credentials cannot follow a redirect
to another endpoint.

## Output and test configuration

```text
prepared-isik/
  transaction.json
  manifest.json
  id-map.json
  configs/
    basis.yaml
    dokumentenaustausch.yaml
    icu-extended.yaml
    icu-minimal.yaml
    labor.yaml
    medikation.yaml
    terminplanung.yaml
    vitalparameter.yaml
```

Point the clinical entries in your Tiger configuration's `additionalConfigurationFiles`
at the generated files, retaining their existing `baseKey` values. For example:

```yaml
additionalConfigurationFiles:
  - filename: output/prepared-isik/configs/basis.yaml
    baseKey: basis
```

Apply the corresponding path changes for the other clinical modules you run. Keep
Connect configuration separate: it requires matching users, tokens and access rights.
The tool does not create authorization-server users, modify the source YAML files or
launch tests. Unmapped values, including business identifiers and IDs for resources
created by the test scenarios themselves, remain unchanged.

The manifest records the server, ID mode, input hashes, transaction hash, import state
and assigned IDs. It is needed for safe continuation of the same import. Output files
are created with restrictive permissions.

## Mapping and reference handling

[config-mapping.json](../../testdata/Stufe5/fixtures/config-mapping.json) explicitly
associates each YAML key with a fixture resource and an output format (`id` or
`reference`). The tool checks each source value against that mapping. It does not
infer mappings from key names or perform global text replacement.

FHIR `Reference.reference` fields are rewritten automatically. Contained references
are retained and checked against the contained resources. References outside the
bundle are rejected in this draft. Other resource links must be listed explicitly as
JSON pointers in `resourceLinks`; the supplied mapping covers the two
DocumentReference attachment URLs that target Binary resources. Business identifiers,
canonical URLs and unrelated text are not rewritten.

UUID resolution and response ordering follow the
[FHIR R4 transaction rules](https://hl7.org/fhir/R4/http.html#transaction).
Read-back verifies both Reference fields and the explicitly mapped URI fields. If a
server leaves a UUID unresolved, the import is not marked complete.

Custom datasets need their own reviewed mapping, particularly for URI-valued fields
and narrative links. The tool is not a general FHIR schema-aware migration engine.
Configuration parsing supports the suite's flat YAML scalar maps, not arbitrary YAML
structures. The importer does not install IGs, resolve terminology, or independently
validate resource profiles; keep the SUT's validation enabled.

## Resume and duplicate protection

Reuse the same output directory, input files, server URL and ID mode when continuing:

| Manifest state | Behaviour with `--execute` |
| --- | --- |
| `planned` | Check capabilities and submit the saved transaction |
| `imported` | Resume read-back and YAML generation; do not submit again |
| `complete` | Recheck the existing resources and regenerate YAML; do not submit again |
| `submitting` | Stop: the server may have committed the transaction without a usable response |

A network timeout, interruption or invalid transaction response after submission can
leave the outcome uncertain. Inspect the server and reconcile the resources before
starting another import. Do not delete the manifest, switch to a fresh output directory
or reset its state merely to bypass this protection. There is no automatic rollback or
reconciliation of an uncertain submission in this draft.

An exclusive `.lock` prevents simultaneous use of one output directory. After an
abrupt process termination, remove a stale lock only after confirming that the importer
is no longer running. Changed inputs or a modified transaction are rejected.

Duplicate protection applies to a retained manifest, not across unrelated output
directories. Use a fresh disposable database for an independent test run, since the
suite can update or delete imported resources. The tool does not automatically delete
resources or reset their clinical content on resume.

## Verification

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s tools/fixture-loader -p 'test_*.py' -v
```

The tests use a local HTTP FHIR test double. They exercise both ID modes, the entire
130-resource dataset and 206 configuration fields, capability checks, attachment links,
read-back, redirects, input changes and restart behaviour. Docker is checked separately
by building the image and preparing a plan with networking disabled. These checks do
not substitute for an integration run against each target FHIR implementation.
