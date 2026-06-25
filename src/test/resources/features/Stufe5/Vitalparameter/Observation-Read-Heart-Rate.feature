# language: en
@Stufe5
@Vitalparameter
@Mandatory
@Observation-Read-Heart-Rate
Feature: Read Information from a resource of type Observation for heart rate (@Observation-Read-Heart-Rate)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'observation-read-heart-rate-id'.

      Create an Observation resource in your system with the following values:
      * Id: the value of the configuration variable 'observation-read-heart-rate-id'
      * Profile: ISiKHerzfrequenz
      * Status: final
      * Category: vital-signs
      * Code:
        - Coding:
            * Code: 8867-4
            * Display: Heart rate
            * System: http://loinc.org
            * Version: 2.81 (can be configured with the property 'loinc-version')
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in 'observation-patient-id')
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in 'observation-encounter-id')
      * Performer: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in 'observation-practitioner-id')
      * Effective date/time: 2026-03-05
      * Value: 63 /min
      * (Optional) Device: any (store the ID in 'observation-read-device-id')
      * (Optional) Method:
        * Coding:
          * Code: 268400002
          * Display: 12-Kanal-Elektrokardiogramm
          * System: http://snomed.info/sct
          * Version: can be configured with the property 'snomed-ct-version'
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate the Observation by its ID
    Then Get FHIR resource at "http://fhirserver/Observation/${data.observation-read-heart-rate-id}" with content type "xml"
    And resource has ID "${data.observation-read-heart-rate-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKHerzfrequenz"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'vital-signs' and system = 'http://terminology.hl7.org/CodeSystem/observation-category').exists()" with error message 'The category does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '8867-4' and system = 'http://loinc.org' and version = '${data.loinc-version}' and display.empty().not()).exists()" with error message 'The code does not match the expected value'
    And element "subject" references resource with ID "Patient/${data.observation-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${data.observation-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${data.observation-practitioner-id}" with error message "The referenced performer does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2026-03-05')" with error message 'The effective date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.where(value ~ 63 and code = '/min' and unit.exists() and system = 'http://unitsofmeasure.org').exists()" with error message 'The value does not match the expected value'

  @Optional
  Scenario: Read optional Method from Observation
    Then Get FHIR resource at "http://fhirserver/Observation/${data.observation-read-heart-rate-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath "method.coding.where(code = '268400002' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The method does not match the expected value'
    And element "device" references resource with ID "Device/${data.observation-device-id}" with error message "The referenced device does not match the expected value"

