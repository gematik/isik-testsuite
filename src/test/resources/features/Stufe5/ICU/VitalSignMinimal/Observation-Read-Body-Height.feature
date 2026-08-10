# language: en
@Stufe5
@ICUMinimal
@VitalSignICUSourceMinimalAkteur
@Mandatory
@ISiKCapabilityStatementVitalSignStandardSourceRolle
@Observation-Read-Body-Height
Feature: Read Information from a resource of type Observation for body height (@Observation-Read-Body-Height)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'observation-read-body-height-id'.

      Create an Observation resource in your system with the following values:
      * Id: the value of the configuration variable 'observation-read-body-height-id'
      * Profile: ISiKKoerpergroesse
      * Status: final
      * Category: vital-signs
      * Code:
        - Coding:
          * Code: 8302-2
          * Display: Body height
          * System: http://loinc.org
          * Version: 2.81 (can be configured with the property 'loinc-version')
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in 'observation-patient-id')
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in 'observation-encounter-id')
      * Performer: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in 'observation-practitioner-id')
      * Effective date/time: 2026-03-05
      * Value: 184 cm
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate the Observation by its ID
    Then Get FHIR resource at "http://fhirserver/Observation/${icuminimal.observation-read-body-height-id}" with content type "xml"
    And resource has ID "${icuminimal.observation-read-body-height-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKKoerpergroesse"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'vital-signs' and system = 'http://terminology.hl7.org/CodeSystem/observation-category').exists()" with error message 'The category does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '8302-2' and system = 'http://loinc.org' and version = '${icuminimal.loinc-version}' and display.empty().not()).exists()" with error message 'The code does not match the expected value'
    And element "subject" references resource with ID "Patient/${icuminimal.observation-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${icuminimal.observation-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${icuminimal.observation-practitioner-id}" with error message "The referenced performer does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2026-03-05')" with error message 'The effective date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.where(value ~ 184 and code = 'cm' and unit.exists() and system = 'http://unitsofmeasure.org').exists()" with error message 'The value does not match the expected value'

