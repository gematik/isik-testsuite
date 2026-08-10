# language: en
@Stufe5
@Terminplanung
@Mandatory
@ISiKCapabilityStatementTerminRepositoryRolle
@Appointment-Book-By-Schedule
Feature: Booking an appointment by schedule reference (@Appointment-Book-By-Schedule)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST support booking appointments by schedule reference."
    Given the Preconditions:
    """
      A Slot resource in the schedule from the Schedule-Read test case must have been created manually with the following properties:

      * Status: free
      * Name:
      * Start time: 31.03.2027 10:05 (or set your own value in the configuration variable 'appointment-book-by-schedule-datetime-start' - must be in the future)
      * End time: 31.03.2027 10:55 (or set your own value in the configuration variable 'appointment-book-by-schedule-datetime-end' - must be in the future)
      * Treatment type: same as from the Schedule-Read test case

      In addition, no other non-free slot may overlap the configured time window in the same schedule.
      After a successful execution, the selected time window may no longer be reusable. Therefore, use a fresh free window or reset the test data before re-running this scenario.
    """

  Scenario: Book an appointment by schedule reference
    Given Get FHIR resource at "http://fhirserver/Slot/?schedule=${terminplanung.appointment-book-by-schedule-schedule-id}&start=${terminplanung.appointment-book-by-schedule-date}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(Slot).count() > 0' with error message 'No slots were found for the configured schedule and booking date'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Slot).where(status = 'free' and start <= @${terminplanung.appointment-book-by-schedule-datetime-start} and end >= @${terminplanung.appointment-book-by-schedule-datetime-end}).count() >= 1" with error message 'The configured schedule does not contain a free slot covering the requested appointment window'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Slot).where(status != 'free' and start < @${terminplanung.appointment-book-by-schedule-datetime-end} and end > @${terminplanung.appointment-book-by-schedule-datetime-start}).count() = 0" with error message 'The configured appointment window overlaps with at least one non-free slot in the selected schedule. Choose a different free time window before executing the happy-path scenario.'
    And TGR set default header "Content-Type" to "application/fhir+json"
    And TGR send POST request to "http://fhirserver/Appointment/$book" with body "!{file('src/test/resources/features/Stufe5/Terminplanung/fixtures/Appointment-Appointment-Book-By-Schedule-Parameters-Fixture.json')}"
    Then TGR find the last request
    And TGR current response with attribute "$.responseCode" matches "20\d"
    #  Asserts for the case if the response is an Appointment
    And FHIR current response body evaluates the FHIRPath '($this is Appointment) or ($this is Parameters)' with error message 'The response contains neither an Appointment nor a Parameters resource'
    And FHIR current response body evaluates the FHIRPath '($this is Appointment) implies id.exists()' with error message 'No ID was assigned to the appointment'
    And FHIR current response body evaluates the FHIRPath "($this is Appointment) implies status.toString().matches('^booked|pending$')" with error message 'Appointment status is neither booked nor pending'
    And FHIR current response body evaluates the FHIRPath "($this is Appointment) implies slot.exists()" with error message 'Appointment does not contain a slot reference'
    #  Asserts for the case if the response is a Parameters resource
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is Appointment).resource.id.exists()" with error message 'No ID was assigned to the Appointment'
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is Appointment).resource.status.toString().matches('^booked|pending$')" with error message 'the Appointment status is neither booked nor pending'
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is Appointment).resource.slot.exists()" with error message 'Appointment does not contain a slot reference'