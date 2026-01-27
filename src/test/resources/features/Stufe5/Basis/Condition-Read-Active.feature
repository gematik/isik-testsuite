# language: en
@Stufe5
@Basis
@Mandatory
@Condition-Read-Active
Feature: Read Information from a resource of type Condition with status "active" (@Condition-Read-Active)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH). Here it is tested whether the resource is returned according to the onset of illness as the patient's age."
    Given the Preconditions:
    """
      - The test cases Condition-Read-Resolved, Patient-Read and Encounter-Read-In-Progress must have been executed successfully beforehand.
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset must be stored in the configuration variable 'condition-read-active-id'.

      Create a Condition resource with these fields:

      * Body site: Knee joint (SNOMED CT from the German National Edition code: 49076000, version: configured with the variable 'snomed-ct-version')
      * Start of Condition: Patient's age (any, in years)
      * Clinical status: active
      * Code system: http://fhir.de/CodeSystem/bfarm/icd-10-gm
      * Code system version: the version configured with the variable 'icd-10-gm-version'
      * Code: F71.0
      * Documentation date: 2021-02-12
      * Related condition: The reference to the resource from the Condition-Read-Resolved test case
      * Referenced patient: The patient from the Patient-Read test case
      * Encounter: The encounter from the Encounter-Read-In-Progress test case
      * Note: Test note
      * (Optional) Category: Diagnosis in the context of an encounter
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Condition"

  Scenario: Read and Validate active Condition by its ID
    When Get FHIR resource at "http://fhirserver/Condition/${data.condition-read-active-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKDiagnose"
    And resource has ID "${data.condition-read-active-id}" with error message "The ID does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "code.coding.where(system = 'http://fhir.de/CodeSystem/bfarm/icd-10-gm' and code = 'F71.0' and version = '${data.icd-10-gm-version}').exists()" with error message "The Condition code is missing or a required value is absent"
    And element "subject" references resource with ID "${data.patient-read-id}" with error message "The referenced case does not match the expected value."
    And FHIR current response body evaluates the FHIRPath "clinicalStatus.coding.where(system = 'http://terminology.hl7.org/CodeSystem/condition-clinical' and code = 'active').exists()" with error message "The Clinical status does not have the value 'active'"
    And FHIR current response body evaluates the FHIRPath 'recordedDate.toString().contains("2021-02-12")' with error message 'The documentation date does not contain the expected value'
    And FHIR current response body evaluates the FHIRPath 'note.text = "Test note"' with error message 'The note does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "bodySite.coding.where(system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}' and code = '49076000').exists()" with error message 'The body site code does not match the expected value'
    And TGR the custom failure message is set to "The related condition does not match the expected url"
    And TGR current response with attribute "$.body.Condition.extension.url" matches "http://hl7.org/fhir/StructureDefinition/condition-related"
    And TGR the custom failure message is set to "The related condition does not match the expected reference value"
    And TGR current response with attribute "$.body.Condition.extension.valueReference.reference.value" matches "Condition/${data.condition-read-resolved-id}"
    And TGR the custom failure message is set to "The onsetAge system field does not match the expected value."
    And TGR current response with attribute "$.body.Condition.onsetAge.system.value" matches "http://unitsofmeasure.org"
    And TGR the custom failure message is set to "The onsetAge unit field does not match the expected value."
    And TGR current response with attribute "$.body.Condition.onsetAge.unit.value" matches "years"
    And TGR the custom failure message is set to "The onsetAge value field was not found."
    And TGR current response contains node "$.body.Condition.onsetAge.value.value"


