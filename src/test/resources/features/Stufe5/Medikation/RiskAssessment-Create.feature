# language: en
@Stufe5
@Medikation
@Mandatory
@RiskAssessment-Create
Feature: Create a resource of type RiskAssessment (@RiskAssessment-Create)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST create the resource internally."
    Given the Preconditions:
      """
        - The RiskAssessment-Read test case must have been executed successfully beforehand.

        For the execution of this test case, the following resources must exist in the system under test:
        * Condition: a valid ISiKDiagnose resource - the Id can be customised with the variable 'riskassessment-condition-id'
        * Encounter: a valid ISiKKontaktGesundheitseinrichtung resource - the Id can be customised with the variable 'riskassessment-encounter-id'
        * Observation: a valid ISiKKoerpergewicht resource - the Id can be customised with the variable 'riskassessment-observation-id'
        * Patient: a valid ISiKPatient resource - the Id can be customised with the variable 'riskassessment-patient-id'
      """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "create" for resource "RiskAssessment"

  Scenario: Create a RiskAssessment resource via POST
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send POST request to "http://fhirserver/RiskAssessment" with body "!{file('src/test/resources/features/Stufe5/Medikation/fixtures/RiskAssessment-Create-Fixture.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "20\d"
    # Asserts for the case if the response is a RiskAssessment resource or a Parameters one
    And FHIR current response body evaluates the FHIRPath '($this is RiskAssessment) or ($this is Parameters)' with error message 'The response contains neither a RiskAssessment nor a Parameters resource'
    # Tests for RiskAssessment resource
    And FHIR current response body evaluates the FHIRPath '($this is RiskAssessment) implies id.exists()' with error message 'No ID was assigned to the RiskAssessment'
    And FHIR current response body evaluates the FHIRPath "($this is RiskAssessment) implies status.toString().matches('^final')" with error message 'RiskAssessment status does not have the value "final"'
    # Tests for Parameters resource
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is RiskAssessment).resource.id.exists()" with error message 'No ID was assigned to the RiskAssessment'
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is RiskAssessment).resource.status.toString().matches('^final')" with error message 'RiskAssessment status does not have the value "final"'
