# language: en
@Stufe5
@Terminplanung
@Mandatory
@Appointment-Book-By-Schedule
Feature: Booking an appointment by schedule reference (@Appointment-Book-By-Schedule)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST support booking appointments by schedule reference."
    Given the Preconditions:
    """
      A Slot resource must have been created manually with the following properties:

      * Status: free
      * Name:
      * Start time: 31.1.2027 11:05 (or set your own value in the configuration variable 'appointment-book-by-schedule-datetime-start' - must be in the future)
      * End time: 31.1.2027 11:55 (or set your own value in the configuration variable 'appointment-book-by-schedule-datetime-end' - must be in the future)
      * Treatment type: same as from the Schedule-Read test case
    """

  Scenario: Book an appointment by schedule reference
    Given TGR set default header "Content-Type" to "application/fhir+json"
    And TGR send POST request to "http://fhirserver/Appointment/$book" with body "!{file('src/test/resources/features/Stufe5/Terminplanung/fixtures/Appointment-Appointment-Book-By-Schedule-Parameters-Fixture.json')}"
    Then TGR find the last request
    And TGR current response with attribute "$.responseCode" matches "20\d"
    #  Asserts for the case if the response is an Appointment
    And FHIR current response body evaluates the FHIRPath '($this is Appointment) or ($this is Parameters)' with error message 'The response contains neither an Appointment nor an OperationOutcome resource nor a Parameters resource'
    And FHIR current response body evaluates the FHIRPath '($this is Appointment) implies id.exists()' with error message 'Response variant Appointment: no ID was assigned to the appointment'
    And FHIR current response body evaluates the FHIRPath "($this is Appointment) implies status.toString().matches('^booked|pending$')" with error message 'Response variant Appointment: no ID was assigned to the appointment'
    And FHIR current response body evaluates the FHIRPath "($this is Appointment) implies slot.exists()" with error message 'Response variant Appointment: no slot assigned'
    #  Asserts for the case if the response is a Parameters resource
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is Appointment).resource.id.exists()" with error message 'Response variant Parameters: no ID was assigned to the appointment'
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is Appointment).resource.status.toString().matches('^booked|pending$')" with error message 'Response variant Parameters: the appointment status is neither booked nor pending'
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is Appointment).resource.slot.exists()" with error message 'Response variant Parameters: no slot assigned'