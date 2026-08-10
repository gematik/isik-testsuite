# language: en
@Stufe5
@ICUExtended
@VitalSignICUSourceExtendedAkteur
@Mandatory
@ISiKCapabilityStatementVitalSignICUSourceExtendedRolle
@Observation-Read-Ext-LeftVentricularCardiacIndex
Feature: Read Information from a resource of type Observation for left ventricular cardiac index data (@Observation-Read-Ext-LeftVentricularCardiacIndex)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'observation-read-ext-left-ventricular-cardiac-index-id'.

      Create an Observation resource in your system with the following values:
      * Id: the value of the configuration variable 'observation-read-ext-left-ventricular-cardiac-index-id'
      * Profile: sd-mii-icu-linksventrikulaerer-herzindex
      * Status: final
      * Category:
        - Coding:
          * Code: vital-signs
          * System: http://terminology.hl7.org/CodeSystem/observation-category
      * Code:
        - Coding:
          * Code: 54993008
          * Display: Cardiac index
          * System: http://snomed.info/sct
          * Version: 20251115 (configured with the property 'snomed-ct-version')
        - Coding:
          * Code: 75919-1
          * Display: Left ventricular Cardiac index
          * System: http://loinc.org
          * Version: (can be configured with the property 'loinc-version')
        - Coding:
          * Code: 149772
          * Display: Cardiac index
          * System: urn:iso:std:iso:11073:10101
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
          * Code: 87878005
          * Display: Left cardiac ventricular structure
          * System: http://snomed.info/sct
          * Version: 20251115 (configured with the property 'snomed-ct-version')
      * Value:
        - Quantity:
          * Value: 3
          * Unit: liter per minute and square meter
          * System: http://unitsofmeasure.org
          * Code: L/min/m2
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate the Observation by its ID
    Then Get FHIR resource at "http://fhirserver/Observation/${icuextended.observation-read-ext-left-ventricular-cardiac-index-id}" with content type "xml"
    And resource has ID "${icuextended.observation-read-ext-left-ventricular-cardiac-index-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/sd-mii-icu-linksventrikulaerer-herzindex"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'vital-signs' and system = 'http://terminology.hl7.org/CodeSystem/observation-category').exists()" with error message 'The category does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '54993008' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${icuextended.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The SNOMED code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '75919-1' and system = 'http://loinc.org' and version = '${icuextended.loinc-version}' and display.empty().not()).exists()" with error message 'The LOINC code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '149772' and system = 'urn:iso:std:iso:11073:10101' and display.empty().not()).exists()" with error message 'The ISO 11073 code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "identifier.exists()" with error message 'The identifier is missing'
    And FHIR current response body evaluates the FHIRPath "interpretation.coding.where(code = 'B' and system = 'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation').exists()" with error message 'The interpretation does not match the expected value'
    And element "subject" references resource with ID "Patient/${icuextended.observation-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${icuextended.observation-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${icuextended.observation-practitioner-id}" with error message "The referenced performer does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.start.toString().contains('2019-12-23T09:30:10+01:00')" with error message 'The effective period start does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "effective.end.toString().contains('2019-12-23T10:30:10+01:00')" with error message 'The effective period end does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.value = 3" with error message 'The value does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.unit = 'liter per minute and square meter'" with error message 'The unit does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.system = 'http://unitsofmeasure.org'" with error message 'The system does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.code = 'L/min/m2'" with error message 'The UCUM code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "bodySite.coding.where(code = '87878005' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${icuextended.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The body site does not match the expected value'
