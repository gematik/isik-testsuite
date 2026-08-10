# language: en
@Stufe5
@Connect
@Mandatory
@System-Wildcard-Scope
Feature: Test the Access to all Resources with the System Scope (@System-Wildcard-Scope)

  @Precondition
  Scenario: Access token has been issued and is active
    Given the Test Description: "The system under test must support the SMART-on-FHIR Authentication flow."
    Given the Preconditions:
    """
     - A valid Bearer Token for the scope "system/*.rs" has been retrieved and configured with the property `connect.read-wildcard-scope-in-system-context-allowed`
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Condition"
    And CapabilityStatement contains interaction "search-type" for resource "Condition"

  Scenario: Search for Patients with the system/*.rs scope
    When TGR send empty GET request to "http://fhirserver/Patient?_count=10" with headers:
      | Accept        | application/fhir+json                        |
      | Authorization | Bearer ${connect.read-wildcard-scope-in-system-context-allowed} |
    Then TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"
    Then FHIR current response body evaluates the FHIRPath "Bundle.entry.where(resource is Patient).count() <= 10" with error message "Expected at most 10 Patient resources in the bundle"

  Scenario: Search for Encounter with the system/*.rs scope
    When TGR send empty GET request to "http://fhirserver/Encounter?_count=10" with headers:
      | Accept        | application/fhir+json                        |
      | Authorization | Bearer ${connect.read-wildcard-scope-in-system-context-allowed} |
    Then TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"
    Then FHIR current response body evaluates the FHIRPath "Bundle.entry.where(resource is Encounter).count() <= 10" with error message "Expected at most 10 Encounter resources in the bundle"
