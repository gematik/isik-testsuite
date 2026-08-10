# language: en
@Stufe5
@Vitalparameter
@Mandatory
@ISiKCapabilityStatementVitalSignStandardSourceRolle
@Observation-Read-Body-Weight
Feature: Read Information from a resource of type Observation for body weight (@Observation-Read-Body-Weight)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
	"""
	  - The test data set must have been recorded in the system under test according to the specifications (manually).
	  - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'observation-read-body-weight-id'.

	  Create an Observation resource in your system with the following values:
	  * Id: the value of the configuration variable 'observation-read-body-weight-id'
	  * Profile: ISiKKoerpergewicht
	  * Status: final
	  * Category: vital-signs
	  * Code:
        - Coding:
          * Code: 29463-7
          * Display: Body weight
          * System: http://loinc.org
          * Version: 2.81 (can be configured with the property 'loinc-version')
	  * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in 'observation-patient-id')
	  * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in 'observation-encounter-id')
	  * Performer: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in 'observation-practitioner-id')
	  * Effective date/time: 2026-01-06
	  * Value: 79 kg
	"""

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate the Observation by its ID
    Then Get FHIR resource at "http://fhirserver/Observation/${vitalparameter.observation-read-body-weight-id}" with content type "xml"
    And resource has ID "${vitalparameter.observation-read-body-weight-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKKoerpergewicht"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'vital-signs' and system = 'http://terminology.hl7.org/CodeSystem/observation-category').exists()" with error message 'The category does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '29463-7' and system = 'http://loinc.org' and version = '${vitalparameter.loinc-version}' and display.empty().not()).exists()" with error message 'The code does not match the expected value'
    And element "subject" references resource with ID "Patient/${vitalparameter.observation-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${vitalparameter.observation-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${vitalparameter.observation-practitioner-id}" with error message "The referenced performer does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2026-01-06')" with error message 'The effective date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.where(value ~ 79 and code = 'kg' and unit.exists() and system = 'http://unitsofmeasure.org').exists()" with error message 'The value does not match the expected value'

