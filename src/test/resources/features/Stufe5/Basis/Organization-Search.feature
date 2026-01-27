# language: en
@Stufe5
@Basis
@Optional
@Organization-Search
Feature: Testing search parameters against a resource of type Organization (@Organization-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Organization-Read test case must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "Organization"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Organization"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | identifier       | token           |
      | active           | token           |
      | type             | token           |
      | name             | string          |
      | address          | string          |
      | partof           | reference       |
      | endpoint         | reference       |
    
    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |

  Scenario: Search for the Organization by ID
    When Get FHIR resource at "http://fhirserver/Organization/?_id=${data.organization-read-id}" with content type "xml"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And response bundle contains resource with ID "${data.organization-read-id}" with error message "The requested Organization ${data.organization-read-id} is not contained in the response bundle"

  @Optional
  Scenario: Search for the Organization by Tag
    When Get FHIR resource at "http://fhirserver/Organization/?_tag=${data.tag-system}%7C${data.tag-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Organization by Count
    When Get FHIR resource at "http://fhirserver/Organization/?_count" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'total > 0 and entry.resource.count() > 0' with error message 'No search results were found'

  Scenario: Search for the Organization by Identifier
    When Get FHIR resource at "http://fhirserver/Organization/?identifier=${data.organization-read-identifier-system}%7C${data.organization-read-identifier-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(identifier.where(system='${data.organization-read-identifier-system}' and value='${data.organization-read-identifier-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Organization by Active Status
    When Get FHIR resource at "http://fhirserver/Organization/?active=true" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(active = true)" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Organization by Type
    When Get FHIR resource at "http://fhirserver/Organization/?type=edu" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(type.coding.where(system = 'http://terminology.hl7.org/CodeSystem/organization-type' and code = 'edu').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Organization by Name
    When Get FHIR resource at "http://fhirserver/Organization/?name=Uniklinik%20Entenhausen" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.contains('Uniklinik Entenhausen'))" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Organization by Address
    When Get FHIR resource at "http://fhirserver/Organization/?address=Entenhausen" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(city.contains('Entenhausen') or line.exists($this.contains('Entenhausen'))).exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Organization that is part of another Organization
    When Get FHIR resource at "http://fhirserver/Organization/?partof=Organization/${data.organization-read-parent-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.where($this.where(partOf.reference = 'Organization/${data.organization-read-parent-id}').as(Organization)).exists()" with error message 'There are search results, but they do not fully match the search criteria'