# language: en
@Stufe5
@Basis
@Optional
@Patient-Delete-Cancellation
Feature: Delete Patient (@Patient-Delete-Cancellation)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MAY perform a Delete on the resource of type Patient using a DELETE HTTP request. After a successful deletion, the resource MUST no longer be accessible and a subsequent GET request to the resource's URL MUST return an appropriate error code (e.g., 410 Gone or 404 Not Found)."
    Given the Preconditions:
      """
        - Create any patient in your system and store the resource ID in the configuration variable 'patient-delete-id'.
      """

  Scenario: Cancellation of a patient via Delete
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send empty DELETE request to "http://fhirserver/Patient/${data.patient-delete-id}"
    And TGR find the last request
    # Ignore content-type header, as it may be missing for 4** responses
    Then TGR current response with attribute "$.responseCode" matches "20\d"
    And TGR send empty GET request to "http://fhirserver/Patient/${data.patient-delete-id}"
    And TGR find the last request
    # Ignore content-type header, as it may be missing for 4** responses
    Then TGR current response with attribute "$.responseCode" matches "410|404"
