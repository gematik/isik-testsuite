# language: en
@Stufe5
@Terminplanung
@Mandatory
@ISiKCapabilityStatementTerminRepositoryRolle
@Slot-Search
Feature: Testing search parameters against the Slot resource (@Slot-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find the previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Slot-Read test case must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "Slot"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Slot"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | schedule         | reference       |
      | status           | token           |
      | start            | date            |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |

  Scenario: Search for the Slot by ID
    Then Get FHIR resource at "http://fhirserver/Slot/?_id=${terminplanung.slot-read-id}" with content type "xml"
    And response bundle contains resource with ID "${terminplanung.slot-read-id}" with error message "The requested slot ${terminplanung.slot-read-id} is not contained in the response bundle"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "Slot" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKTerminblock"

  @Optional
  Scenario: Optional Search for the Slot by Tag and ID
    When Get FHIR resource at "http://fhirserver/Slot/?_tag=${terminplanung.tag-system}%7C${terminplanung.tag-value}&_id=${terminplanung.slot-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${terminplanung.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${terminplanung.slot-read-id}" with error message "The requested slot ${terminplanung.slot-read-id} is not contained in the response bundle"

  Scenario: Search for the Slot by Count
    When Get FHIR resource at "http://fhirserver/Slot/?_count=1" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= 1' with error message 'The _count parameter was not applied as expected'

  Scenario: Search for the Slot by Schedule
    Then Get FHIR resource at "http://fhirserver/Slot/?schedule=${terminplanung.schedule-read-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(Slot).count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Slot).all(schedule.where(reference.replaceMatches('/_history/.+','').matches('\\b${terminplanung.schedule-read-id}$')).exists())" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Slot by Status and Schedule
    Then Get FHIR resource at "http://fhirserver/Slot/?schedule=${terminplanung.schedule-read-id}&status=busy" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(Slot).count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Slot).all(status = 'busy')" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Slot by Start time
    Then Get FHIR resource at "http://fhirserver/Slot/?schedule=${terminplanung.schedule-read-id}&start=${terminplanung.slot-read-start}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(Slot).count() > 0' with error message 'No search results were found'
    # The OR expression enables configuration of both full and partial date time values with different precision, e.g. slot-read-start: 2024-01-01, 2024-01-01T13:00:00, 2024-01-01T13:00:00.000, 2024-01-01T13:00:00+01:00
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Slot).all(start.toString().contains('${terminplanung.slot-read-start}') or start ~ @${terminplanung.slot-read-start})" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Chaining search for slots by Practitioner
    Then Get FHIR resource at "http://fhirserver/Slot/?schedule.actor=Practitioner/${terminplanung.appointment-practitioner-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.where(id.replaceMatches("/_history/.+","").matches("\\b${terminplanung.slot-read-id}$")).exists()' with error message 'The requested slot ${terminplanung.slot-read-id} is not contained in the response bundle'
