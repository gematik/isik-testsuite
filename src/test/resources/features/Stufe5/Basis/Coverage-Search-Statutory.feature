# language: en
@Stufe5
@Basis
@Mandatory
@ISiKCapabilityStatementVersicherungsverhaeltnisRolle
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
    When Get FHIR resource at "http://fhirserver/Coverage/?_id=${basis.coverage-read-statutory-id}" with content type "xml"
    And response bundle contains resource with ID "${basis.coverage-read-statutory-id}" with error message "The requested Coverage ${basis.coverage-read-statutory-id} is not contained in the response bundle"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"

  @Optional
  Scenario: Optional Search for the Coverage by Tag and ID
    When Get FHIR resource at "http://fhirserver/Coverage/?_tag=${basis.tag-system}%7C${basis.tag-value}&_id=${basis.coverage-read-statutory-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${basis.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${basis.coverage-read-statutory-id}" with error message "The requested Coverage ${basis.coverage-read-statutory-id} is not contained in the response bundle."

  Scenario: Search for the Coverage by insured person's number
    When Get FHIR resource at "http://fhirserver/Coverage/?patient.identifier=http://fhir.de/sid/gkv/kvid-10%7CX485231029" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And response bundle contains resource with ID "${basis.coverage-read-statutory-id}" with error message "The requested Coverage ${basis.coverage-read-statutory-id} is not contained in the response bundle"

  Scenario: Search for the Coverage by Status and Beneficiary
    When Get FHIR resource at "http://fhirserver/Coverage/?status=active&beneficiary=Patient/${basis.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(status='active')" with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${basis.coverage-read-statutory-id}" with error message "The requested Coverage ${basis.coverage-read-statutory-id} is not contained in the response bundle."

  Scenario: Search for the Coverage by Type and Beneficiary
    When Get FHIR resource at "http://fhirserver/Coverage/?type=GKV&beneficiary=Patient/${basis.patient-read-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(type.coding.code='GKV')" with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${basis.coverage-read-statutory-id}" with error message "The requested Coverage ${basis.coverage-read-statutory-id} is not contained in the response bundle."

  Scenario: Search for the Coverage by Type (Negative Test) and Beneficiary
    When Get FHIR resource at "http://fhirserver/Coverage/?type=SEL&beneficiary=Patient/${basis.patient-read-id}" with content type "json"
    And bundle does not contain resource "Coverage" with ID "${basis.coverage-read-statutory-id}" with error message "There are search results, but they do not fully match the search criteria"
