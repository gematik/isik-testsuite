<img align="right" width="250" height="47" src="imgs/gematik_logo.png"/> <br/>

# Release Notes ISiK Stufe 3 Test Suite

## Release 1.5.0

### changed
- Updated TIGER Framework to version 4.1.9
- Updated ISIK3 Plugins to latest versions of Specifications (3.1.1)
- The Test-Case Appointment-Book has now an `@Optional` testcase for testing the booking with a specialty slice using a IHE `AerztlicheFachrichtungen` code.
  - If your server does not support this, run the test cases by providing the parameter `not @Optional`

## Release 1.4.0

### changed
- HTTP Headers are now verified case insensitive

## Release 1.3.2

### changed
- The `DocumentReference-Post` testcase now allows the configuration of a custom `masterIdentifier` via the `testdata/dokumentenaustausch.yaml` file.

### fixed
- Removed the precondition from the `DocumentReference-Post` testcase to require the execution of the `DocumentReference-Read` one.

## Release 1.3.1

### changed
- Renamed Test Report archive to `test-report.zip`
- Updated Licenses

## Release 1.3.0

### added
- New Tag for the execution of the optional `Terminplanung` Communication tests: `@Communication`

### changed
- Test Scenario `Binary-Create` is now optional and executed only when the tag `@Communication` is provided
- Updated TIGER Framework to version 4.1.1

### fixed
- Matching Content-Type Charset in HTTP Headers is now case insensitive

## Release 1.2.0 (2025-05-06)

### added
- Possibility to provide HTTP Basic credentials or a Bearer token (cf. [README.md](./README.md#test-environment)) 
- docker image for the testsuite

### changed
- Synchronized test cases with [TITUS Release 3.6.3](https://wiki.gematik.de/spaces/EPA/pages/459883044/ISiK+Testmodul+in+Titus+-+Release+Notes)

## Release 1.1.0 (2024-08-30)

(sync with TITUS test cases v3.4.0)

### added
- Verification of TelematikID and precinct in Practitioner-Read test
- Verification of TelematikID as a search identifier in Practitioner-Search test
- Verification of patientInstruction and timing data in MedicationRequest-Read test

### changed
- Unified search test cases by medication code for MedicationRequest, MedicationAdministration and MedicationStatement resources
- Enabling use of reasonCode apart from reasonReference in MedicationStatement-Read test
- Enabling coding of timing information using multiple dosageInstruction elements in MedicationStatement-Read and MedicationRequest tests
- Enabling use of a dedicated Medication resource in MedicationRequest tests
- Enabling use of arbitrary values in dosage.text for MedicationAdministration and MedicationStatement tests
- Enabling use of arbitrary dates in List tests
- [TIGER Workflow UI](https://gematik.github.io/app-Tiger/Tiger-User-Manual.html#_workflow_ui) now starts by default. Change `lib.activateWorkflowUi` in `tiger.yaml` to `false` to disable it. 

### fixed
- Verification of meta.tag in Appointment-Read test
- UCUM code for Tablette in MedicationUpdate test
- Corrupted HTML reports with Javascript error showing up for testcases with a template in title (e.g. Suche des Medikaments anhand des <title>)

## Release 1.0.0 (2024-07-17)

- initial implementation
