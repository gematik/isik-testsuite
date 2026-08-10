# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementMedikamentRolle
@Medication-Update
Feature: Update a resource of type Medication (@Medication-Update)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST update an existing resource."
    Given the Preconditions:
      """
        - The Medication-Read test case must have been executed successfully beforehand.
        - Store the ID of any Medication resource that should be updated with test data in the configuration variable 'medication-update-id'.
      """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "update" for resource "Medication"

  Scenario: Update a Medication resource
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send PUT request to "http://fhirserver/Medication/${medikation.medication-update-id}" with body "!{file('src/test/resources/features/Stufe5/Medikation/fixtures/Medication-Update-Fixture.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"
    And TGR send empty GET request to "http://fhirserver/Medication/${medikation.medication-update-id}"
    And TGR find the last request
    And FHIR current response body evaluates the FHIRPath "amount.numerator.value ~ 40" with error message 'The amount was not updated or was updated incorrectly'
