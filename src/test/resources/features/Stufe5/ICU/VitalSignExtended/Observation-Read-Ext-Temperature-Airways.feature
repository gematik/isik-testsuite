# language: en
@Stufe5
@ICUExtended
@VitalSignICUSourceExtendedAkteur
@Mandatory
@ISiKCapabilityStatementVitalSignICUSourceExtendedRolle
@Observation-Read-Ext-Temperature-Airways
Feature: Read Information from a resource of type Observation for airway temperature data (@Observation-Read-Ext-Temperature-Airways)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'observation-read-ext-temperature-airways-id'.

      Create an Observation resource in your system with the following values:
      * Id: the value of the configuration variable 'observation-read-ext-temperature-airways-id'
      * Profile: sd-mii-icu-koerpertemperatur-atemwege
      * Status: final
      * Category:
        - Coding:
          * Code: vital-signs
          * System: http://terminology.hl7.org/CodeSystem/observation-category
      * Code:
        - Coding:
          * Code: 8310-5
          * System: http://loinc.org
          * Version: (can be configured with the property 'loinc-version')
          (no display required)
        - Coding:
          * Code: 150356
          * Display: MDC_TEMP_AWAY
          * System: urn:iso:std:iso:11073:10101
        - Coding:
          * Code: 60955-2
          * Display: Airway temperature
          * System: http://loinc.org
          * Version: (can be configured with the property 'loinc-version')
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in 'observation-patient-id')
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in 'observation-encounter-id')
      * Performer: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in 'observation-practitioner-id')
      * Effective Period:
        - Start: 2019-12-23T09:30:10+01:00
        - End: 2019-12-23T10:30:10+01:00
      * Interpretation:
        - Coding:
          * Code: B
          * Display: Better
          * System: http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation
      * Identifier: any (system: https://fhir.krankenhaus.example/sid/observation)
      * Body Site:
        - Coding:
          * Code: 89187006
          * Display: Airway structure (body structure)
          * System: http://snomed.info/sct
          * Version: 20251115 (configured with the property 'snomed-ct-version')
      * Value:
        - Quantity:
          * Value: 37
          * Unit: degree Celsius
          * System: http://unitsofmeasure.org
          * Code: Cel
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate the Observation by its ID
    Then Get FHIR resource at "http://fhirserver/Observation/${icuextended.observation-read-ext-temperature-airways-id}" with content type "xml"
    And resource has ID "${icuextended.observation-read-ext-temperature-airways-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/sd-mii-icu-koerpertemperatur-atemwege"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'vital-signs' and system = 'http://terminology.hl7.org/CodeSystem/observation-category').exists()" with error message 'The category does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '8310-5' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}').exists()" with error message 'The LOINC code (8310-5) does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '150356' and system = 'urn:iso:std:iso:11073:10101' and display.empty().not()).exists()" with error message 'The ISO 11073 code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '60955-2' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}' and display.empty().not()).exists()" with error message 'The LOINC code (60955-2) does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "identifier.exists()" with error message 'The identifier is missing'
    And FHIR current response body evaluates the FHIRPath "interpretation.coding.where(code = 'B' and system = 'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation').exists()" with error message 'The interpretation does not match the expected value'
    And element "subject" references resource with ID "Patient/${icuextended.observation-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${icuextended.observation-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${icuextended.observation-practitioner-id}" with error message "The referenced performer does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.start.toString().contains('2019-12-23T09:30:10+01:00')" with error message 'The effective period start does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "effective.end.toString().contains('2019-12-23T10:30:10+01:00')" with error message 'The effective period end does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.value = 37" with error message 'The value does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.unit = 'degree Celsius'" with error message 'The unit does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.system = 'http://unitsofmeasure.org'" with error message 'The system does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.code = 'Cel'" with error message 'The UCUM code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "bodySite.coding.where(code = '89187006' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${icuextended.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The body site does not match the expected value'
