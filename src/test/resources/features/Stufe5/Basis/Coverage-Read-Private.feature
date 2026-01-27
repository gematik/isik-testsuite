# language: en
@Stufe5
@Basis
@Mandatory
@Coverage-Read-Private
Feature: Read Information from a resource of type "private" Coverage (@Coverage-Read-Private)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The Patient-Read test case must have been executed successfully beforehand.
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset must be stored in the configuration variable 'coverage-read-private-id'.
      - The FHIR Profile for the resource is ISiKVersicherungsverhaeltnisSelbstzahler

      Create a Coverage resource with the following insurance relationship in your system:

      * Beneficiary: the patient from the Patient-Read test case
      * Status: active/valid
      * Coverage type: self-pay (Selbstzahler/privat)
      * Payor: same as the beneficiary
      * Payor display: the value from the variable 'patient-read-display-name'
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Coverage"

  Scenario: Read and Validate private Coverage by its ID
    When Get FHIR resource at "http://fhirserver/Coverage/${data.coverage-read-private-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKVersicherungsverhaeltnisSelbstzahler"
    And resource has ID "${data.coverage-read-private-id}" with error message "The returned Coverage resource has not the expected ID"
    And TGR current response with attribute "$..status.value" matches "active"
    And TGR current response with attribute "$..code.value" matches "SEL"
    And element "beneficiary" references resource with ID "${data.patient-read-id}" with error message "The payor does not match the expected value."
    And element "payor" references resource with ID "${data.patient-read-id}" with error message "The policy holder does not match the expected value."
    And FHIR current response body evaluates the FHIRPath "payor.display.contains('${data.patient-read-display-name}')" with error message 'The payor does not match the expected value.'
