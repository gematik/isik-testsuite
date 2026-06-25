# language: en
@Stufe5
@Basis
@Mandatory
@ISiKCapabilityStatementGesundheitsstatusRolle
@Observation-Alcohol-Abuse-Read
Feature: Read information from a resource of type Observation for alcohol abuse (@Observation-Alcohol-Abuse-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset must be stored in the configuration variable 'observation-alcohol-abuse-read-id'.

      Create an Observation resource with these fields:
      * Id: the value of the configuration variable 'observation-alcohol-abuse-read-id'
      * Profile: ISiKAlkoholAbusus
      * Status: final
      * Code:
        - Coding:
          * System: http://snomed.info/sct
          * Code: 15167005
          * Display: Schädlicher Gebrauch von Alkohol
          * Version: 20251115 (configured with the property 'snomed-ct-version')
        - Coding:
          * System: http://loinc.org
          * Code: 74043-1
          * Display: Alcohol use disorder
          * Version: 2.81 (can be configured with the property 'loinc-version')
      * Patient: Patient from the Patient-Read test case
      * Performer: Practitioner from the Practitioner-Read test case
      * Encounter: Encounter from the Encounter-Read-In-Progress test case
      * Effective date/time: 2026-01-06
      * Value:
        - Coding:
          * System: http://terminology.hl7.org/CodeSystem/v2-0532
          * Code: Y
          * Display: Yes
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate alcohol abuse Observation by its ID
    When Get FHIR resource at "http://fhirserver/Observation/${data.observation-alcohol-abuse-read-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKAlkoholAbusus"
    And resource has ID "${data.observation-alcohol-abuse-read-id}" with error message "The ID does not match the expected value"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "code.coding.where(system = 'http://snomed.info/sct' and code = '15167005' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The SNOMED CT code for alcohol abuse does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(system = 'http://loinc.org' and code = '74043-1' and version = '${data.loinc-version}' and display.empty().not()).exists()" with error message 'The LOINC code for alcohol abuse does not match the expected value'
    And element "subject" references resource with ID "Patient/${data.patient-read-id}" with error message "The referenced patient does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${data.practitioner-read-id}" with error message "The referenced performer does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${data.encounter-read-in-progress-id}" with error message "The referenced encounter does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2026-01-06')" with error message 'The effective date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.coding.where(system = 'http://terminology.hl7.org/CodeSystem/v2-0532' and code = 'Y' and display = 'Yes').exists()" with error message 'The alcohol abuse value does not match the expected value'
