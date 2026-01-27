# language: en
@Stufe5
@Basis
@Mandatory
@Condition-Read-Resolved
Feature: Read Information from a resource of type Condition with status "resolved" (@Condition-Read-Resolved)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH). Here it is tested whether the resource is returned according to the onset of illness as a date."
    Given the Preconditions:
    """
      - The test cases Patient-Read and Encounter-Read-Finished must have been executed successfully beforehand.
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset must be stored in the configuration variable 'condition-read-resolved-id'.

      Create a Condition resource with these fields:

      * Body site: Knee joint (SNOMED CT from the German National Edition code: 49076000, version: configured with the variable 'snomed-ct-version')
      * Start of Condition: 2025-12-20
      * End of Condition: 2026-01-07
      * Clinical status: resolved
      * Code system: http://fhir.de/CodeSystem/bfarm/icd-10-gm
      * Code system version: the version configured with the variable 'icd-10-gm-version'
      * Code: M17.0
      * Documentation date: 2025-12-23
      * Referenced patient: The patient from the Patient-Read test case
      * Encounter: The encounter from the Encounter-Read-In-Progress test case
      * Note: Illness resolved
      * (Optional) Verification Status: confirmed
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Condition"

  Scenario: Read and Validate resolved Condition by its ID
    When Get FHIR resource at "http://fhirserver/Condition/${data.condition-read-resolved-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKDiagnose"
    And resource has ID "${data.condition-read-resolved-id}" with error message "The ID does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "code.coding.where(system = 'http://fhir.de/CodeSystem/bfarm/icd-10-gm' and code = 'M17.0' and version = '${data.icd-10-gm-version}').exists()" with error message 'The Condition code is missing or a required value is absent'
    And element "subject" references resource with ID "${data.patient-read-id}" with error message "The referenced patient does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "clinicalStatus.coding.where(system = 'http://terminology.hl7.org/CodeSystem/condition-clinical' and code = 'resolved').exists()" with error message "The Clinical status does not have the value 'resolved'"
    And FHIR current response body evaluates the FHIRPath 'recordedDate.toString().contains("2025-12-23")' with error message 'The resource does not contain the expected Documentation date'
    And FHIR current response body evaluates the FHIRPath 'note.text = "Illness resolved"' with error message 'The note does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "bodySite.coding.where(system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}' and code = '49076000').exists()" with error message 'The body site code does not match the expected value'
    And TGR the custom failure message is set to "The end date does not contain the expected value"
    And TGR current response with attribute "$.body.Condition.abatementDateTime.value" matches "2026-01-07"
    And TGR the custom failure message is set to "The start date does not contain the expected value"
    And TGR current response with attribute "$.body.Condition.onsetDateTime.value" matches "2025-12-20"
    And TGR clear the custom failure message

  @Optional
  Scenario: Check Verification Status
    When Get FHIR resource at "http://fhirserver/Condition/${data.condition-read-resolved-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath "verificationStatus.coding.where(system = 'http://terminology.hl7.org/CodeSystem/condition-ver-status' and code = 'confirmed').exists()" with error message "The Verification status does not have the value 'confirmed'"

