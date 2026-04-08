# language: en
@Stufe5
@Medikation
@Mandatory
@List-Create
Feature: Create a resource of type Medication List (@List-Create)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST be able to resolve the MedicationStatement, Patient and Encounter referenced by their literal reference (e.g. [ResourceType]/[id])."
    Given the Preconditions:
      """
        - The MedicationStatement-Read test case must have been executed successfully beforehand.

        For the execution of this test case, the following resources must exist in the system under test:
        * MedicationStatement: a valid ISiKMedikationsInformation resource - the Id can be customised with the variable 'medicationstatement-read-id'
        * Patient: a valid ISiKPatient resource - the Id can be customised with the variable 'medication-patient-id'
        * Encounter: a valid ISiKKontaktGesundheitseinrichtung resource - the Id can be customised with the variable 'medication-encounter-id'
      """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "create" for resource "List"

  Scenario: Create a Medication List via POST
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send POST request to "http://fhirserver/List" with body "!{file('src/test/resources/features/Stufe5/Medikation/fixtures/List-Create-Fixture.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "20\d"
    # Asserts for the case if the response is a List resource or a Parameters one
    And FHIR current response body evaluates the FHIRPath '($this is List) or ($this is Parameters)' with error message 'The response contains neither a List nor a Parameters resource'
    # Tests for List resource
    And FHIR current response body evaluates the FHIRPath '($this is List) implies id.exists()' with error message 'No ID was assigned to the List'
    And FHIR current response body evaluates the FHIRPath "($this is List) implies status.toString().matches('^current$')" with error message 'List status does not have the value "current"'
    And FHIR current response body evaluates the FHIRPath "($this is List) implies mode.toString().matches('^working')" with error message 'List mode does not have the value "working"'
    # Tests for Parameters resource
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is List).resource.id.exists()" with error message 'No ID was assigned to the List'
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is List).resource.status.toString().matches('^current$')" with error message 'List status does not have the value "current"'
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is List).resource.mode.toString().matches('^working$')" with error message 'List mode does not have the value "working"'
