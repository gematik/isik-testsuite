# language: en
@Stufe5
@Terminplanung
@Mandatory
@Appointment-Book
Feature: Booking an appointment (@Appointment-Book)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST support booking appointments."
    Given the Preconditions:
    """
      - A free slot with start time 1.1.2027 09:00 and end time 1.1.2027 20:00 must have been created manually in the system in any schedule (please store the slot ID in the configuration variable 'appointment-book-slot-id').
      - Service type: any (please store in the configuration variables 'appointment-book-servicetype-system' and 'appointment-book-servicetype-code').
    """

  Scenario: Read and Validation of the CapabilityStatement
    Given Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains operation "book" for resource "Appointment"

  Scenario: Book an appointment using a free slot
    Given TGR set default header "Content-Type" to "application/fhir+json"
    And TGR send POST request to "http://fhirserver/Appointment/$book" with body "!{file('src/test/resources/features/Stufe5/Terminplanung/fixtures/Appointment-Appointment-Book-Fixture-With-Specialty.json')}"
    Then TGR find the last request
    And TGR current response with attribute "$.responseCode" matches "20\d"
    #  Asserts for the case if the response is an Appointment
    And FHIR current response body evaluates the FHIRPath '($this is Appointment) or ($this is Parameters)' with error message 'The response contains neither an Appointment nor an OperationOutcome resource nor a Parameters resource'
    And FHIR current response body evaluates the FHIRPath '($this is Appointment) implies id.exists()' with error message 'Response variant Appointment: no ID was assigned to the appointment'
    And FHIR current response body evaluates the FHIRPath "($this is Appointment) implies status.toString().matches('^booked|pending$')" with error message 'Response variant Appointment: no ID was assigned to the appointment'
    #  Asserts for the case if the response is a Parameters resource
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is Appointment).resource.id.exists()" with error message 'Response variant Parameters: no ID was assigned to the appointment'
    And FHIR current response body evaluates the FHIRPath "($this is Parameters) implies parameter.where(name = 'return' and resource is Appointment).resource.status.toString().matches('^booked|pending$')" with error message 'Response variant Parameters: the appointment status is neither booked nor pending'

  Scenario: Book an appointment when the request is incomplete (no slot or schedule provided)
    Given TGR set default header "Content-Type" to "application/fhir+json"
    And TGR send POST request to "http://fhirserver/Appointment/$book" with body "!{file('src/test/resources/features/Stufe5/Terminplanung/fixtures/Appointment-Appointment-Book-Incomplete-Fixture.json')}"
    Then TGR find the last request
    And TGR current response with attribute "$.responseCode" matches "400"
    And FHIR current response body evaluates the FHIRPath '$this is OperationOutcome' with error message 'The response does not contain an OperationOutcome resource'
