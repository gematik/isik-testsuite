# language: en
@Stufe5
@Vitalparameter
@Mandatory
@Observation-Read-Arterial-Blood-Pressure
Feature: Read Information from a resource of type Observation for arterial blood pressure (@Observation-Read-Arterial-Blood-Pressure)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'observation-read-arterial-blood-pressure-id'.

      Create an Observation resource in your system with the following values:
      * Id: the value of the configuration variable 'observation-read-arterial-blood-pressure-id'
      * Profile: ISiKBlutdruckSystemischArteriell
      * Status: final
      * Category: vital-signs
      * Code:
        - Coding:
          * Code: 85354-9
          * Display: Blood pressure panel with all children optional
          * System: http://loinc.org
          * Version: can be configured with the property 'loinc-version'
        - Coding (SNOMED):
            * Code: 75367002
            * Display: Blood pressure
            * System: http://snomed.info/sct
            * Version: can be configured with the property 'snomed-ct-version'
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in 'observation-patient-id')
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in 'observation-encounter-id')
      * Performer: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in 'observation-practitioner-id')
      * Device: any (store the ID in 'observation-read-device-id')
      * Effective date/time: 2026-03-06
      * Components:
        - Systolic blood pressure:
          * Value: 107 mm[Hg]
          * Coding (LOINC):
            * Code: 8480-6
            * Display: Systolic blood pressure
            * System: http://loinc.org
            * Version: can be configured with the property 'loinc-version'
          * Coding (SNOMED):
            * Code: 271649006
            * Display: Systolischer Blutdruck
            * System: http://snomed.info/sct
            * Version: can be configured with the property 'snomed-ct-version'
        - Diastolic blood pressure:
          * Value: 60 mm[Hg]
          * Coding (LOINC):
            * Code: 8462-4
            * Display: Diastolic blood pressure
            * System: http://loinc.org
            * Version: can be configured with the property 'loinc-version'
          * Coding (SNOMED):
            * Code: 271650006
            * Display: Diastolischer Blutdruck
            * System: http://snomed.info/sct
            * Version: can be configured with the property 'snomed-ct-version'
      * (Optional) Method:
        * Coding:
          * Code: 113011001
          * Display: Automatisches Blutdruckmessgerät
          * System: http://snomed.info/sct
          * Version: can be configured with the property 'snomed-ct-version'
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate the Observation by its ID
    Then Get FHIR resource at "http://fhirserver/Observation/${data.observation-read-arterial-blood-pressure-id}" with content type "xml"
    And resource has ID "${data.observation-read-arterial-blood-pressure-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKBlutdruckSystemischArteriell"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'vital-signs' and system = 'http://terminology.hl7.org/CodeSystem/observation-category').exists()" with error message 'The category does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '85354-9' and system = 'http://loinc.org' and version = '${data.loinc-version}' and display.empty().not()).exists()" with error message 'The LOINC Code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '75367002' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The SNOMED Code does not match the expected value'
    And element "subject" references resource with ID "Patient/${data.observation-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${data.observation-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${data.observation-practitioner-id}" with error message "The referenced performer does not match the expected value"
    And element "device" references resource with ID "Device/${data.observation-device-id}" with error message "The referenced device does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2026-03-06')" with error message 'The effective date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.count() >= 2" with error message 'The number of components does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(system = 'http://loinc.org' and code = '8480-6' and version = '${data.loinc-version}' and display.empty().not()).exists() and value.where(value ~ 107 and code = 'mm[Hg]' and system = 'http://unitsofmeasure.org').exists()).exists()" with error message 'The systolic blood pressure component does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(system = 'http://loinc.org' and code = '8462-4' and version = '${data.loinc-version}' and display.empty().not()).exists() and value.where(value ~ 60 and code = 'mm[Hg]' and system = 'http://unitsofmeasure.org').exists()).exists()" with error message 'The diastolic blood pressure component does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.select(value.code = 'mm[Hg]' and value.unit.exists() and value.system = 'http://unitsofmeasure.org').allTrue()" with error message 'At least one component uses an incorrect UCUM coding'

  @Optional
  Scenario: Read optional Method from Observation
    Then Get FHIR resource at "http://fhirserver/Observation/${data.observation-read-arterial-blood-pressure-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath "method.coding.where(code = '113011001' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The method does not match the expected value'
