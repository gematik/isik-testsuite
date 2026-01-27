# language: en
@Stufe5
@Basis
@Mandatory
@RelatedPerson-Read
Feature: Read Information from a resource of type RelatedPerson (@RelatedPerson-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
        - The test dataset must have been entered in the system under test according to the specifications (manually).
        - The ID of the corresponding FHIR resource for this test dataset must be stored in the configuration variable 'relatedperson-read-id'.

        Create a RelatedPerson resource with these fields:

        * First name: Maxine
        * Last name: Mustermann
        * Address: Musterstraße 3, 13187 Berlin, Germany
        * Patient reference: The patient from the Patient-Read test case
        * Patient-RelatedPerson relationship: DAUC (daughter of user of care)
        * Phone number: 030 1234567
        * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "RelatedPerson"

  Scenario: Read and Validate RelatedPerson resource by its ID
    When Get FHIR resource at "http://fhirserver/RelatedPerson/${data.relatedperson-read-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKAngehoeriger"
    And resource has ID "${data.relatedperson-read-id}" with error message "The ID does not match the expected value"
    And TGR current response with attribute "$..name.given.value" matches "Maxine"
    And TGR current response with attribute "$..name.family.value" matches "Mustermann"
    And FHIR current response body evaluates the FHIRPath "address.where(type = 'both' and city = 'Berlin' and postalCode = '13187' and country = 'DE' and line = 'Musterstraße 3' and line.extension.where(url = 'http://hl7.org/fhir/StructureDefinition/iso21090-ADXP-streetName' and value = 'Musterstraße').exists() and line.extension.where(url = 'http://hl7.org/fhir/StructureDefinition/iso21090-ADXP-houseNumber' and value = '3').exists()).exists()" with error message 'The address does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "relationship.coding.where(system = 'http://terminology.hl7.org/CodeSystem/v3-RoleCode' and code = 'DAUC').exists()" with error message 'The patient-related person relationship does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "telecom.where(system = 'phone' and value = '030 1234567').exists()" with error message 'The phone number does not match the expected value'
    And element "patient" references resource with ID "${data.patient-read-id}" with error message "${data.patient-read-id} is not registered as patient"
