# language: en
@Stufe5
@Basis
@Optional
@Location-Search
Feature: Testing search parameters against a resource of type Location (@Location-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Location-Read, Location-Bed-Placement and Location-Room-Read test cases must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "Location"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Location"

    Examples:
      | searchParamValue   | searchParamType |
      | _id                | token           |
      | _count             | number          |
      | identifier         | token           |
      | address            | string          |
      | operational-status | token           |
      | organization       | reference       |
      | type               | token           |
      | partof             | reference       |
      | near               | special         |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |

  Scenario: Search for the Location by ID
    When Get FHIR resource at "http://fhirserver/Location/?_id=${data.Location-read-id}" with content type "xml"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And response bundle contains resource with ID "${data.Location-read-id}" with error message "The requested Location ${data.Location-read-active-id} is not contained in the response bundle"

  @Optional
  Scenario: Search for the Location by Tag
    When Get FHIR resource at "http://fhirserver/Location/?_tag=${data.tag-system}%7C${data.tag-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Location by Count
    When Get FHIR resource at "http://fhirserver/Location/?_count" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'total > 0 and entry.resource.count() > 0' with error message 'No search results were found'

  Scenario: Search for the Location by Identifier
    When Get FHIR resource at "http://fhirserver/Location/?identifier=${data.location-read-identifier-system}%7C${data.location-read-identifier-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(identifier.where(system='${data.location-read-identifier-system}' and value='${data.location-read-identifier-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Location by Address
    When Get FHIR resource at "http://fhirserver/Location/?address=Musterstadt" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(city.contains('Musterstadt') or line.exists($this.contains('Musterstadt'))).exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Location by Operational Status (Occupied)
    When Get FHIR resource at "http://fhirserver/Location/?operational-status=O" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(operationalStatus.where(code = 'O' and system = 'http://terminology.hl7.org/CodeSystem/v2-0116').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Location by Organization
    When Get FHIR resource at "http://fhirserver/Location/?organization=Organization/${data.organization-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.where($this.where(managingOrganization.reference = 'Organization/${data.organization-read-id}').as(Location)).exists()" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Location by Type 'LOCHFID'
    When Get FHIR resource at "http://fhirserver/Location/?type=LOCHFID" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(type.coding.where(system = 'http://terminology.hl7.org/CodeSystem/v3-RoleCode' and code = 'LOCHFID').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Location that part of another Location
    When Get FHIR resource at "http://fhirserver/Location/?partof=Location/${data.location-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.where($this.where(partOf.reference = 'Location/${data.location-read-id}').as(Location)).exists()" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Location by Near (in format latitude|longitude)
    When Get FHIR resource at "http://fhirserver/Location/?near=52.52%7C13.405" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() >= 0' with error message 'Failed to perform near search'