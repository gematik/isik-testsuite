# language: en
@Stufe5
@Terminplanung
@Mandatory
@HealthcareService-Read
Feature: Read Information from a resource of type HealthcareService (@HealthcareService-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the created resource correctly and completely in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'healthcareservice-read-id'.

      Create the following HealthcareService resource in your system:

      * Active: true
      * Service type: any (please store the code system and code in the configuration variables 'healthcareservice-read-servicetype-system' and 'healthcareservice-read-servicetype-code')
      * Specialty: Neurology
      * Name: any (please store the value in the configuration variable 'healthcareservice-read-name')
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "HealthcareService"

  Scenario: Read a HealthcareService by ID
    Then Get FHIR resource at "http://fhirserver/HealthcareService/${data.healthcareservice-read-id}" with content type "xml"
    And resource has ID "${data.healthcareservice-read-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedizinischeBehandlungseinheit"
    And TGR current response with attribute "$..active.value" matches "true"
    And FHIR current response body evaluates the FHIRPath "type.where(coding.where(code = '${data.healthcareservice-read-servicetype-code}' and system = '${data.healthcareservice-read-servicetype-system}').exists()).exists()" with error message 'The type does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "specialty.coding.where(code = 'NEUR' and system ='http://ihe-d.de/CodeSystems/AerztlicheFachrichtungen').exists()" with error message 'The specialty does not match the expected value'
    And TGR current response with attribute "$..name.value" matches "${data.healthcareservice-read-name}"
    