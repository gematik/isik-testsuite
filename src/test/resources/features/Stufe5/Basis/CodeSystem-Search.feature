# language: en
@Stufe5
@Basis
@Optional
@CodeSystem-Search
Feature: Testing search parameters against a resource of type CodeSystem (@CodeSystem-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The CodeSystem-Read test case must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "Account"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "CodeSystem"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | url              | uri             |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |

  Scenario: Search for the CodeSystem by ID
    When Get FHIR resource at "http://fhirserver/CodeSystem/?_id=${data.codesystem-read-id}" with content type "xml"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And response bundle contains resource with ID "${data.codesystem-read-id}" with error message "The requested CodeSystem ${data.codesystem-read-id} is not contained in the response bundle."

  @Optional
  Scenario: Search for the CodeSystem by Tag
    When Get FHIR resource at "http://fhirserver/CodeSystem/?_tag=${data.tag-system}%7C${data.tag-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the CodeSystem by Count
    When Get FHIR resource at "http://fhirserver/CodeSystem/?_count" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'total > 0 and entry.resource.count() > 0' with error message 'No search results were found'

  Scenario: Search for the CodeSystem by URL
    When Get FHIR resource at "http://fhirserver/CodeSystem/?url=http%3A%2F%2Fexample.org%2Ffhir%2FCodeSystem%2FTestKatalog" with content type "xml"
    And FHIR current response body evaluates the FHIRPath "entry.resource.count() > 0" with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.where(url = 'http://example.org/fhir/CodeSystem/TestKatalog').exists()" with error message 'There are search results, but they do not fully match the search criteria..'