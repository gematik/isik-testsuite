# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementMedikationVerabreichungRolle
@MedicationAdministration-Update
Feature: Update a resource of type MedicationAdministration (@MedicationAdministration-Update)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST update an existing resource."
    Given the Preconditions:
      """
        - The Medication-Read test case must have been executed successfully beforehand.
        - Store the ID of any MedicationAdministration resource that should be updated with test data in the configuration variable 'medicationadministration-update-id'.
      """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "update" for resource "MedicationAdministration"

  Scenario: Update a MedicationAdministration resource
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send PUT request to "http://fhirserver/MedicationAdministration/${medikation.medicationadministration-update-id}" with body "!{file('src/test/resources/features/Stufe5/Medikation/fixtures/MedicationAdministration-Update-Fixture.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"
    And TGR send empty GET request to "http://fhirserver/MedicationAdministration/${medikation.medicationadministration-update-id}"
    And TGR find the last request
    And TGR current response with attribute "$.body.note.0.text.content" matches "Updated note"
    Then TGR current response with attribute "$.body.dosage.dose.value.content" matches "5"