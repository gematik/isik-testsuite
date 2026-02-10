# language: en
@Stufe5
@Terminplanung
@Mandatory
@Schedule-Read
Feature: Read Information from a resource of type Schedule (@Schedule-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the created resource correctly and completely in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'schedule-read-id'.

      Create the following Schedule resource in your system:

      * Active: true
      * Service type:
        - Text: any text that describes the service type (e.g., "Regular check-up")
        - Coding System: any (please provide the code system in the configuration variable 'schedule-read-servicetype-system')
        - Coding Code: any (please provide the code in the configuration variable 'schedule-read-servicetype-code')
      * Specialty: Neurology
      * Actor: Any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; please store the ID in the configuration variable 'appointment-practitioner-id')
      * Name: Any (not empty)
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Schedule"

  Scenario: Read a Schedule by ID
    Then Get FHIR resource at "http://fhirserver/Schedule/${data.schedule-read-id}" with content type "xml"
    And resource has ID "${data.schedule-read-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKKalender"
    And TGR current response with attribute "$..active.value" matches "true"
    And FHIR current response body evaluates the FHIRPath "serviceType.text.empty().not() and serviceType.coding.where(code='${data.schedule-read-servicetype-code}' and system = '${data.schedule-read-servicetype-system}').exists()" with error message 'The schedule type does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "specialty.coding.where(code = 'NEUR' and system ='http://ihe-d.de/CodeSystems/AerztlicheFachrichtungen').exists()" with error message 'The specialty does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "actor.where(reference.replaceMatches('/_history/.+','').matches('\\b${data.appointment-practitioner-id}$') and display.exists()).exists()" with error message 'The actor is missing or incomplete'
    And FHIR current response body evaluates the FHIRPath "extension.where(url = 'http://hl7.org/fhir/5.0/StructureDefinition/extension-Schedule.name' and value.empty().not()).exists()" with error message 'The schedule name is not provided'
