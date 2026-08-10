# language: en
@Stufe5
@Labor
@Mandatory
@Observation-Read-Serumkreatinin
Feature: Read Information from a resource of type Observation for serum creatinine (@Observation-Read-Serumkreatinin)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'observation-read-serumkreatinin-id'.

      Create an Observation resource in your system with the following values:
      * Id: the value of the configuration variable 'observation-read-serumkreatinin-id'
      * Profile: ISiKLaboruntersuchungSerumkreatinin
      * Status: final
      * Category: laboratory
      * Code:
        - Coding (LOINC):
          * Code: 2160-0
          * Display: Creatinin [Masse/Volumen] in Serum oder Plasma
          * System: http://loinc.org
          * Version: can be configured with the property 'loinc-version'
        - Coding (SNOMED):
          * Code: 70901006
          * Display: Creatinine measurement
          * System: http://snomed.info/sct
          * Version: can be configured with the property 'snomed-ct-version'
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in 'observation-patient-id')
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in 'observation-encounter-id')
      * Performer: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in 'observation-practitioner-id')
      * Effective date/time: 2024-05-14T07:45:00+02:00
      * Issued: 2024-05-14T09:15:00+02:00
      * Value: 0.7 mg/dL
      * Reference Range:
        - Low: 0.6 mg/dL
        - High: 1.2 mg/dL
        - Type: normal
        - Applies to: Coding: Code: 248152002, Display: Weiblich, System: http://snomed.info/sct
      * Interpretation:
        - Coding: Code: N, Display: Normal, System: http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation
      * Note: "Wert im Normbereich."
      * Specimen:
        - Identifier: System: https://example.org/fhir/sid/proben, Value: PRB-2024-1002
      * Device:
        - Display: Cobas c503 (Roche Diagnostics)
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate the Observation by its ID
    Then Get FHIR resource at "http://fhirserver/Observation/${labor.observation-read-serumkreatinin-id}" with content type "xml"
    And resource has ID "${labor.observation-read-serumkreatinin-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKLaboruntersuchungSerumkreatinin"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'laboratory' and system = 'http://terminology.hl7.org/CodeSystem/observation-category').exists()" with error message 'The category does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '2160-0' and system = 'http://loinc.org' and version = '${labor.loinc-version}' and display.empty().not()).exists()" with error message 'The LOINC code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '70901006' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${labor.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The SNOMED code does not match the expected value'
    And element "subject" references resource with ID "Patient/${labor.observation-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${labor.observation-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${labor.observation-practitioner-id}" with error message "The referenced performer does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2024-05-14')" with error message 'The effective date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "issued.toString().contains('2024-05-14')" with error message 'The issued date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.where(value ~ 0.7 and code = 'mg/dL' and unit.exists() and system = 'http://unitsofmeasure.org').exists()" with error message 'The value does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "referenceRange.where(low.value ~ 0.6 and low.code = 'mg/dL' and low.system = 'http://unitsofmeasure.org' and high.value ~ 1.2 and high.code = 'mg/dL' and high.system = 'http://unitsofmeasure.org' and type.coding.where(code = 'normal' and system = 'http://terminology.hl7.org/CodeSystem/referencerange-meaning').exists() and appliesTo.coding.where(code = '248152002' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${labor.snomed-ct-version}').exists()).exists()" with error message 'The reference range does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "interpretation.coding.where(code = 'N' and system = 'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation' and display.empty().not()).exists()" with error message 'The interpretation does not match the expected value'
    And FHIR current response body evaluates the FHIRPath 'note.text = "Wert im Normbereich."' with error message 'The note does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "specimen.identifier.where(system = 'https://example.org/fhir/sid/proben' and value = 'PRB-2024-1002').exists()" with error message 'The specimen identifier does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "device.display = 'Cobas c503 (Roche Diagnostics)'" with error message 'The device display does not match the expected value'
