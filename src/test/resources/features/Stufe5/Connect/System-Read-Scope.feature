# language: en
@Stufe5
@Connect
@Mandatory
@System-Read-Scope
Feature: Test the Access to a Patient Resource with the System Scope (@System-Read-Scope)

  @Precondition
  Scenario: Access token has been issued and is active
    Given the Test Description: "The system under test must support the SMART-on-FHIR Authentication flow."
    Given the Preconditions:
    """
     - A valid Bearer Token for the scope "system/Patient.rs" has been retrieved and configured with the property `connect.read-patient-scope-in-system-context-allowed`
     - A valid Patient Id, bounded to the Bearer Token, configured with the property `connect.read-patient-in-system-context-id`
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Encounter"
    And CapabilityStatement contains interaction "search-type" for resource "Encounter"

  Scenario: Access a specific Patient Resource by ID with the system/Patient.rs scope
    When TGR send empty GET request to "http://fhirserver/Patient/${connect.read-patient-in-system-context-id}" with headers:
      | Accept        | application/fhir+json                        |
      | Authorization | Bearer ${connect.read-patient-scope-in-system-context-allowed} |
    Then TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"

  Scenario: Search for Patients with the system/Patient.rs scope
    When TGR send empty GET request to "http://fhirserver/Patient?_count=10" with headers:
      | Accept        | application/fhir+json                        |
      | Authorization | Bearer ${connect.read-patient-scope-in-system-context-allowed} |
    Then TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"
    Then FHIR current response body evaluates the FHIRPath "Bundle.entry.where(resource is Patient).count() <= 10" with error message "Expected at most 10 Patient resources in the bundle"

  Scenario: Access to Encounter resources is forbidden
    When TGR send empty GET request to "http://fhirserver/Encounter?_count=10" with headers:
      | Accept        | application/fhir+json                        |
      | Authorization | Bearer ${connect.read-patient-scope-in-system-context-allowed} |
    Then TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "40\d"
