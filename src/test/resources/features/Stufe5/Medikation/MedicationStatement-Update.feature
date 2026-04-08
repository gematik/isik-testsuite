# language: en
@Stufe5
@Medikation
@Mandatory
@MedicationStatement-Update
Feature: Update a resource of type MedicationStatement (@MedicationStatement-Update)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST update an existing resource."
    Given the Preconditions:
      """
        - The Medication-Read test case must have been executed successfully beforehand.
        - Store the ID of any MedicationStatement resource that should be updated with test data in the configuration variable 'medicationstatement-update-id'.
      """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "update" for resource "MedicationStatement"

  Scenario: Update a MedicationStatement resource
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send PUT request to "http://fhirserver/MedicationStatement/${data.medicationstatement-update-id}" with body "!{file('src/test/resources/features/Stufe5/Medikation/fixtures/MedicationStatement-Update-Fixture.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"
    And TGR send empty GET request to "http://fhirserver/MedicationStatement/${data.medicationstatement-update-id}"
    And TGR find the last request
    And TGR current response with attribute "$.body.note.0.text.content" matches "Updated test note"
    And FHIR current response body evaluates the FHIRPath "dosage.all(patientInstruction = 'Updated Patient Instructions')" with error message 'Patient instructions do not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosage.all(doseAndRate.dose.value = 5)" with error message 'Dose and rate information does not match the expected value'
