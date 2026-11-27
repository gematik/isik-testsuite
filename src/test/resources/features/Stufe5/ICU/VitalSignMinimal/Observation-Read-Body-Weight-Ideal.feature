# language: en
@Stufe5
@ICUMinimal
@VitalSignICUSourceMinimalAkteur
@Mandatory
@ISiKCapabilityStatementVitalSignICUSourceMinimalRolle
@Observation-Read-Body-Weight-Ideal
Feature: Read information from an Observation for ideal body weight (@Observation-Read-Body-Weight-Ideal)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'observation-read-body-weight-ideal-id'.

      Create an Observation resource in your system with the following values:
      * Id: the value of the configuration variable 'observation-read-body-weight-ideal-id'
      * Profile: sd-mii-icu-ideales-koerpergewicht
      * Status: final
      * Category:
        - Coding:
          * Code: vital-signs
          * System: http://terminology.hl7.org/CodeSystem/observation-category
      * Code:
        - Coding:
          * Code: 170804003
          * Display: Ideal body weight
          * System: http://snomed.info/sct
          * Version: 20251115 (configured with 'snomed-ct-version')
        - Coding:
          * Code: 50064-5
          * Display: Ideal body weight
          * System: http://loinc.org
          * Version: 2.81 (configured with 'loinc-version')
        - Coding:
          * Code: 188796
          * Display: MDC_MASS_BODY_EST_IBW
          * System: urn:iso:std:iso:11073:10101
      * Patient: store the ID in 'observation-patient-id'
      * Encounter: store the ID in 'observation-encounter-id'
      * Performer: store the ID in 'observation-practitioner-id'
      * Device: store the ID in 'observation-device-id'
      * Effective date/time: 2024-03-12T08:25:00+01:00
      * Value: 72 kg
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate the Observation by its ID
    Then Get FHIR resource at "http://fhirserver/Observation/${icuminimal.observation-read-body-weight-ideal-id}" with content type "xml"
    And resource has ID "${icuminimal.observation-read-body-weight-ideal-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/sd-mii-icu-ideales-koerpergewicht"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'vital-signs' and system = 'http://terminology.hl7.org/CodeSystem/observation-category').exists()" with error message 'The category does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '170804003' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${icuminimal.snomed-ct-version}' and display = 'Ideal body weight').exists()" with error message 'The SNOMED CT code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '50064-5' and system = 'http://loinc.org' and version = '${icuminimal.loinc-version}' and display = 'Ideal body weight').exists()" with error message 'The LOINC code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '188796' and system = 'urn:iso:std:iso:11073:10101' and display = 'MDC_MASS_BODY_EST_IBW').exists()" with error message 'The IEEE 11073 code does not match the expected value'
    And element "subject" references resource with ID "Patient/${icuminimal.observation-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${icuminimal.observation-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${icuminimal.observation-practitioner-id}" with error message "The referenced performer does not match the expected value"
    And element "device" references resource with ID "Device/${icuminimal.observation-device-id}" with error message "The referenced device does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2024-03-12T08:25:00+01:00')" with error message 'The effective date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.where(value ~ 72 and unit = 'kilogram' and system = 'http://unitsofmeasure.org' and code = 'kg').exists()" with error message 'The ideal body weight value does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "interpretation.coding.where(code = 'N' and system = 'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation' and display = 'Normal').exists()" with error message 'The interpretation does not match the expected value'
