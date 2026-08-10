# language: en
@Stufe5
@Vitalparameter
@Optional
@ISiKCapabilityStatementVitalSignStandardSourceRolle
@Observation-Read-EKG
Feature: Read Information from a resource of type Observation for ECG data (@Observation-Read-EKG)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'observation-read-ekg-id'.

      Create an Observation resource in your system with the following values:
      * Id: the value of the configuration variable 'observation-read-ekg-id'
      * Profile: ISiKEKG
      * Status: final
      * Category: procedure
      * Code:
        - Coding:
          * Code: LP6244-0
          * Display: Electrocardiogram (EKG)
          * System: http://loinc.org
          * Version: 2.81 (can be configured with the property 'loinc-version')
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in 'observation-patient-id')
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in 'observation-encounter-id')
      * Performer: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in 'observation-practitioner-id')
      * Device: any (store the ID in 'observation-device-id')
      * Effective date/time: 2026-03-05
      * Three ECG components with sampled data:
        - Coding:
          * Code: LP7386-8
          * Display: Lead I
          * System: http://loinc.org
          * Version: 2.81 (can be configured with the property 'loinc-version')
        - Coding:
          * Code: LP7387-6
          * Display: Lead II
          * System: http://loinc.org
          * Version: 2.81 (can be configured with the property 'loinc-version')
        - Coding:
          * Code: LP7388-4
          * Display: Lead III
          * System: http://loinc.org
          * Version: 2.81 (can be configured with the property 'loinc-version')
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate the Observation by its ID
    Then Get FHIR resource at "http://fhirserver/Observation/${vitalparameter.observation-read-ekg-id}" with content type "xml"
    And resource has ID "${vitalparameter.observation-read-ekg-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKEKG"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'procedure' and system = 'http://terminology.hl7.org/CodeSystem/observation-category').exists()" with error message 'The category does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = 'LP6244-0' and system = 'http://loinc.org' and version = '${vitalparameter.loinc-version}' and display.empty().not()).exists()" with error message 'The code does not match the expected value'
    And element "device" references resource with ID "Device/${vitalparameter.observation-device-id}" with error message "The referenced device does not match the expected value"
    And element "subject" references resource with ID "Patient/${vitalparameter.observation-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${vitalparameter.observation-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${vitalparameter.observation-practitioner-id}" with error message "The referenced performer does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2026-03-05')" with error message 'The effective date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.count() >= 3" with error message 'The number of components does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = 'LP7386-8' and system = 'http://loinc.org' and version = '${vitalparameter.loinc-version}' and display.empty().not()).exists()).exists()" with error message 'The first ECG lead is missing'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = 'LP7387-6' and system = 'http://loinc.org' and version = '${vitalparameter.loinc-version}' and display.empty().not()).exists()).exists()" with error message 'The second ECG lead is missing'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = 'LP7388-4' and system = 'http://loinc.org' and version = '${vitalparameter.loinc-version}' and display.empty().not()).exists()).exists()" with error message 'The third ECG lead is missing'
    And FHIR current response body evaluates the FHIRPath "component.all(value.exists())" with error message 'At least one ECG component is missing sampled data'
    And FHIR current response body evaluates the FHIRPath "component.all(value.origin.exists())" with error message 'At least one ECG component is missing the sampled-data origin'
    And FHIR current response body evaluates the FHIRPath "component.all(value.period.exists())" with error message 'At least one ECG component is missing the sampled-data period'
    And FHIR current response body evaluates the FHIRPath "component.all(value.dimensions.exists())" with error message 'At least one ECG component is missing the sampled-data dimensions'
    And FHIR current response body evaluates the FHIRPath "component.all(value.data.exists())" with error message 'At least one ECG component is missing sampled-data values'

