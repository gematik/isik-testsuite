# language: en
@Stufe5
@Basis
@Mandatory
@Account-Read
Feature: Read Information from a resource of type Account (@Account-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'account-read-id'.

      Create an Account resource in your system, with the following values:

      * Identifier: Value defined through the configuration variables 'account-read-identifier-value' and 'account-read-identifier-system'
      * Identifier Type Code: AN
      * Status: active
      * Coverage Extension Billing type: Diagnosis-related groups (DRG)
      * Coverage Priority: 1
      * Linked Coverage insurance relationship: Any
      * Linked Subject (Patient): Any — please store the patient ID in the configuration variable 'account-read-patient-id'.
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Account"

  Scenario: Read and Validate the Account by its ID
    When Get FHIR resource at "http://fhirserver/Account/${data.account-read-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKAbrechnungsfall"
    And resource has ID "${data.account-read-id}" with error message "The ID does not match the expected value"
    And TGR current response with attribute "$..status.value" matches "active"
    And element "subject" references resource with ID "${data.account-read-patient-id}" with error message "Referenced patient does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "identifier.where(system = '${data.account-read-identifier-system}' and value='${data.account-read-identifier-value}').exists()" with error message 'The Account does not contain the expected identifier value'
    And FHIR current response body evaluates the FHIRPath "identifier.where(system = '${data.account-read-identifier-system}' and value='${data.account-read-identifier-value}' and type.coding.where(system='http://terminology.hl7.org/CodeSystem/v2-0203' and code='AN').exists()).exists()" with error message 'The Account exists but does not have a valid type.'
    And FHIR current response body evaluates the FHIRPath "coverage.priority = 1" with error message 'The Account does not include priority 1 for the insurance coverage.'
    And FHIR current response body evaluates the FHIRPath "coverage.coverage.exists()" with error message 'The Account does not contain a linked coverage insurance relationship.'
    And FHIR current response body evaluates the FHIRPath "coverage.extension.where(url = 'http://fhir.de/StructureDefinition/ExtensionAbrechnungsart').exists()" with error message 'The Account does not contain an extension for the billing type.'
    And FHIR current response body evaluates the FHIRPath "coverage.extension.where(url = 'http://fhir.de/StructureDefinition/ExtensionAbrechnungsart' and value.code = 'DRG' and value.system = 'http://fhir.de/CodeSystem/dkgev/Abrechnungsart').exists()" with error message 'The Account does not contain the correct billing type.'
