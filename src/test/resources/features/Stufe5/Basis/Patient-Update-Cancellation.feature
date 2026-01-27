# language: en
@Stufe5
@Basis
@Optional
@Patient-Update-Cancellation
Feature: Update Patient (@Patient-Update-Cancellation)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MAY perform an Update on the resource of type Patient using a PUT HTTP request to set the 'active' element to 'false'. After a successful update, the resource MUST be accessible via a GET request to the resource's URL, and the 'active' element MUST be set to 'false'."
    Given the Preconditions:
      """
        Create the following Patient resource in your system and store their ID in the configuration variable 'patient-update-cancellation-id':

        * Status: active
        * First name: Max
        * Last name: Storno-Update-Mustermann
        * Gender: male
        * Date of birth: 13.5.1968
        * Identifier: Any (please set in the configuration variables 'patient-update-cancellation-identifier-system' and 'patient-update-cancellation-identifier-value')
      """

  Scenario: Cancellation of a patient via Update
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send PUT request to "http://fhirserver/Patient/${data.patient-update-cancellation-id}" with body "!{file('src/test/resources/features/Stufe5/Basis/fixtures/Patient-Update-Cancellation-Inactive-Fixture.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"
    And TGR send empty GET request to "http://fhirserver/Patient/${data.patient-update-cancellation-id}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"
    And FHIR current response body evaluates the FHIRPath "active = false" with error message 'The active value does not match the expected value'
