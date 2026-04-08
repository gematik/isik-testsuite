# language: en
@Stufe5
@Medikation
@Mandatory
@Medication-Create
Feature: Create a resource of type Medication (@Medication-Create)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST create the resource internally."
    Given the Preconditions:
      """
        - No preconditions
      """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "create" for resource "Medication"

  Scenario: Create a Medication resource via POST
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send POST request to "http://fhirserver/Medication" with body "!{file('src/test/resources/features/Stufe5/Medikation/fixtures/Medication-Create-Fixture.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "20\d"
    # Asserts for the case if the response is a Medication resource or a Parameters one
    And FHIR current response body evaluates the FHIRPath '($this is Medication) or ($this is Parameters)' with error message 'The response contains neither a Medication nor a Parameters resource'
    # Tests for Medication resource
    And FHIR current response body evaluates the FHIRPath '($this is Medication) implies id.exists()' with error message 'No ID was assigned to the Medication'
    And FHIR current response body evaluates the FHIRPath "($this is Medication) implies status.toString().matches('^active')" with error message 'Medication status does not have the value "active"'
    And FHIR current response body evaluates the FHIRPath "($this is Medication) implies manufacturer.display.toString().empty().not()" with error message 'Medication manufacturer does not have a display value'
    # Tests for Parameters resource
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is Medication).resource.id.exists()" with error message 'No ID was assigned to the Medication'
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is Medication).resource.status.toString().matches('^active')" with error message 'Medication status does not have the value "active"'
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is Medication).resource.manufacturer.display.toString().empty().not()" with error message 'Medication manufacturer does not have a display value'
