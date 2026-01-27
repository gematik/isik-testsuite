# language: en
@Stufe5
@Basis
@Mandatory
@Procedure-Read
Feature: Read Information from a resource of type Procedure (@Procedure-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
        - The test dataset must have been entered in the system under test according to the specifications (manually).
        - The ID of the corresponding FHIR resource for this test dataset must be stored in the configuration variable 'procedure-read-id'.

        Create a Procedure resource with these fields:

        * Patient reference: Patient from the Patient-Read test case
        * Encounter reference: Encounter from the Encounter-Read-In-Progress test case
        * Type of procedure: surgical intervention (SNOMED CT from the German National Edition category code: 387713003, version: configured with the variable 'snomed-ct-version')
        * Procedure codes:
          - SNOMED CT: appendectomy (from the German National Edition code: 6025007, version: configured with the variable 'snomed-ct-version')
          - OPS code: 5-470.11 (catalog version: any valid catalog version)
        * Status: completed
        * Performed date: 2026-01-05
        * Note: Test note
        * Documentation date: 2026-01-05
        * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Procedure"

  Scenario: Read and Validate Procedure by its ID
    When Get FHIR resource at "http://fhirserver/Procedure/${data.procedure-read-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKProzedur"
    And resource has ID "${data.procedure-read-id}"
    And TGR current response with attribute "$..status.value" matches "completed"
    And FHIR current response body evaluates the FHIRPath 'category.coding.where(code = "387713003" and system = "http://snomed.info/sct" and version = "http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}").exists()' with error message 'The Procedure resource does not contain a correct categorization'
    And FHIR current response body evaluates the FHIRPath 'code.coding.where(code = "5-470.11" and system = "http://fhir.de/CodeSystem/bfarm/ops" and version.exists()).exists()' with error message 'The Procedure resource does not contain a correct OPS coding'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '6025007' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}').exists()" with error message 'The Procedure resource does not contain a correct SNOMED-CT coding'
    And element "subject" references resource with ID "${data.patient-read-id}" with error message "The referenced Patient does not match the expected value"
    And element "encounter" references resource with ID "${data.encounter-read-in-progress-id}" with error message "Referenced Encounter does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "performed.toString().contains('2026-01-05') or ( performed.start.toString().contains('2026-01-05') and performed.end.toString().contains('2026-01-05') )" with error message "The Procedure does not contain a performed date"
    And FHIR current response body evaluates the FHIRPath 'note.where(text = "Test note").exists()' with error message 'The note does not match the expected value'
    And FHIR current response body evaluates the FHIRPath 'extension.where(url = "http://fhir.de/StructureDefinition/ProzedurDokumentationsdatum" and value.toString().contains("2026-01-05")).exists()' with error message 'The documentation date does not match the expected value'
