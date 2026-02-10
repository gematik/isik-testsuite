# language: en
@Stufe5
@Terminplanung
@Mandatory
@Appointment-Search
Feature: Testing search parameters against the Appointment resource (@Appointment-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find the previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Appointment-Read test case must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "Appointment"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Appointment"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _tag             | token           |
      | _count           | number          |
      | status           | token           |
      | service-type     | token           |
      | specialty        | token           |
      | date             | date            |
      | slot             | reference       |
      | actor            | reference       |

  Scenario: Search for the Appointment by ID
    Then Get FHIR resource at "http://fhirserver/Appointment/?_id=${data.appointment-read-id}" with content type "xml"
    And response bundle contains resource with ID "${data.appointment-read-id}" with error message "The requested appointment ${data.appointment-read-id} is not contained in the response bundle"
    And Check if current response of resource "Appointment" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKTermin"

  @Optional
  Scenario: Search for the Appointment by Tag
    When Get FHIR resource at "http://fhirserver/Appointment/?_tag=${data.tag-system}%7C${data.tag-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Appointment by Count
    When Get FHIR resource at "http://fhirserver/Appointment/?_count" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'total > 0 and entry.resource.count() > 0' with error message 'No search results were found'

  Scenario: Search for the Appointment by Status
    Then Get FHIR resource at "http://fhirserver/Appointment/?status=cancelled" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(Appointment).count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Appointment).all(status = 'cancelled')" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Appointment by Service Type
    Then Get FHIR resource at "http://fhirserver/Appointment/?service-type=${data.schedule-read-servicetype-code}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(Appointment).count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Appointment).all(serviceType.coding.where(code='${data.schedule-read-servicetype-code}' and system='${data.schedule-read-servicetype-system}').exists())" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Appointment by Specialty
    Then Get FHIR resource at "http://fhirserver/Appointment/?specialty=http://ihe-d.de/CodeSystems/AerztlicheFachrichtungen%7CNEUR" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(Appointment).count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Appointment).all(specialty.coding.where(code = 'NEUR' and system ='http://ihe-d.de/CodeSystems/AerztlicheFachrichtungen').exists())" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Appointment by Date
    Then Get FHIR resource at "http://fhirserver/Appointment/?date=${data.slot-read-start}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(Appointment).count() > 0' with error message 'No search results were found'
    # The OR expression enables configuration of both full and partial date time values with different precision, e.g. slot-read-start: 2027-01-01, 2027-01-01T13:00:00, 2027-01-01T13:00:00.000, 2027-01-01T13:00:00+01:00
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Appointment).all(start.toString().contains('${data.slot-read-start}') or start ~ @${data.slot-read-start})" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Appointment by Slot
    Then Get FHIR resource at "http://fhirserver/Appointment/?slot=${data.slot-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(Appointment).count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Appointment).all(slot.where(reference.replaceMatches('/_history/.+','').matches('\\b${data.slot-read-id}$')).exists())" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Appointment by Actor
    Then Get FHIR resource at "http://fhirserver/Appointment/?actor=Patient/${data.appointment-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(Appointment).count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Appointment).all(participant.where(actor.where(reference.replaceMatches('/_history/.+','').matches('\\b${data.appointment-patient-id}$') and display.exists()).exists()).exists())" with error message 'There are search results, but they do not fully match the search criteria.'
