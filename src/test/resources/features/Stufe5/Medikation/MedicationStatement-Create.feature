# language: en
@Stufe5
@Medikation
@Mandatory
@MedicationStatement-Create
Feature: Create a resource of type MedicationStatement (@MedicationStatement-Create)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST create the resource internally."
    Given the Preconditions:
      """
        The MedicationStatement-Read test case must have been executed successfully beforehand.

        For the execution of this test case, the following resources must exist in the system under test:
        * Medication: a valid ISiKMedikament resource - the Id can be customised with the variable 'medication-read-id'
        * Patient: a valid ISiKPatient resource - the Id can be customised with the variable 'medication-patient-id'
        * Encounter: a valid ISiKKontaktGesundheitseinrichtung resource - the Id can be customised with the variable 'medication-encounter-id'
        * Condition: a valid ISiKDiagnose resource - the Id can be customised with the variable 'medication-condition-id'
      """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "create" for resource "MedicationStatement"

  Scenario: Create a MedicationStatement resource via POST
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send POST request to "http://fhirserver/MedicationStatement" with body "!{file('src/test/resources/features/Stufe5/Medikation/fixtures/MedicationStatement-Create-Fixture.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "201"
    # Asserts for the case if the response is a MedicationStatement resource or a Parameters one
    And FHIR current response body evaluates the FHIRPath '($this is MedicationStatement) or ($this is Parameters)' with error message 'The response contains neither a MedicationStatement nor a Parameters resource'
    # Tests for MedicationStatement resource
    And FHIR current response body evaluates the FHIRPath '($this is MedicationStatement) implies id.exists()' with error message 'No ID was assigned to the MedicationStatement'
    And FHIR current response body evaluates the FHIRPath "($this is MedicationStatement) implies status.toString().matches('^active')" with error message 'MedicationStatement status does not have the value "active"'
    And FHIR current response body evaluates the FHIRPath "($this is MedicationStatement) implies note.text.toString().empty().not()" with error message 'MedicationStatement note does not contain a valid text'
    # Tests for Parameters resource
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is MedicationStatement).resource.id.exists()" with error message 'No ID was assigned to the MedicationStatement'
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is MedicationStatement).resource.status.toString().matches('^active')" with error message 'MedicationStatement status does not have the value "active"'
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is MedicationStatement).resource.note.text.toString().empty().not()" with error message 'MedicationStatement note does not contain a valid text'
