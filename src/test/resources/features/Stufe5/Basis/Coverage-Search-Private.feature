# language: en
@Stufe5
@Basis
@Mandatory
@Coverage-Search-Private
Feature: Testing search parameters against a resource of type "private" Coverage (@Coverage-Search-Private)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Coverage-Read-Private test case must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "Coverage"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Coverage"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | status           | token           |
      | type             | token           |
      | beneficiary      | reference       |
      | payor            | reference       |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |
      | subscriber       | reference       |

  Scenario: Search for the Coverage by ID
    When Get FHIR resource at "http://fhirserver/Coverage/?_id=${data.coverage-read-private-id}" with content type "xml"
    And response bundle contains resource with ID "${data.coverage-read-private-id}" with error message "The requested Coverage ${data.coverage-read-private-id} is not contained in the response bundle"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"

  Scenario Outline: Search for the Coverage by Beneficiary and Payor
    When Get FHIR resource at "http://fhirserver/Coverage/?<searchParameter>=Patient/<searchValue>" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath 'entry.resource.all(<searchParameter>.reference.replaceMatches("/_history/.+","").matches("\\b${data.patient-read-id}$"))' with error message 'There are search results, but they do not fully match the search criteria'

    Examples:
      | searchParameter | searchValue             |
      | beneficiary     | ${data.patient-read-id} |
      | payor           | ${data.patient-read-id} |

  Scenario: Search for the Coverage Coverage by Beneficiary (Chaining)
    When Get FHIR resource at "http://fhirserver/Coverage/?beneficiary.identifier=${data.patient-read-identifier-system}%7C${data.patient-read-identifier-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "beneficiary" in all bundle resources references resource with ID "${data.patient-read-id}"

  Scenario: Search for the Coverage by Status
    When Get FHIR resource at "http://fhirserver/Coverage/?status=active" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(status = 'active')" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Coverage by Type of Insurance
    When Get FHIR resource at "http://fhirserver/Coverage/?type=http://fhir.de/CodeSystem/versicherungsart-de-basis%7CSEL" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(type.coding.where(system = 'http://fhir.de/CodeSystem/versicherungsart-de-basis').code = 'SEL')" with error message 'There are search results, but they do not fully match the search criteria'
