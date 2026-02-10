# language: en
@Stufe5
@Terminplanung
@Mandatory
@Slot-Read
Feature: Read Information from a resource of type Slot (@Slot-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the created resource correctly and completely in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'slot-read-id'.

      Create the following Slot Resource in your system:

      * Status: busy
      * Start time: any time in the future (please store in the configuration variable 'slot-read-start')
      * End time: any time in the future
      * Schedule: the schedule from the Schedule-Read test case
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Slot"

  Scenario: Read a Slot by ID
    Then Get FHIR resource at "http://fhirserver/Slot/${data.slot-read-id}" with content type "xml"
    And resource has ID "${data.slot-read-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKTerminblock"
    And TGR current response with attribute "$..status.value" matches "busy"
    And element "schedule" references resource with ID "${data.schedule-read-id}" with error message "The referenced schedule is not correct"
    # The OR expression enables configuration of both full and partial date time values with different precision, e.g. slot-read-start: 2024-01-01, 2024-01-01T13:00:00, 2024-01-01T13:00:00.000, 2024-01-01T13:00:00+01:00
    And FHIR current response body evaluates the FHIRPath "start.toString().contains('${data.slot-read-start}') or start ~ @${data.slot-read-start}" with error message 'The slot start time does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "end.empty().not()" with error message 'The slot end time is not provided'