# language: en
@Stufe5
@Terminplanung
@Mandatory
@Encounter-Appointment-Read
Feature: Read the Appointment Information from a resource of type Encounter (@Encounter-Appointment-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The Appointment-Read test case must have been executed successfully beforehand.
      - The test dataset must have been entered in the system under the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset and the assigned facility-internal admission number must be stored in the configuration variable 'encounter-read-planned-id'.

      Create an Encounter resource with these fields:

      * Admission number: a valid admission number assigned by the system (Please, set them in the configuration variables 'encounter-read-appointment-identifier-system' and 'encounter-read-appointment-identifier-value')
      * Status: planned
      * Type: inpatient (normalstationaer)
      * Class: IMP
      * Subject: Reference to the patient from the Patient-Read test case
      * Admission reason: referral by a doctor
      * Patient: reference to the Patient resource from the Appointment-Read test case
      * Department: General Surgery
      * Service provider (display): Hospital
      * Service provider ID (value): any (Please, set it in the configuration variable 'encounter-read-appointment-serviceprovider-identifier-value')
      * Planned start: 2026-02-12
      * Appointment: reference to the Appointment resource from the Appointment-Read test case
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Encounter"

  Scenario: Read and Validate planned Encounter by its ID
    When Get FHIR resource at "http://fhirserver/Encounter/${data.encounter-read-appointment-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKKontaktGesundheitseinrichtung"
    And resource has ID "${data.encounter-read-appointment-id}" with error message "The returned Encounter resource has not the expected ID"
    And TGR current response with attribute "$..status.value" matches "planned"
    And FHIR current response body evaluates the FHIRPath "identifier.where(system = '${data.encounter-read-appointment-identifier-system}' and value='${data.encounter-read-appointment-identifier-value}').exists()" with error message 'The Encounter does not contain the correct admission number'
    And FHIR current response body evaluates the FHIRPath "class.where(code = 'IMP' and system = 'http://terminology.hl7.org/CodeSystem/v3-ActCode').exists()" with error message 'The Encounter does not contain the correct class code'
    And FHIR current response body evaluates the FHIRPath "type.coding.where(code = 'normalstationaer' and system = 'http://fhir.de/CodeSystem/kontaktart-de').exists()" with error message 'The Encounter does not contain the correct type'
    And FHIR current response body evaluates the FHIRPath "serviceType.coding.where(code = '1500' and system = 'http://fhir.de/CodeSystem/dkgev/Fachabteilungsschluessel').exists()" with error message 'The Encounter does not contain the correct department code'
    And element "subject" references resource with ID "${data.appointment-patient-id}" with error message "The referenced Patient does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "hospitalization.admitSource.coding.where(code = 'E' and system = 'http://fhir.de/CodeSystem/dgkev/Aufnahmeanlass').exists()" with error message 'The encounter does not contain the correct admission reason'
    And FHIR current response body evaluates the FHIRPath "serviceProvider.display = 'Hospital'" with error message 'The service provider display value does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "serviceProvider.identifier.value = '${data.encounter-read-appointment-serviceprovider-identifier-value}'" with error message 'The service provider identifier value does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "period.exists().not()" with error message 'A planned Encounter should not contain a period (time range).'
