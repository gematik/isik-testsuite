# language: en
@Stufe5
@Basis
@Mandatory
@ValueSet-Search
Feature: Testing search parameters against a resource of type ValueSet (@ValueSet-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The ValueSet-Read test case must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "xml"
    And CapabilityStatement contains interaction "search-type" for resource "ValueSet"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "ValueSet"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | url              | uri             |
      | version          | token           |
      | name             | string          |
      | status           | token           |

    @Optional
    Examples:
      | searchParamValue   | searchParamType |
      | _tag               | token           |
      | context-type-value | composite       |

  Scenario: Search for ValueSet by ID
    When Get FHIR resource at "http://fhirserver/ValueSet/?_id=${data.valueset-read-id}" with content type "xml"
    Then TGR find the last request
    And TGR current response with attribute "$.header.[~'content-type']" matches "application/fhir\+xml;charset=(?i)UTF-8"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And response bundle contains resource with ID "${data.valueset-read-id}" with error message "The requested ValueSet ${data.valueset-read-id} is not contained in the response bundle"

  @Optional
  Scenario: Search for ValueSet resource by Tag
    When Get FHIR resource at "http://fhirserver/ValueSet/?_tag=${data.tag-system}%7C${data.tag-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for ValueSet resource by Count
    When Get FHIR resource at "http://fhirserver/ValueSet/?_count" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'total > 0 and entry.resource.count() > 0' with error message 'No search results were found'

  Scenario Outline: Search for ValueSet by additional search parameters
    When Get FHIR resource at "http://fhirserver/ValueSet/?<searchParameter>=<searchValue>" with content type "<contentType>"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(<searchParameter> = '<searchValue>')" with error message 'There are search results, but they do not fully match the search criteria'

    Examples:
      | contentType | searchParameter | searchValue                                   |
      | xml         | url             | http://example.org/fhir/ValueSet/TestValueSet |
      | json        | name            | TestValueSet                                  |
      | json        | status          | active                                        |
      | json        | version         | 1.0.0                                         |

  @Optional
  Scenario: Search for ValueSet by context type
    When Get FHIR resource at "http://fhirserver/ValueSet/?context-type-value=focus%24http%3A%2F%2Fhl7.org%2Ffhir%2Fresource-types%7CEncounter" with content type "xml"
    Then TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'