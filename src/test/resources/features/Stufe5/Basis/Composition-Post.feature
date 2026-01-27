# language: en
@Stufe5
@Basis
@Mandatory
@Composition-Post
Feature: Upload of a Document Bundle with POST Operation (@Composition-Post)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST be able to resolve the patients and Encounters referenced in the Composition by their identifiers."
    Given the Preconditions:
      """
       - The Encounter-Read-In-Progress test case must have been executed successfully beforehand.
      """

  Scenario: Upload of a DocumentBundle with known patients and Encounters with the POST Operation
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send POST request to "http://fhirserver/" with body "!{file('src/test/resources/features/Stufe5/Basis/fixtures/Composition-Post-CorrectCompositionBundle.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "20\d"

  Scenario Outline: Upload of an incorrect DocumentBundle with the POST Operation
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send POST request to "http://fhirserver/" with body "!{file('src/test/resources/features/Stufe5/Basis/fixtures/<inputFile>')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "<responseCode>"
    And FHIR current response body evaluates the FHIRPath "issue.where(severity = 'error' or 'fatal').count() >= 1" with error message 'The OperationOutcome does not contain the expected issue(s).'

    Examples:
      |  inputFile                                                 | responseCode |
      |  Composition-Post-CompositionBundleUnknownPatient.json     |    422       |
      |  Composition-Post-CompositionBundleUnknownEncounter.json   |    422       |
      |  Composition-Post-CompositionBundleMissingText.json        |    4\d\d     |