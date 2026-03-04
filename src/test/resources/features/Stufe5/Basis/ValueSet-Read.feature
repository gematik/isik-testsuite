# language: en
@Stufe5
@Basis
@Mandatory
@ValueSet-Read
Feature: Read Information from a resource of type ValueSet (@ValueSet-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset must be stored in the configuration variable 'valueset-read-id'.

      Create a ValueSet in your system that contains codes 'sat' and 'sun' from the FHIR CodeSystem http://hl7.org/fhir/days-of-week:

      * Version: 1.0.0
      * Name: TestValueSet
      * Status: active
      * Context: Encounter
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "ValueSet"

  Scenario: Read and Validate ValueSet by its ID
    When Get FHIR resource at "http://fhirserver/ValueSet/${data.valueset-read-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKValueSet"
    And resource has ID "${data.valueset-read-id}" with error message "The ID does not match the expected value"
    Then TGR current response with attribute "$.responseCode" matches "200"
    And TGR current response with attribute "$.header.[~'content-type']" matches "application/fhir\+xml;\s*charset=(?i)UTF-8"
    And TGR current response with attribute "$..status.value" matches "active"
    And TGR current response with attribute "$..url.value" matches "http://example.org/fhir/ValueSet/TestValueSet"
    And TGR current response with attribute "$..name.value" matches "TestValueSet"
    And TGR current response with attribute "$..ValueSet.version.value" matches "1.0.0"
    And FHIR current response body evaluates the FHIRPath "useContext.value.coding.where(code = 'Encounter').exists()" with error message 'The ValueSet does not specify the required context'
    And FHIR current response body evaluates the FHIRPath "expansion.exists()" with error message 'The ValueSet does not contain an expansion'
    And FHIR current response body evaluates the FHIRPath "expansion.contains.where(code = 'sun' and display = 'Sunday' and system = 'http://hl7.org/fhir/days-of-week').exists()" with error message 'The ValueSet does not contain the required codes'
