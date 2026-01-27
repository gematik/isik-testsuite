# language: en
@Stufe5
@Basis
@Mandatory
@Encounter-Read-In-Progress
Feature: Read Information from a resource of type Encounter with status "in progress" (@Encounter-Read-In-Progress)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The Patient-Read test case must have been executed successfully beforehand.
      - The Condition-Read-Active test case must have been executed successfully beforehand.
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset and the assigned facility-internal admission number must be stored in the configuration variable 'encounter-read-in-progress-id'.

      Create an Encounter resource with these fields (add the optional values if you want to pass the optional search tests too):

      * Admission number: a valid admission number assigned by the system (Please, set it in the configuration variable 'encounter-read-in-progress-identifier-value')
      * Status: in-progress
      * Type: inpatient (normalstationaer)
      * Patient: the patient from the Patient-Read test case
      * Admission reason: referral by a doctor
      * Department: General Surgery
      * Start of encounter: 2026-01-06
      * Service provider (identifier): 1234567890
      * Service provider (display): Hospital
      * Location: reference to a Location with identifier 'https://test.krankenhaus.de/fhir/sid/zimmerId' and value 'Z001'
      * Diagnosis: the Condition from the Condition-Read-Active test case
      * (Optional) Service provider (reference): any
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Encounter"

  Scenario: Read and Validate in-progress Encounter by its ID
    When Get FHIR resource at "http://fhirserver/Encounter/${data.encounter-read-in-progress-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKKontaktGesundheitseinrichtung"
    And resource has ID "${data.encounter-read-in-progress-id}" with error message "The returned Encounter resource has not the expected ID"
    And TGR current response with attribute "$..status.value" matches "in-progress"
    And FHIR current response body evaluates the FHIRPath "identifier.where(system = '${data.encounter-read-in-progress-identifier-system}' and value='${data.encounter-read-in-progress-identifier-value}').exists()" with error message 'The Encounter does not contain the correct admission number'
    And FHIR current response body evaluates the FHIRPath "class.where(code = 'IMP' and system = 'http://terminology.hl7.org/CodeSystem/v3-ActCode').exists()" with error message 'The Encounter does not contain the correct class code'
    And FHIR current response body evaluates the FHIRPath "type.coding.where(code = 'normalstationaer' and system = 'http://fhir.de/CodeSystem/kontaktart-de').exists()" with error message 'The Encounter does not contain the correct type'
    And FHIR current response body evaluates the FHIRPath "serviceType.coding.where(code = '1500' and system = 'http://fhir.de/CodeSystem/dkgev/Fachabteilungsschluessel').exists()" with error message 'The Encounter does not contain the correct department code'
    And element "subject" references resource with ID "${data.patient-read-id}" with error message "The referenced Patient does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "period.start.toString().contains('2026-01-06')" with error message 'The Encounter does not contain a valid start date'
    And FHIR current response body evaluates the FHIRPath "hospitalization.admitSource.coding.where(code = 'E' and system = 'http://fhir.de/CodeSystem/dgkev/Aufnahmeanlass').exists()" with error message 'The Encounter does not contain the correct admission reason'
    And element "diagnosis.condition" references resource with ID "Condition/${data.condition-read-active-id}" with error message "The referenced Condition does not match the expected value."
    And FHIR current response body evaluates the FHIRPath "location.location.identifier.where(system = 'https://test.krankenhaus.de/fhir/sid/zimmerId' and value = 'Z001').exists()" with error message 'The location does not contain the correct code'
