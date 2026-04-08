# language: en
@Stufe5
@Medikation
@Mandatory
@RiskAssessment-Update
Feature: Update a resource of type RiskAssessment (@RiskAssessment-Update)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST update an existing resource."
    Given the Preconditions:
      """
        - The RiskAssessment-Create test case must have been executed successfully beforehand.
        - Store the ID of any RiskAssessment resource that should be updated with test data in the configuration variable 'riskassessment-update-id'.
      """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "update" for resource "RiskAssessment"

  Scenario: Update a RiskAssessment resource
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send PUT request to "http://fhirserver/RiskAssessment/${data.riskassessment-update-id}" with body "!{file('src/test/resources/features/Stufe5/Medikation/fixtures/RiskAssessment-Update-Fixture.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "20\d"
    And TGR send empty GET request to "http://fhirserver/RiskAssessment/${data.riskassessment-update-id}"
    And TGR find the last request
    And TGR current response with attribute "$.body.note.0.text.content" matches "Recheck on 28.02.2026"
    And TGR current response with attribute "$.body.code.text.content" matches "Updated text note"
