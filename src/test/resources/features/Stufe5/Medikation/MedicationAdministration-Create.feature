# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementMedikationVerabreichungRolle
@MedicationAdministration-Create
Feature: Create a resource of type MedicationAdministration (@MedicationAdministration-Create)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST create the resource internally."
    Given the Preconditions:
      """
        - The Medication-Read test case must have been executed successfully beforehand.

        For the execution of this test case, the following resources must exist in the system under test:
        * Medication: a valid ISiKMedikament resource - the Id can be customised with the variable 'medication-read-id'
        * Patient: a valid ISiKPatient resource - the Id can be customised with the variable 'medication-patient-id'
        * Encounter: a valid ISiKKontaktGesundheitseinrichtung resource - the Id can be customised with the variable 'medication-encounter-id'
        * Practitioner: a valid ISiKPersonImGesundheitsberuf resource - the Id can be customised with the variable 'medication-practitioner-id'
      """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "create" for resource "MedicationAdministration"

  Scenario: Create a MedicationAdministration resource via POST
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send POST request to "http://fhirserver/MedicationAdministration" with body "!{file('src/test/resources/features/Stufe5/Medikation/fixtures/MedicationAdministration-Create-Fixture.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "20\d"
    # Asserts for the case if the response is a MedicationAdministration resource or a Parameters one
    And FHIR current response body evaluates the FHIRPath '($this is MedicationAdministration) or ($this is Parameters)' with error message 'The response contains neither a MedicationAdministration nor a Parameters resource'
    # Tests for MedicationAdministration resource
    And FHIR current response body evaluates the FHIRPath '($this is MedicationAdministration) implies id.exists()' with error message 'No ID was assigned to the MedicationAdministration'
    And FHIR current response body evaluates the FHIRPath "($this is MedicationAdministration) implies status.toString().matches('^completed')" with error message 'MedicationAdministration status does not have the value "completed"'
    # Tests for Parameters resource
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is MedicationAdministration).resource.id.exists()" with error message 'No ID was assigned to the MedicationAdministration'
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is MedicationAdministration).resource.status.toString().matches('^completed')" with error message 'MedicationAdministration status does not have the value "completed"'
