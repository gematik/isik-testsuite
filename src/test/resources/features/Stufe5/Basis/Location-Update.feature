# language: en
@Stufe5
@Basis
@Optional
@ISiKCapabilityStatementAufbaustrukturRolle
@Location-Update
Feature: Update a resource of type Location (@Location-Update) (Optional)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST update an existing Location resource with a PUT request and return the updated resource on a subsequent GET request."
    Given the Preconditions:
    """
      - A Location resource with the ID from the configuration variable 'location-update-id' must exist in the system under test before this test is run.
      - The Location resource must conform to the ISiKStandort profile and contain a Location identifier.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "update" for resource "Location"

  Scenario: Update a Location resource
    Given Get FHIR resource at "http://fhirserver/Location/${basis.location-update-id}" with content type "json"
    And TGR current response with attribute "$.header.[~'etag']" matches ".+"
    And TGR store current response node text value at "$.header.[~'etag']" in variable "basis.location-update-etag"
    And TGR set default header "If-Match" to "${basis.location-update-etag}"
    And TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send PUT request to "http://fhirserver/Location/${basis.location-update-id}" with body "!{file('src/test/resources/features/Stufe5/Basis/fixtures/Location-Update-Fixture.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"
    And TGR clear default header "If-Match"
    And TGR send empty GET request to "http://fhirserver/Location/${basis.location-update-id}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKStandort"
    And resource has ID "${basis.location-update-id}" with error message "The ID does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "name = 'Station B Updated'" with error message 'The Location name was not updated correctly'
