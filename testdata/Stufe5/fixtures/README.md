# Synthetic Stufe 5 reference fixtures

This dataset provides 130 synthetic FHIR resources for the Stufe 5 test preconditions.
It covers all 116 configured direct-read resource identities outside Connect in suite
commit `3c8e44c730c139230452c00ba582cec021fa5d61` (3.0.9), plus reference targets.
The resource IDs match the defaults in the adjacent [module YAML files](../).
The dataset contains no real patient data.

The resources were loaded and read back with server profile validation enabled in
an integration run.
This establishes fixture loadability in that environment, not that every scenario
passes. Known conflicts with the suite's assertions are listed below.

## Contents and provenance

- [bundle.json](bundle.json) is a FHIR R4 transaction containing the resources and
  relative `PUT ResourceType/id` requests. Its `fullUrl` values use the placeholder
  base `https://example.org/fhir`; replace that base before submitting the transaction.
- [provenance.json](provenance.json) records the source of each resource, relevant
  feature files, adaptations, package versions and validation evidence.
- [config-mapping.json](config-mapping.json) maps 206 clinical YAML fields to fixture
  resources and identifies the two document attachment links for the preparation tool.
- [LICENSE](LICENSE) preserves the MIT notice for the reused InterSystems DACH corpus.

The starting corpus comes from the
[InterSystems ISiK test rig](https://github.com/intersystems-dach/IRIS-ISiK-Test-Suite/tree/bef08a9e1b6fda60ce3a5687f09cddd0a97cee8f/testdata/fhir),
which targeted suite 2.7.0. This adaptation resolves its placeholders against suite
3.0.9, adds ICU and laboratory resources from suite preconditions and package examples,
and supplies the required reference targets. Validation repairs include required fields,
profile slices, coding versions and displays. Per-resource attribution is retained in
the provenance file.

The bundle includes the CodeSystem and ValueSet resources used by their respective
read tests. It does not install ImplementationGuides, StructureDefinitions,
CapabilityStatements or SearchParameters.

## Version requirements

Prepare the SUT and reference validator with compatible profiles and terminology
before loading fixtures. The validated package set is:

| Package | Version |
| --- | --- |
| `de.gematik.isik` | `5.1.3` |
| `de.gematik.ti` | `1.1.1` |
| `de.gematik.terminology` | `1.0.7` |
| `de.basisprofil.r4` | `1.5.4` |
| `de.ihe-d.terminology` | `3.0.1` |
| `dvmd.kdl.r4` | `2025.0.1` |
| `de.fhir.medication` | `1.0.4` |
| `hl7.terminology.r4` | `7.1.0` |
| `hl7.fhir.uv.extensions.r4` | `5.2.0` |
| `hl7.fhir.uv.subscriptions-backport.r4` | `1.1.0` |
| `hl7.fhir.uv.sdc` | `4.0.0-ballot` |

FHIR core is R4 `4.0.1`. Explicit coding versions include LOINC `2.81`, German SNOMED
CT `http://snomed.info/sct/11000274103/version/20251115`, ATC `2024`, ICD-10-GM
`2026.0.0` and OPS `2021`. The terminology validator must support the versions used
by the resources; access to a terminology server does not by itself establish that
it hosts those editions. The dataset does not configure a terminology service.

## Load using the configured example IDs

The optional [fixture preparation tool](../../../tools/fixture-loader/README.md)
automates preparation, import, read-back and configuration generation. It runs with
Python or Docker and defaults to an offline dry run. Use `--id-mode preserve` for
the existing example IDs, or `--id-mode server-assigned` to generate configurations
using IDs returned by the server. The manual procedure below retains the example IDs.

Use an empty, disposable test environment. The transaction creates or updates the
specified IDs, including resources later changed by update and delete scenarios.
This loading method requires FHIR transactions, update-as-create and client-assigned
alphanumeric IDs. Servers that assign their own IDs can use the mapping procedure
in the next section instead.

From the repository root, prepare the transaction with Python 3 and the target's FHIR
base URL. This only writes a local file; it does not contact the server:

```sh
export FHIR_BASE_URL="http://localhost:8080/fhir"

python3 - <<'PY' > /tmp/isik-stufe5-fixtures.json
import json
import os
from pathlib import Path
from urllib.parse import urlsplit

base = os.environ["FHIR_BASE_URL"].rstrip("/")
url = urlsplit(base)
if (url.scheme not in {"http", "https"} or not url.netloc or url.username
        or url.password or url.query or url.fragment):
    raise SystemExit("FHIR_BASE_URL must be an HTTP(S) base without credentials, query or fragment")
bundle = json.loads(Path("testdata/Stufe5/fixtures/bundle.json").read_text())
for entry in bundle["entry"]:
    entry["fullUrl"] = base + "/" + entry["request"]["url"]
print(json.dumps(bundle, ensure_ascii=False))
PY
```

Submit it to the FHIR base endpoint. Set `FHIR_TOKEN` to an access token authorized
to load the dataset; omit the Authorization header if the test server does not
require authentication.

```sh
curl --fail-with-body --show-error --max-time 300 \
  --request POST "${FHIR_BASE_URL%/}" \
  --header "Authorization: Bearer ${FHIR_TOKEN:?Set FHIR_TOKEN}" \
  --header 'Content-Type: application/fhir+json' \
  --header 'Accept: application/fhir+json' \
  --data-binary @/tmp/isik-stufe5-fixtures.json \
  --output /tmp/isik-stufe5-fixture-response.json
```

Require a successful response for every entry before running tests:

```sh
python3 - <<'PY'
import json
from pathlib import Path

request = json.loads(Path("/tmp/isik-stufe5-fixtures.json").read_text())
response = json.loads(Path("/tmp/isik-stufe5-fixture-response.json").read_text())
entries = response.get("entry", [])
if (response.get("resourceType") != "Bundle" or response.get("type") != "transaction-response"
        or len(entries) != len(request["entry"])):
    raise SystemExit("Fixture load did not return the expected transaction response")
for index, entry in enumerate(entries, 1):
    status = entry.get("response", {}).get("status", "").split()
    if not status or len(status[0]) != 3 or not status[0].isdigit() or not status[0].startswith("2"):
        raise SystemExit(f"Fixture entry {index} failed; inspect the response")
print(f"All {len(entries)} transaction entries succeeded")
PY
```

Read the resources back at their `request.url` paths to verify their persisted IDs
and content. Investigate any OperationOutcome before proceeding; do not disable
profile validation to load a rejected fixture. With the example IDs retained, the
existing clinical module YAML mappings can be used unchanged.

## Use server assigned IDs

The example IDs are fixture labels, not requirements on the SUT. The suite accepts
the IDs configured in the module YAML files. For a server that assigns IDs:

1. Create the resources and capture each returned resource ID or response location.
   A transaction using `POST` and unique `urn:uuid:` fullUrls can resolve references
   when all corresponding reference values are changed to those fullUrls.
2. Maintain a mapping from each original `ResourceType/id` to its assigned identity.
   Apply the mapping to cross-resource references, including forward references.
3. Update the corresponding IDs and reference values in the module YAML files. Retain
   the business identifier systems and values required by the search assertions.
4. Read back each mapped resource and verify reference resolution before running tests.

Changing `PUT` to `POST` alone is insufficient: the references and YAML values must
also be mapped. Discovery through unique business identifiers is another option for
resources that have suitable identifiers. Fail on ambiguous or missing matches.
The [fixture preparation tool](../../../tools/fixture-loader/README.md) implements
the transaction and mapping procedure above, including document attachment links.
It writes new module YAML files without modifying the source configuration.

## Connect and test isolation

Connect needs separate authorization-server users, tokens, scope assignments and
resource relationships described by its feature preconditions and
[connect.yaml](../connect.yaml). This bundle does not provision identities or tokens.
Adding `@Connect` to the test selection requires that setup in addition to the data.

Update and delete scenarios mutate fixtures. Start each independent run with a fresh
test database, or restore the complete fixture state and mappings before rerunning.
Remove the disposable environment after the run. The dataset does not supply a
generic deletion transaction because deletion rules and reference-integrity policies
vary by server.

## Known assertion conflicts

- `Medikation/MedicationAdministration-Read-Rate.feature` and
  `Medikation/MedicationStatement-Read-Rate.feature` assert SNOMED `255560000`
  (Intravenous). Validation against the pinned profile's required
  `SctRouteOfAdministration` ValueSet rejected that code. The two fixtures instead use
  `47625008` (Intravenous route), accepted with the German `20251115` release. Their
  route-code assertions therefore remain expected failures until the discrepancy is
  resolved. The feature files are unchanged.
- The GCS preconditions in `Vitalparameter` and `ICU/VitalSignMinimal` label
  `LA6558-6` as “Oriented”, but terminology validation identifies it as
  “Incomprehensible sounds”. The fixtures retain the suite's asserted code and total
  score, with the corrected display. This is an unresolved inconsistency in test
  data and preconditions; it is not a clinically consistent GCS example.

Configured-ID coverage and successful fixture loading do not prove all clinical field
assertions. Review scenario failures against the provenance and preconditions before
attributing them to the SUT.
