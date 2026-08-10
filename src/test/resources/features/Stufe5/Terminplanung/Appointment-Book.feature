# language: en
@Stufe5
@Terminplanung
@Mandatory
@ISiKCapabilityStatementTerminRepositoryRolle
@Appointment-Book
Feature: Booking an appointment (@Appointment-Book)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST support booking appointments."
    Given the Preconditions:
    """
      - A currently free and still unused slot must have been created manually in the system in any schedule and configured via 'appointment-book-slot-id'. The slot must overlap with the configured appointment start and end values ('appointment-book-datetime-start' and 'appointment-book-datetime-end').
      - After a successful execution, the configured slot will typically no longer be free. Therefore, use a fresh slot or reset the slot state before re-running this scenario.
      - Service type: any (please store in the configuration variables 'appointment-book-servicetype-system' and 'appointment-book-servicetype-code').

      Optional for the conflict scenario below:
      - A second slot that is already busy for the same time range can be configured via 'appointment-book-busy-slot-id' (for example the busy slot from the Slot-Read test case).
    """

  Scenario: Read and Validation of the CapabilityStatement
    Given Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains operation "book" for resource "Appointment"

  Scenario: Book an appointment using a free slot
    Given Get FHIR resource at "http://fhirserver/Slot/${terminplanung.appointment-book-slot-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath "$this is Slot" with error message 'The configured appointment-book-slot-id does not resolve to a Slot resource'
    And FHIR current response body evaluates the FHIRPath "status = 'free'" with error message "The configured slot for appointment-book-slot-id is not free. Use a fresh free slot before executing the happy-path booking scenario."
    And TGR set default header "Content-Type" to "application/fhir+json"
    And TGR send POST request to "http://fhirserver/Appointment/$book" with body "!{file('src/test/resources/features/Stufe5/Terminplanung/fixtures/Appointment-Appointment-Book-Fixture-With-Specialty.json')}"
    Then TGR find the last request
    And TGR current response with attribute "$.responseCode" matches "20\d"
    #  Asserts for the case if the response is an Appointment
    And FHIR current response body evaluates the FHIRPath '($this is Appointment) or ($this is Parameters)' with error message 'The response contains neither an Appointment nor a Parameters resource'
    And FHIR current response body evaluates the FHIRPath '($this is Appointment) implies id.exists()' with error message 'Response variant Appointment: no ID was assigned to the appointment'
    And FHIR current response body evaluates the FHIRPath "($this is Appointment) implies status.toString().matches('^booked|pending$')" with error message 'Response variant Appointment: no ID was assigned to the appointment'
    #  Asserts for the case if the response is a Parameters resource
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is Appointment).resource.id.exists()" with error message 'Response variant Parameters: no ID was assigned to the appointment'
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is Appointment).resource.status.toString().matches('^booked|pending$')" with error message 'Response variant Parameters: the appointment status is neither booked nor pending'

  Scenario: Book an appointment using a slot that is no longer free
    Given TGR set default header "Content-Type" to "application/fhir+json"
    And TGR send POST request to "http://fhirserver/Appointment/$book" with body "!{file('src/test/resources/features/Stufe5/Terminplanung/fixtures/Appointment-Appointment-Book-Busy-Slot-Fixture.json')}"
    Then TGR find the last request
    And TGR current response with attribute "$.responseCode" matches "4\d\d"
    And FHIR current response body evaluates the FHIRPath '$this is OperationOutcome' with error message 'The response does not contain an OperationOutcome resource'
    And FHIR current response body evaluates the FHIRPath "issue.where(severity = 'error' or severity = 'fatal').exists()" with error message 'The OperationOutcome does not contain an error issue'
    And FHIR current response body evaluates the FHIRPath "issue.where(code.empty().not()).exists()" with error message 'The OperationOutcome does not contain an issue with code conflict'
    And FHIR current response body evaluates the FHIRPath "issue.where(diagnostics.empty().not()).exists()" with error message 'The OperationOutcome diagnostics do not explain that the slot is already busy'

  Scenario: Book an appointment when the request is incomplete (no slot or schedule provided)
    Given TGR set default header "Content-Type" to "application/fhir+json"
    And TGR send POST request to "http://fhirserver/Appointment/$book" with body "!{file('src/test/resources/features/Stufe5/Terminplanung/fixtures/Appointment-Appointment-Book-Incomplete-Fixture.json')}"
    Then TGR find the last request
    And TGR current response with attribute "$.responseCode" matches "422"
    And FHIR current response body evaluates the FHIRPath '$this is OperationOutcome' with error message 'The response does not contain an OperationOutcome resource'
