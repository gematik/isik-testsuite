# language: en
@Stufe5
@Vitalparameter
@ISiKCapabilityStatementVitalSignStandardSourceRolle
@Observation-Read-GCS
Feature: Read Information from a resource of type Observation for the Glasgow Coma Scale (@Observation-Read-GCS)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'observation-read-gcs-id'.

      Create an Observation resource in your system with the following values:
      * Id: the value of the configuration variable 'observation-read-gcs-id'
      * Profile: ISiKGCS
      * Status: final
      * Category: survey
      * Code:
        - Coding:
            * Code: 9269-2
            * Display: Glasgow coma score total
            * System: http://loinc.org
            * Version: 2.81 (can be configured with the property 'loinc-version')
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in 'observation-patient-id')
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in 'observation-encounter-id')
      * Performer: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in 'observation-practitioner-id')
      * Effective date/time: 2026-02-18
      * Total score: 15 with UCUM code 1
      * Components:
        - Oriented (LOINC 9270-0): LA6558-6
        - Obeys commands (LOINC 9268-4): LA6567-7
        - Eyes open spontaneously (LOINC 9267-6): LA6556-0
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate the Observation by its ID
    Then Get FHIR resource at "http://fhirserver/Observation/${vitalparameter.observation-read-gcs-id}" with content type "xml"
    And resource has ID "${vitalparameter.observation-read-gcs-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKGCS"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'survey' and system = 'http://terminology.hl7.org/CodeSystem/observation-category').exists()" with error message 'The category does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '9269-2' and system = 'http://loinc.org' and version = '${vitalparameter.loinc-version}' and display.empty().not()).exists()" with error message 'The code does not match the expected value'
    And element "subject" references resource with ID "Patient/${vitalparameter.observation-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${vitalparameter.observation-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${vitalparameter.observation-practitioner-id}" with error message "The referenced performer does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2026-02-18')" with error message 'The effective date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.where(value ~ 15 and code = '1' and unit.exists() and system = 'http://unitsofmeasure.org').exists()" with error message 'The total score does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.count() >= 3" with error message 'The number of components does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(system = 'http://loinc.org' and code = '9270-0' and version = '${vitalparameter.loinc-version}' and display.empty().not()).exists() and value.coding.where(system = 'http://loinc.org' and code = 'LA6558-6').exists()).exists()" with error message 'The verbal response component does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(system = 'http://loinc.org' and code = '9268-4' and version = '${vitalparameter.loinc-version}' and display.empty().not()).exists() and value.coding.where(system = 'http://loinc.org' and code = 'LA6567-7').exists()).exists()" with error message 'The motor response component does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(system = 'http://loinc.org' and code = '9267-6' and version = '${vitalparameter.loinc-version}' and display.empty().not()).exists() and value.coding.where(system = 'http://loinc.org' and code = 'LA6556-0').exists()).exists()" with error message 'The eye-opening component does not match the expected value'

