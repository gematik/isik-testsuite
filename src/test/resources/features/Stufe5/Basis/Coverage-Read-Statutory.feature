# language: en
@Stufe5
@Basis
@Mandatory
@Coverage-Read-Statutory
Feature: Read Information from a resource of type "statutory" Coverage (@Coverage-Read-Statutory)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The Patient-Read test case must have been executed successfully beforehand.
      - The RelatedPerson-Read test case must have been executed successfully beforehand.
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset must be stored in the configuration variable 'coverage-read-statutory-id'.
      - The FHIR Profile for the resource is ISiKVersicherungsverhaeltnisGesetzlich

      Create a Coverage resource with these fields:

      * Status: active/valid
      * Coverage type: statutory (gesetzlich)
      * Insurer: AOK Baden-Württemberg
      * IK-Number: 108018007
      * Insured person's statutory insurance number (GKV): from the Patient-Read test case
      * Beneficiary: the patient from the Patient-Read test case
      * Subscriber: reference to the RelatedPerson from the RelatedPerson-Read test case; Insurance Number (KVNR) belongs to the Subscriber themselves
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Coverage"

  Scenario: Read and Validate statutory Coverage by its ID
    When Get FHIR resource at "http://fhirserver/Coverage/${data.coverage-read-statutory-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKVersicherungsverhaeltnisGesetzlich"
    And resource has ID "${data.coverage-read-statutory-id}" with error message "The returned Coverage resource has not the expected ID"
    And FHIR current response body evaluates the FHIRPath "type.coding.where(system='http://fhir.de/CodeSystem/versicherungsart-de-basis' and code = 'GKV').exists()" with error message 'The type does not match the expected value'
    And element "beneficiary" references resource with ID "${data.patient-read-id}" with error message "The referenced patient does not match the expected value."
    And TGR current response with attribute "$..status.value" matches "active"
    And FHIR current response body evaluates the FHIRPath "payor.identifier.type.coding.where(system = 'http://terminology.hl7.org/CodeSystem/v2-0203' and code = 'XX').exists()" with error message "The type of the insurer's identifier does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "payor.identifier.where(system = 'http://fhir.de/sid/arge-ik/iknr' and value = '108018007').exists()" with error message "The insurer's identifier does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "payor.display = 'AOK Baden-Württemberg'" with error message "The insurer's display value does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "subscriber.reference.exists()" with error message 'A reference to a RelatedPerson as Subscriber was not found'
    And FHIR current response body evaluates the FHIRPath "subscriber.identifier.type.coding.where(system = 'http://fhir.de/CodeSystem/identifier-type-de-basis' and code = 'KVZ10').exists()" with error message "The subscriber's identifier type does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "subscriber.identifier.where(system = 'http://fhir.de/sid/gkv/kvid-10' and value = '${data.related-person-identifier-value}').exists()" with error message "The subscriber's identifier does not match the expected value"
