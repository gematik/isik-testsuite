# language: en
@Stufe5
@Terminplanung
@Mandatory
@Appointment-Read
Feature: Read Information from a resource of type Appointment (@Appointment-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the created resource correctly and completely in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The Schedule-Read and Slot-Read test cases must have been executed successfully beforehand.
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'appointment-read-id'.

      Create the following Appointment resource as a replacement for any appointment in your system:

      * Replaced appointment: any
      * Status: cancelled
      * Cancellation reason: patient
      * Service type: the service type from the Schedule-Read test case
      * Specialty: Neurology
      * Priority: normal
      * Comment: any (not empty)
      * Start time: identical to the start time of the slot from the Slot-Read test case
      * End time: identical to the end time of the slot from the Slot-Read test case
      * Referenced slot: the slot from the Slot-Read test case
      * Patient instruction: any non-empty value
      * Participant: any (Please store the ID in the configuration variable 'appointment-patient-id', with display value; the linked Patient resource must conform to ISiKPatient)
      * Source: External
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Appointment"

  Scenario: Read an Appointment by ID
    Then Get FHIR resource at "http://fhirserver/Appointment/${data.appointment-read-id}" with content type "xml"
    And resource has ID "${data.appointment-read-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKTermin"
    And FHIR current response body evaluates the FHIRPath "meta.tag.where(system = 'http://fhir.de/CodeSystem/common-meta-tag-de').all(code = 'external')" with error message 'The value for the source identification does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "extension.where(url = 'http://hl7.org/fhir/5.0/StructureDefinition/extension-Appointment.replaces' and value.reference.exists()).exists()" with error message 'This appointment does not reference the replaced appointment'
    And TGR current response with attribute "$..Appointment.status.value" matches "cancelled"
    And FHIR current response body evaluates the FHIRPath "cancelationReason.coding.where(code = 'pat').exists()" with error message 'The cancellation reason does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "comment.empty().not()" with error message 'The comment field must contain a valid value'
    And FHIR current response body evaluates the FHIRPath "serviceType.coding.where(code='${data.schedule-read-servicetype-code}' and system = '${data.schedule-read-servicetype-system}').exists()" with error message 'The appointment service type does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "specialty.coding.where(code = 'NEUR' and system ='http://ihe-d.de/CodeSystems/AerztlicheFachrichtungen').exists()" with error message 'The specialty does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "priority.extension.where(url = 'https://gematik.de/fhir/isik/StructureDefinition/ISiKTerminPriorityExtension' and value.coding.where(code = '394848005' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}').exists()).exists()" with error message 'The priority does not match the expected value'
    # The OR expression enables configuration of both full and partial date time values with different precision, e.g. slot-read-start: 2027-01-01, 2027-01-01T13:00:00, 2027-01-01T13:00:00.000, 2027-01-01T13:00:00+01:00
    And FHIR current response body evaluates the FHIRPath "start.toString().contains('${data.slot-read-start}') or start ~ @${data.slot-read-start}" with error message 'The start time does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "end.empty().not()" with error message 'The end time does not match the expected value'
    And element "slot" references resource with ID "${data.slot-read-id}" with error message "The linked slot does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "patientInstruction.empty().not()" with error message 'The patient instruction is not defined'
    And FHIR current response body evaluates the FHIRPath "participant.actor.where(reference.replaceMatches('/_history/.+','').matches('\\b${data.appointment-patient-id}$') and display.exists()).exists()" with error message 'The participant does not match the expected value'
