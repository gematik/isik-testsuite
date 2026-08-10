# language: en
@Stufe5
@Vitalparameter
@Mandatory
@ISiKCapabilityStatementVitalSignStandardSourceRolle
@Observation-Read-Respiratory-Rate
Feature: Read Information from a resource of type Observation for respiratory rate (@Observation-Read-Respiratory-Rate)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'observation-read-respiratory-rate-id'.

      Create an Observation resource in your system with the following values:
      * Id: the value of the configuration variable 'observation-read-respiratory-rate-id'
      * Profile: ISiKAtemfrequenz
      * Status: final
      * Category: vital-signs
      * Code:
        - Coding:
          * Code: 9279-1
          * Display: Respiratory rate
          * System: http://loinc.org
          * Version: 2.81 (can be configured with the property 'loinc-version')
      * Method:
        - Coding:
          * Code: 86290005
          * Display: Respiratory rate (observable entity)
          * System: http://snomed.info/sct
          * Version: 20251115 (can be configured with the property 'snomed-ct-version')
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in 'observation-patient-id')
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in 'observation-encounter-id')
      * Performer: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in 'observation-read-practitioner-id')
      * Effective date/time: 2026-03-05
      * Value: 26 /min
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate the Observation by its ID
    Then Get FHIR resource at "http://fhirserver/Observation/${vitalparameter.observation-read-respiratory-rate-id}" with content type "xml"
    And resource has ID "${vitalparameter.observation-read-respiratory-rate-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKAtemfrequenz"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'vital-signs' and system = 'http://terminology.hl7.org/CodeSystem/observation-category').exists()" with error message 'The category does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '9279-1' and system = 'http://loinc.org' and version = '${vitalparameter.loinc-version}' and display.empty().not()).exists()" with error message 'The code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "method.coding.where(code = '86290005' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${vitalparameter.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The method does not match the expected value'
    And element "subject" references resource with ID "Patient/${vitalparameter.observation-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${vitalparameter.observation-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${vitalparameter.observation-practitioner-id}" with error message "The referenced performer does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2026-03-05')" with error message 'The effective date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.where(value ~ 26 and code = '/min' and unit.exists() and system = 'http://unitsofmeasure.org').exists()" with error message 'The value does not match the expected value'
    And referenced "Patient" resource with id "${vitalparameter.observation-patient-id}" conforms to a valid v5 "ISiKPatient" profile
    And referenced "Encounter" resource with id "${vitalparameter.observation-encounter-id}" conforms to a valid v5 "ISiKKontaktGesundheitseinrichtung" profile
    And referenced "Practitioner" resource with id "${vitalparameter.observation-practitioner-id}" conforms to a valid v5 "ISiKPersonImGesundheitsberuf" profile
