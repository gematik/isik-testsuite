# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementMedikationVerordnungRolle
@MedicationRequest-Update
Feature: Update a resource of type MedicationRequest (@MedicationRequest-Update)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST update an existing resource."
    Given the Preconditions:
      """
        - The MedicationRequest-Create test case must have been executed successfully beforehand.
        - Store the ID of any MedicationRequest resource that should be updated with test data in the configuration variable 'medicationrequest-update-id'.
      """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "update" for resource "MedicationRequest"

  Scenario: Update a MedicationRequest resource
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send PUT request to "http://fhirserver/MedicationRequest/${medikation.medicationrequest-update-id}" with body "!{file('src/test/resources/features/Stufe5/Medikation/fixtures/MedicationRequest-Update-Fixture.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "20\d"
    And TGR send empty GET request to "http://fhirserver/MedicationRequest/${medikation.medicationrequest-update-id}"
    And TGR find the last request
    And TGR current response with attribute "$.body.note.0.text.content" matches "Updated note"
    And FHIR current response body evaluates the FHIRPath "dispenseRequest.quantity.value ~ 10" with error message 'The dispense quantity was not updated or was updated incorrectly'
    And FHIR current response body evaluates the FHIRPath "substitution.allowed = false" with error message 'Substitution allowed does not match the expected value'
