# language: en
@Stufe5
@ICUExtended
@VitalSignICUSourceExtendedAkteur
@Mandatory
@ISiKCapabilityStatementVitalSignICUSourceExtendedRolle
@Observation-Read-Ext-PulmonaryArterialPressure
Feature: Read Information from a resource of type Observation for pulmonary arterial pressure data (@Observation-Read-Ext-PulmonaryArterialPressure)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'observation-read-ext-pulmonary-arterial-pressure-id'.

      Create an Observation resource in your system with the following values:
      * Id: the value of the configuration variable 'observation-read-ext-pulmonary-arterial-pressure-id'
      * Profile: sd-mii-icu-pulmonalarterieller-blutdruck
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
          * Code: 250767002
          * Display: Pulmonary artery pressure
          * System: http://snomed.info/sct
          * Version: 20251115 (configured with the property 'snomed-ct-version')
        - Coding:
          * Code: 76284-9
          * Display: Pulmonary artery Blood pressure
          * System: http://loinc.org
          * Version: (can be configured with the property 'loinc-version')
        - Coding:
          * Code: 150044
          * Display: MDC_PRESS_BLD_ART_PULM
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
          * Code: 81040000
          * Display: Pulmonary artery structure
          * System: http://snomed.info/sct
          * Version: 20251115 (configured with the property 'snomed-ct-version')
      * Components:
        - Systolic:
          - Coding:
            * Code: 8480-6
            * System: http://loinc.org
            * Version: (can be configured with the property 'loinc-version')
          - Coding:
            * Code: 150045
            * Display: Systolic pulmonary arterial pressure
            * System: urn:iso:std:iso:11073:10101
          - Coding:
            * Code: 8440-0
            * Display: Pulmonary artery Systolic blood pressure
            * System: http://loinc.org
            * Version: (can be configured with the property 'loinc-version')
          - Coding:
            * Code: 250768007
            * Display: Pulmonary artery systolic pressure
            * System: http://snomed.info/sct
            * Version: 20251115 (configured with the property 'snomed-ct-version')
          - Quantity:
            * Value: 18
            * Unit: millimeter Mercury column
            * System: http://unitsofmeasure.org
            * Code: mm[Hg]
        - Diastolic:
          - Coding:
            * Code: 8462-4
            * System: http://loinc.org
            * Version: (can be configured with the property 'loinc-version')
          - Coding:
            * Code: 150046
            * Display: Diastolic pulmonary arterial pressure
            * System: urn:iso:std:iso:11073:10101
          - Coding:
            * Code: 8385-7
            * Display: Pulmonary artery Diastolic blood pressure
            * System: http://loinc.org
            * Version: (can be configured with the property 'loinc-version')
          - Coding:
            * Code: 250769004
            * Display: Pulmonary artery diastolic pressure
            * System: http://snomed.info/sct
            * Version: 20251115 (configured with the property 'snomed-ct-version')
          - Quantity:
            * Value: 8
            * Unit: millimeter Mercury column
            * System: http://unitsofmeasure.org
            * Code: mm[Hg]
        - Mean:
          - Coding:
            * Code: 8478-0
            * System: http://loinc.org
            * Version: (can be configured with the property 'loinc-version')
          - Coding:
            * Code: 150047
            * Display: Mean pulmonary arterial pressure
            * System: urn:iso:std:iso:11073:10101
          - Coding:
            * Code: 8414-5
            * Display: Pulmonary artery Mean blood pressure
            * System: http://loinc.org
            * Version: (can be configured with the property 'loinc-version')
          - Coding:
            * Code: 250770003
            * Display: Pulmonary artery mean pressure
            * System: http://snomed.info/sct
            * Version: 20251115 (configured with the property 'snomed-ct-version')
          - Quantity:
            * Value: 10
            * Unit: millimeter Mercury column
            * System: http://unitsofmeasure.org
            * Code: mm[Hg]
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate the Observation by its ID
    Then Get FHIR resource at "http://fhirserver/Observation/${icuextended.observation-read-ext-pulmonary-arterial-pressure-id}" with content type "xml"
    And resource has ID "${icuextended.observation-read-ext-pulmonary-arterial-pressure-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/sd-mii-icu-pulmonalarterieller-blutdruck"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'vital-signs' and system = 'http://terminology.hl7.org/CodeSystem/observation-category').exists()" with error message 'The category does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '75367002' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${icuextended.snomed-ct-version}').exists()" with error message 'The generic SNOMED code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '250767002' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${icuextended.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The SNOMED code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '76284-9' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}' and display.empty().not()).exists()" with error message 'The LOINC code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '150044' and system = 'urn:iso:std:iso:11073:10101' and display.empty().not()).exists()" with error message 'The ISO 11073 code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "identifier.exists()" with error message 'The identifier is missing'
    And FHIR current response body evaluates the FHIRPath "interpretation.coding.where(code = 'B' and system = 'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation').exists()" with error message 'The interpretation does not match the expected value'
    And element "subject" references resource with ID "Patient/${icuextended.observation-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${icuextended.observation-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${icuextended.observation-practitioner-id}" with error message "The referenced performer does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2019-12-23T09:30:10+01:00')" with error message 'The effective date/time does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "bodySite.coding.where(code = '81040000' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${icuextended.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The body site does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.count() = 3" with error message 'The number of components does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8480-6' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).exists()" with error message 'The systolic component is missing'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8480-6' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).code.coding.where(code = '150045' and system = 'urn:iso:std:iso:11073:10101' and display.empty().not()).exists()" with error message 'The systolic component ISO 11073 code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8480-6' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).code.coding.where(code = '8440-0' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}' and display.empty().not()).exists()" with error message 'The systolic component LOINC code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8480-6' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).code.coding.where(code = '250768007' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${icuextended.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The systolic component SNOMED code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8480-6' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).value.where(value = 18 and unit = 'millimeter Mercury column' and system = 'http://unitsofmeasure.org' and code = 'mm[Hg]').exists()" with error message 'The systolic component value does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8462-4' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).exists()" with error message 'The diastolic component is missing'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8462-4' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).code.coding.where(code = '150046' and system = 'urn:iso:std:iso:11073:10101' and display.empty().not()).exists()" with error message 'The diastolic component ISO 11073 code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8462-4' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).code.coding.where(code = '8385-7' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}' and display.empty().not()).exists()" with error message 'The diastolic component LOINC code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8462-4' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).code.coding.where(code = '250769004' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${icuextended.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The diastolic component SNOMED code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8462-4' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).value.where(value = 8 and unit = 'millimeter Mercury column' and system = 'http://unitsofmeasure.org' and code = 'mm[Hg]').exists()" with error message 'The diastolic component value does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8478-0' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).exists()" with error message 'The mean component is missing'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8478-0' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).code.coding.where(code = '150047' and system = 'urn:iso:std:iso:11073:10101' and display.empty().not()).exists()" with error message 'The mean component ISO 11073 code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8478-0' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).code.coding.where(code = '8414-5' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}' and display.empty().not()).exists()" with error message 'The mean component LOINC code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8478-0' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).code.coding.where(code = '250770003' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${icuextended.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The mean component SNOMED code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "component.where(code.coding.where(code = '8478-0' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()).value.where(value = 10 and unit = 'millimeter Mercury column' and system = 'http://unitsofmeasure.org' and code = 'mm[Hg]').exists()" with error message 'The mean component value does not match the expected value'
