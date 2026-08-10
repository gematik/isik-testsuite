# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementMedikationVerordnungRolle
@MedicationRequest-Create
Feature: Create a resource of type MedicationRequest (@MedicationRequest-Create)

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
    And CapabilityStatement contains interaction "create" for resource "MedicationRequest"

  Scenario: Create a MedicationRequest resource via POST
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send POST request to "http://fhirserver/MedicationRequest" with body "!{file('src/test/resources/features/Stufe5/Medikation/fixtures/MedicationRequest-Create-Fixture.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "20\d"
    # Asserts for the case if the response is a MedicationRequest resource or a Parameters one
    And FHIR current response body evaluates the FHIRPath '($this is MedicationRequest) or ($this is Parameters)' with error message 'The response contains neither a MedicationRequest nor a Parameters resource'
    # Tests for MedicationRequest resource
    And FHIR current response body evaluates the FHIRPath '($this is MedicationRequest) implies id.exists()' with error message 'No ID was assigned to the MedicationRequest'
    And FHIR current response body evaluates the FHIRPath "($this is MedicationRequest) implies status.toString().matches('^completed')" with error message 'MedicationRequest status does not have the value "completed"'
    And FHIR current response body evaluates the FHIRPath "($this is MedicationRequest) implies authoredOn.hasValue()" with error message 'MedicationRequest authoredOn does not contain a valid value'
    # Tests for Parameters resource
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is MedicationRequest).resource.id.exists()" with error message 'No ID was assigned to the MedicationRequest'
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is MedicationRequest).resource.status.toString().matches('^completed')" with error message 'MedicationRequest status does not have the value "completed"'
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is MedicationRequest).resource.authoredOn.hasValue()" with error message 'MedicationRequest authoredOn does not contain a valid value'
