# language: en
@Stufe5
@ICUExtended
@VitalSignICUSourceExtendedAkteur
@Mandatory
@ISiKCapabilityStatementVitalSignICUSourceExtendedRolle
@Observation-Read-Ext-RightAtrialPressure
Feature: Read Information from a resource of type Observation for right atrial pressure data (@Observation-Read-Ext-RightAtrialPressure)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'observation-read-ext-right-atrial-pressure-id'.

      Create an Observation resource in your system with the following values:
      * Id: the value of the configuration variable 'observation-read-ext-right-atrial-pressure-id'
      * Profile: sd-mii-icu-rechtsatrialer-druck
      * Status: final
      * Category:
        - Coding:
          * Code: vital-signs
          * System: http://terminology.hl7.org/CodeSystem/observation-category
      * Code:
        - Coding:
          * Code: 75367002
          * System: http://snomed.info/sct
          * Version: 20251115 (configured with the property 'snomed-ct-version')
        - Coding:
          * Code: 276755008
          * Display: Right atrial pressure
          * System: http://snomed.info/sct
          * Version: 20251115 (configured with the property 'snomed-ct-version')
        - Coding:
          * Code: 60996-6
          * Display: Right atrial pressure
          * System: http://loinc.org
          * Version: (can be configured with the property 'loinc-version')
        - Coding:
          * Code: 150068
          * Display: MDC_PRESS_BLD_ATR_RIGHT
          * System: urn:iso:std:iso:11073:10101
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in 'observation-patient-id')
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in 'observation-encounter-id')
      * Performer: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in 'observation-practitioner-id')
      * Effective Date/Time: 2019-12-23T09:30:10+01:00
      * Interpretation:
        - Coding:
          * Code: B
          * Display: Better
          * System: http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation
      * Identifier: any (system: https://fhir.krankenhaus.example/sid/observation)
      * Body Site:
        - Coding:
          * Code: 73829009
          * Display: Right atrial structure
          * System: http://snomed.info/sct
          * Version: 20251115 (configured with the property 'snomed-ct-version')
      * Components:
        - Systolic:
          - Coding:
            * Code: 8480-6
            * System: http://loinc.org
            * Version: (can be configured with the property 'loinc-version')
          - Coding:
            * Code: 150069
            * Display: Systolic right atrial pressure
            * System: urn:iso:std:iso:11073:10101
          - Coding:
            * Code: 60998-2
            * Display: Right atrial pressure Systolic
            * System: http://loinc.org
            * Version: (can be configured with the property 'loinc-version')
          - Quantity:
            * Value: 5
            * Unit: millimeter Mercury column
            * System: http://unitsofmeasure.org
            * Code: mm[Hg]
        - Mean:
          - Coding:
            * Code: 8478-0
            * System: http://loinc.org
            * Version: (can be configured with the property 'loinc-version')
          - Coding:
            * Code: 150071
            * Display: Mean right atrial pressure
            * System: urn:iso:std:iso:11073:10101
          - Coding:
            * Code: 8400-4
            * Display: Right atrial Intrachamber mean pressure
            * System: http://loinc.org
            * Version: (can be configured with the property 'loinc-version')
          - Coding:
            * Code: 276775004
            * Display: Mean right atrial pressure
            * System: http://snomed.info/sct
            * Version: 20251115 (configured with the property 'snomed-ct-version')
          - Quantity:
            * Value: 4
            * Unit: millimeter Mercury column
            * System: http://unitsofmeasure.org
            * Code: mm[Hg]
        - Diastolic:
          - Coding:
            * Code: 8462-4
            * System: http://loinc.org
            * Version: (can be configured with the property 'loinc-version')
          - Coding:
            * Code: 150070
            * Display: Diastolic right atrial pressure
            * System: urn:iso:std:iso:11073:10101
          - Coding:
            * Code: 60997-4
            * Display: Right atrial pressure Diastolic
            * System: http://loinc.org
            * Version: (can be configured with the property 'loinc-version')
          - Quantity:
            * Value: 3
            * Unit: millimeter Mercury column
            * System: http://unitsofmeasure.org
            * Code: mm[Hg]
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate the Observation by its ID
    Then Get FHIR resource at "http://fhirserver/Observation/${icuextended.observation-read-ext-right-atrial-pressure-id}" with content type "xml"
    And resource has ID "${icuextended.observation-read-ext-right-atrial-pressure-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/sd-mii-icu-rechtsatrialer-druck"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'vital-signs' and system = 'http://terminology.hl7.org/CodeSystem/observation-category').exists()" with error message 'The category does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '75367002' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${icuextended.snomed-ct-version}').exists()" with error message 'The generic SNOMED code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '276755008' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${icuextended.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The SNOMED code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '60996-6' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}' and display.empty().not()).exists()" with error message 'The LOINC code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '150068' and system = 'urn:iso:std:iso:11073:10101' and display.empty().not()).exists()" with error message 'The ISO 11073 code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "identifier.exists()" with error message 'The identifier is missing'
    And FHIR current response body evaluates the FHIRPath "interpretation.coding.where(code = 'B' and system = 'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation').exists()" with error message 'The interpretation does not match the expected value'
    And element "subject" references resource with ID "Patient/${icuextended.observation-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${icuextended.observation-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${icuextended.observation-practitioner-id}" with error message "The referenced performer does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2019-12-23T09:30:10+01:00')" with error message 'The effective date/time does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "bodySite.coding.where(code = '73829009' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${icuextended.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The body site does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.count() = 3" with error message 'The number of components does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8480-6' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).exists()" with error message 'The systolic component is missing'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8480-6' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).code.coding.where(code = '150069' and system = 'urn:iso:std:iso:11073:10101' and display.empty().not()).exists()" with error message 'The systolic component ISO 11073 code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8480-6' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).code.coding.where(code = '60998-2' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}' and display.empty().not()).exists()" with error message 'The systolic component LOINC code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8480-6' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).value.where(value = 5 and unit = 'millimeter Mercury column' and system = 'http://unitsofmeasure.org' and code = 'mm[Hg]').exists()" with error message 'The systolic component value does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8478-0' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).exists()" with error message 'The mean component is missing'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8478-0' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).code.coding.where(code = '150071' and system = 'urn:iso:std:iso:11073:10101' and display.empty().not()).exists()" with error message 'The mean component ISO 11073 code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8478-0' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).code.coding.where(code = '8400-4' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}' and display.empty().not()).exists()" with error message 'The mean component LOINC code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8478-0' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).code.coding.where(code = '276775004' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${icuextended.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The mean component SNOMED code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8478-0' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).value.where(value = 4 and unit = 'millimeter Mercury column' and system = 'http://unitsofmeasure.org' and code = 'mm[Hg]').exists()" with error message 'The mean component value does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8462-4' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).exists()" with error message 'The diastolic component is missing'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8462-4' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).code.coding.where(code = '150070' and system = 'urn:iso:std:iso:11073:10101' and display.empty().not()).exists()" with error message 'The diastolic component ISO 11073 code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8462-4' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).code.coding.where(code = '60997-4' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}' and display.empty().not()).exists()" with error message 'The diastolic component LOINC code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8462-4' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).value.where(value = 3 and unit = 'millimeter Mercury column' and system = 'http://unitsofmeasure.org' and code = 'mm[Hg]').exists()" with error message 'The diastolic component value does not match the expected value'
