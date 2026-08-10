# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementMedikationVerabreichungRolle
@MedicationAdministration-Read-Extended
Feature: Read Information from a resource of type MedicationAdministration with extended data (@MedicationAdministration-Read-Extended)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The ID of the corresponding FHIR resources for this test data set must be stored in the configuration variable 'medicationadministration-read-extended-id'.

      Create a MedicationAdministration resource in your system with the following values:
      * Status: completed
      * Medication:
        * code: V03AB23
        * display: Acetylcystein
        * system: http://fhir.de/CodeSystem/bfarm/atc
        * version: any (the value of the configuration variable 'atc-code-version')
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in the configuration variable 'medication-patient-id')
      * Patient identifier: identifier of the linked patient (store in 'medication-patient-identifier')
      * Effective date/time: 2026-02-03 (time is arbitrary)
      * Performer: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in the configuration variable 'medication-practitioner-id')
      * Performer identifier: identifier of the linked performer (store in 'medication-practitioner-identifier')
    """

  Scenario: Read and Validate the MedicationAdministration with extended data by its ID
    Then Get FHIR resource at "http://fhirserver/MedicationAdministration/${medikation.medicationadministration-read-extended-id}" with content type "xml"
    And resource has ID "${medikation.medicationadministration-read-extended-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationsVerabreichung"
    And TGR current response with attribute "$..status.value" matches "completed"
    And FHIR current response body evaluates the FHIRPath "medication.coding.where(code = 'V03AB23' and system = 'http://fhir.de/CodeSystem/bfarm/atc' and display = 'Acetylcystein').exists()" with error message 'The coded medication does not match the expected value'
    And element "subject" references resource with ID "Patient/${medikation.medication-patient-id}" with error message "The referenced patient does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "subject.identifier.value = '${medikation.medication-patient-identifier}'" with error message "The subject identifier does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2026-02-03')" with error message 'The effective date/time does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "performer.actor.reference.replaceMatches('/_history/.+','').matches('Practitioner/${medikation.medication-practitioner-id}$')" with error message 'The performer does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "performer.actor.identifier.value = '${medikation.medication-practitioner-identifier}'" with error message 'The performer identifier does not match the expected value'
