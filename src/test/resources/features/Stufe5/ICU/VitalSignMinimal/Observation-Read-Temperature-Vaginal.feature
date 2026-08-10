# language: en
@Stufe5
@ICUMinimal
@VitalSignICUSourceMinimalAkteur
@Mandatory
@ISiKCapabilityStatementVitalSignICUSourceMinimalRolle
@Observation-Read-Temperature-Vaginal
Feature: Read Information from a resource of type Observation for vaginal temperature data (@Observation-Read-Temperature-Vaginal)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'observation-read-temperature-vaginal-id'.

      Create an Observation resource in your system with the following values:
      * Id: the value of the configuration variable 'observation-read-temperature-vaginal-id'
      * Profile: sd-mii-icu-koerpertemperatur-vaginal
      * Status: final
      * Identifier:
        - System: https://fhir.krankenhaus.example/sid/observation
          Value: ICUmin-OBS-013
      * Category:
        - Coding:
          * Code: vital-signs
          * System: http://terminology.hl7.org/CodeSystem/observation-category
      * Code:
        - Coding:
          * Code: 364246006
          * Display: Vaginaltemperatur
          * System: http://snomed.info/sct
          * Version: 20251115 (configured with the property 'snomed-ct-version')
        - Coding:
          * Code: 8329-5
          * Display: Körperkerntemperatur
          * System: http://loinc.org
          * Version: (can be configured with the property 'loinc-version')
        - Coding:
          * Code: 8310-5
          * Display: Körpertemperatur
          * System: http://loinc.org
          * Version: (can be configured with the property 'loinc-version')
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in 'observation-patient-id')
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in 'observation-encounter-id')
      * Performer: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in 'observation-practitioner-id')
      * Device: any (store the ID in 'observation-device-id')
      * Effective date/time: 2026-03-12T08:48:00+01:00
      * Body Site:
        - Coding:
          * Code: 76784001
          * Display: Vaginal structure
          * System: http://snomed.info/sct
          * Version: 20251115 (configured with the property 'snomed-ct-version')
      * Value:
        - Quantity:
          * Value: 37.2
          * Unit: degree Celsius
          * System: http://unitsofmeasure.org
          * Code: Cel
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate the Observation by its ID
    Then Get FHIR resource at "http://fhirserver/Observation/${icuminimal.observation-read-temperature-vaginal-id}" with content type "xml"
    And resource has ID "${icuminimal.observation-read-temperature-vaginal-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/sd-mii-icu-koerpertemperatur-vaginal"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'vital-signs' and system = 'http://terminology.hl7.org/CodeSystem/observation-category').exists()" with error message 'The category does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '364246006' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${icuminimal.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The SNOMED code does not match the expected value'
    And element "device" references resource with ID "Device/${icuminimal.observation-device-id}" with error message "The referenced device does not match the expected value"
    And element "subject" references resource with ID "Patient/${icuminimal.observation-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${icuminimal.observation-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${icuminimal.observation-practitioner-id}" with error message "The referenced performer does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2026-03-12T08:48:00+01:00')" with error message 'The effective date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.value = 37.2" with error message 'The value does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.unit = 'degree Celsius'" with error message 'The unit does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.system = 'http://unitsofmeasure.org'" with error message 'The system does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.code = 'Cel'" with error message 'The UCUM code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "bodySite.coding.where(code = '76784001' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${icuminimal.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The body site does not match the expected value'
