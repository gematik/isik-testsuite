# language: en
@Stufe5
@Basis
@Mandatory
@Binary-Read
Feature: Read Information from a resource of type Binary (@Binary-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'binary-read-id'.

      Create a Binary resource in your system, with the following values:

      * Mime-Type: text/plain
      * Textual Data (UTF-8, LF (Unix), Base64 encoded): Test
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Binary"

  Scenario: Read and Validate Binary data in FHIR format by its ID
    When Get FHIR resource at "http://fhirserver/Binary/${data.binary-read-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKBinary"
    And resource has ID "${data.binary-read-id}" with error message "The ID does not match the expected value"
    And TGR current response with attribute "$..contentType.value" matches "text/plain"
    And TGR current response with attribute "$..data.value" matches "VGVzdA=="

  @Optional
  Scenario: Read and Validate Binary data in native format by its ID
    When TGR send empty GET request to "http://fhirserver/Binary/${data.binary-read-id}" with headers:
      | Accept | text/plain |
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"
    And TGR current response with attribute "$.header.[~'content-type']" matches "text/plain"
    And TGR current response with attribute "$.body" matches "Test"
