# language: en
@Stufe5
@Connect
@Mandatory
@Patient-Read-Scope
Feature: Test the Access to a Patient Resource with the Patient Scope (@Patient-Read-Scope)

  @Precondition
  Scenario: Access token has been issued and is active
    Given the Test Description: "The system under test must support the SMART-on-FHIR Authentication flow."
    Given the Preconditions:
    """
     - A valid Bearer Token for the scope "patient/Patient.rs" has been retrieved and configured with the property `connect.read-patient-scope-allowed`
     - A valid Patient Id, bounded to the Bearer Token, configured with the property `connect.read-patient-in-context-id`
     - A valid Patient Id, that is not bounded to the Bearer Token (not in context), with the property `connect.read-patient-not-in-context-id`
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Patient"
    And CapabilityStatement contains interaction "search-type" for resource "Patient"

  Scenario: Access a specific Patient Resource by ID with the patient/Patient.rs scope
    When TGR send empty GET request to "http://fhirserver/Patient/${connect.read-patient-in-context-id}" with headers:
      | Accept        | application/fhir+json                        |
      | Authorization | Bearer ${connect.read-patient-scope-allowed} |
    Then TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"

  Scenario: Search for Patients with the patient/Patient.rs scope returns only one Patient
    When TGR send empty GET request to "http://fhirserver/Patient" with headers:
      | Accept        | application/fhir+json                        |
      | Authorization | Bearer ${connect.read-patient-scope-allowed} |
    Then TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"
    Then FHIR current response body evaluates the FHIRPath "Bundle.entry.where(resource is Patient).count() = 1" with error message "Expected only a single Patient resource in the bundle"
    Then FHIR current response body evaluates the FHIRPath "Bundle.entry.where(id = ${connect.read-patient-in-context-id}).exists()" with error message "Expected the specific Patient resource to exist in the bundle"

  Scenario: Access to Condition resources of patients not in context is forbidden
    When TGR send empty GET request to "http://fhirserver/Condition?subject=Patient/${connect.read-patient-not-in-context-id}" with headers:
      | Accept        | application/fhir+json                        |
      | Authorization | Bearer ${connect.read-patient-scope-allowed} |
    Then TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"
    Then FHIR current response body evaluates the FHIRPath "Bundle.entry.where(resource is Condition).count() = 0" with error message "Search for Condition resources leaks other resources"

  Scenario: Access to Encounter resources is forbidden
    When TGR send empty GET request to "http://fhirserver/Encounter?_count=10" with headers:
      | Accept        | application/fhir+json                        |
      | Authorization | Bearer ${connect.read-patient-scope-allowed} |
    Then TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "40\d"
