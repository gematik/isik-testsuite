# language: en
@Stufe5
@Terminplanung
@Mandatory
@Schedule-Search
Feature: Testing search parameters against the Schedule resource (@Schedule-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find the previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Schedule-Read test case must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "Schedule"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Schedule"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | active           | token           |
      | service-type     | token           |
      | specialty        | token           |
      | actor            | reference       |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |

  Scenario: Search for the Schedule by ID
    Then Get FHIR resource at "http://fhirserver/Schedule/?_id=${data.schedule-read-id}" with content type "xml"
    And response bundle contains resource with ID "${data.schedule-read-id}" with error message "The requested Schedule ${data.schedule-read-id} is not contained in the response bundle"
    And Check if current response of resource "Schedule" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKKalender"

  @Optional
  Scenario: Search for the Schedule by Tag
    When Get FHIR resource at "http://fhirserver/Schedule/?_tag=${data.tag-system}%7C${data.tag-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Schedule by Count
    When Get FHIR resource at "http://fhirserver/Schedule/?_count" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'total > 0 and entry.resource.count() > 0' with error message 'No search results were found'

  Scenario: Search for the Schedule by Active state
    Then Get FHIR resource at "http://fhirserver/Schedule/?active=true" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(Schedule).count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Schedule).all(active = 'true')" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Schedule by Service Type
    Then Get FHIR resource at "http://fhirserver/Schedule/?service-type=${data.schedule-read-servicetype-code}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(Schedule).count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Schedule).all(serviceType.coding.where(code='${data.schedule-read-servicetype-code}').exists())" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Schedule by Specialty
    Then Get FHIR resource at "http://fhirserver/Schedule/?specialty=urn%3Aoid%3A1.2.276.0.76.5.114%7C142%2Chttp%3A%2F%2Fihe-d.de%2FCodeSystems%2FAerztlicheFachrichtungen%7CNEUR" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(Schedule).count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Schedule).all(specialty.coding.where((code = '142' and system ='urn:oid:1.2.276.0.76.5.114') or (code = 'NEUR' and system ='http://ihe-d.de/CodeSystems/AerztlicheFachrichtungen')).exists())" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Schedule by Actor
    Then Get FHIR resource at "http://fhirserver/Schedule/?actor=Practitioner/${data.appointment-practitioner-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(Schedule).count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Schedule).all(actor.where(reference.replaceMatches('/_history/.+','').matches('\\b${data.appointment-practitioner-id}$') and display.exists()).exists())" with error message 'There are search results, but they do not fully match the search criteria.'
