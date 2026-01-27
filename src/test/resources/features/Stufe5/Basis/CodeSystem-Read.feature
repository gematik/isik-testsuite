# language: en
@Stufe5
@Basis
@Optional
@CodeSystem-Read
Feature: Read Information from a resource of type CodeSystem (@CodeSystem-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset must be stored in the configuration variable 'codesystem-read-id'.

      Create the following CodeSystem resource in your system:

      * Url: http://example.org/fhir/CodeSystem/TestKatalog
      * Version: 1.0.0
      * Name: Test Catalog
      * Status: active
      * Content: complete
      * Contained code (code, display, definition): test, Test, This is a test code"
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "CodeSystem"

  Scenario: Read and Validate CodeSystem by its ID
    When Get FHIR resource at "http://fhirserver/CodeSystem/${data.codesystem-read-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKCodeSystem"
    And resource has ID "${data.codesystem-read-id}" with error message "The ID does not match the expected value"
    And TGR current response with attribute "$..status.value" matches "active"
    And TGR current response with attribute "$..content.value" matches "complete"
    And TGR current response with attribute "$..url.value" matches "http://example.org/fhir/CodeSystem/TestKatalog"
    And TGR current response with attribute "$..name.value" matches "Test Catalog"
    And TGR current response with attribute "$..version.value" matches "1.0.0"
    And TGR current response contains node "$..concept"
    And FHIR current response body evaluates the FHIRPath 'concept.where(code = "test" and display = "Test" and definition = "This is a test code").exists()' with error message 'The resource does not contain the expected code'
