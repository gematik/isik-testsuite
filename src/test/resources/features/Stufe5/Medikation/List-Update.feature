# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementMedikationInformationRolle
@List-Update
Feature: Update a resource of type Medication List (@List-Update)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST update an existing resource and return the updated resource correctly."
    Given the Preconditions:
    """
      - The List-Create test case must have been executed successfully beforehand.
      - An additional MedicationStatement resource must exist in the system under test: a valid ISiKMedikationsInformation resource - the Id can be customised with the variable 'medicationstatement-read-extended-id'
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "update" for resource "List"

  Scenario: Update a Medication List resource
    When TGR set default header "Content-Type" to "application/fhir+json"
    And TGR send PUT request to "http://fhirserver/List/${medikation.list-update-id}" with body "!{file('src/test/resources/features/Stufe5/Medikation/fixtures/List-Update-Fixture.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"
    And TGR send empty GET request to "http://fhirserver/List/${medikation.list-update-id}"
    And TGR find the last request
    Then FHIR current response body evaluates the FHIRPath "entry.where(item.reference.replaceMatches('/_history/.+','').matches('MedicationStatement/${medikation.medicationstatement-read-id}$')).exists()" with error message 'List entry was not found'
    Then FHIR current response body evaluates the FHIRPath "entry.where(item.reference.replaceMatches('/_history/.+','').matches('MedicationStatement/${medikation.medicationstatement-read-extended-id}$')).exists()" with error message 'List entry was not found'