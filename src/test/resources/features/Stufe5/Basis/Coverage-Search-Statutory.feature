# language: en
@Stufe5
@Basis
@Mandatory
@Coverage-Search-Statutory
Feature: Testing search parameters against a resource of type "statutory" Coverage (@Coverage-Search-Statutory)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Coverage-Read-Statutory test case must have been executed successfully beforehand.
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
    When Get FHIR resource at "http://fhirserver/Coverage/?_id=${data.coverage-read-statutory-id}" with content type "xml"
    And response bundle contains resource with ID "${data.coverage-read-statutory-id}" with error message "The requested Coverage ${data.coverage-read-statutory-id} is not contained in the response bundle"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"

  Scenario: Search for the Coverage by insured person's number
    When Get FHIR resource at "http://fhirserver/Coverage/?patient.identifier=http://fhir.de/sid/gkv/kvid-10%7CX485231029" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And response bundle contains resource with ID "${data.coverage-read-statutory-id}" with error message "The requested Coverage ${data.coverage-read-statutory-id} is not contained in the response bundle"

  Scenario: Search for the Coverage by Status
    When Get FHIR resource at "http://fhirserver/Coverage/?status=active" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(status='active')" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Coverage by Type
    When Get FHIR resource at "http://fhirserver/Coverage/?type=GKV" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(type.coding.code='GKV')" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Coverage by Beneficiary
    When Get FHIR resource at "http://fhirserver/Coverage/?beneficiary=${data.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "beneficiary" in all bundle resources references resource with ID "${data.patient-read-id}"

  Scenario: Search for the Coverage by Type (Negative Test)
    When Get FHIR resource at "http://fhirserver/Coverage/?type=SEL" with content type "json"
    And bundle does not contain resource "Coverage" with ID "${data.coverage-read-statutory-id}" with error message "There are search results, but they do not fully match the search criteria"
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Coverage).all(type.coding.code='SEL')" with error message 'There are search results, but they do not fully match the search criteria'
