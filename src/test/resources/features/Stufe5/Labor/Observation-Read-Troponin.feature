# language: en
@Stufe5
@Labor
@Mandatory
@Observation-Read-Troponin
Feature: Read Information from a resource of type Observation for troponin (@Observation-Read-Troponin)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'observation-read-troponin-id'.

      Create an Observation resource in your system with the following values:
      * Id: the value of the configuration variable 'observation-read-troponin-id'
      * Profile: ISiKLaboruntersuchungTroponin
      * Status: final
      * Category: laboratory
      * Code:
        - Coding (LOINC):
          * Code: 42757-5
          * Display: Troponin I.kardial [Masse/Volumen] in Blut
          * System: http://loinc.org
          * Version: can be configured with the property 'loinc-version'
        - Coding (SNOMED):
          * Code: 105000003
          * Display: Troponin measurement
          * System: http://snomed.info/sct
          * Version: can be configured with the property 'snomed-ct-version'
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in 'observation-patient-id')
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in 'observation-encounter-id')
      * Performer: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in 'observation-practitioner-id')
      * Effective date/time: 2024-05-14T07:45:00+02:00
      * Issued: 2024-05-14T09:15:00+02:00
      * Value: 0.1 ng/L
      * Reference Range:
        - High: 0.14 ng/L
        - Type: normal
      * Interpretation:
        - Coding: Code: N, Display: Normal, System: http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation
      * Note: "Kein Hinweis auf myokardiale Schädigung."
      * Specimen:
        - Identifier: System: https://example.org/fhir/sid/proben, Value: PRB-2024-1007
      * Device:
        - Display: Atellica IM Analyzer (Siemens Healthineers)
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate the Observation by its ID
    Then Get FHIR resource at "http://fhirserver/Observation/${labor.observation-read-troponin-id}" with content type "xml"
    And resource has ID "${labor.observation-read-troponin-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKLaboruntersuchungTroponin"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'laboratory' and system = 'http://terminology.hl7.org/CodeSystem/observation-category').exists()" with error message 'The category does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '42757-5' and system = 'http://loinc.org' and version = '${labor.loinc-version}' and display.empty().not()).exists()" with error message 'The LOINC code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '105000003' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${labor.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The SNOMED code does not match the expected value'
    And element "subject" references resource with ID "Patient/${labor.observation-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${labor.observation-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${labor.observation-practitioner-id}" with error message "The referenced performer does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2024-05-14')" with error message 'The effective date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "issued.toString().contains('2024-05-14')" with error message 'The issued date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.where(value ~ 0.1 and code = 'ng/mL' and unit.exists() and system = 'http://unitsofmeasure.org').exists()" with error message 'The value does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "referenceRange.where(high.value ~ 0.14 and high.code = 'ng/mL' and high.system = 'http://unitsofmeasure.org' and type.coding.where(code = 'normal' and system = 'http://terminology.hl7.org/CodeSystem/referencerange-meaning').exists()).exists()" with error message 'The reference range does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "interpretation.coding.where(code = 'N' and system = 'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation' and display.empty().not()).exists()" with error message 'The interpretation does not match the expected value'
    And FHIR current response body evaluates the FHIRPath 'note.text = "Kein Hinweis auf myokardiale Schädigung."' with error message 'The note does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "specimen.identifier.where(system = 'https://example.org/fhir/sid/proben' and value = 'PRB-2024-1007').exists()" with error message 'The specimen identifier does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "device.display = 'Atellica IM Analyzer (Siemens Healthineers)'" with error message 'The device display does not match the expected value'
