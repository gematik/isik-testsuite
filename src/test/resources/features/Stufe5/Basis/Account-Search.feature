# language: en
@Stufe5
@Basis
@Mandatory
@Account-Search
Feature: Testing search parameters against a resource of type Account (@Account-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Account-Read test case must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "Account"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Account"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | identifier       | token           |
      | status           | token           |
      | type             | token           |
      | patient          | reference       |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |

  Scenario: Search for the Account by ID
    When Get FHIR resource at "http://fhirserver/Account/?_id=${data.account-read-id}" with content type "xml"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And response bundle contains resource with ID "${data.account-read-id}" with error message "The requested Account ${data.account-read-id} is not contained in the response bundle."

  @Optional
  Scenario: Search for the Account by Tag
    When Get FHIR resource at "http://fhirserver/Account/?_tag=${data.tag-system}%7C${data.tag-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Account by Count
    When Get FHIR resource at "http://fhirserver/Account/?_count" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'total > 0 and entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(identifier.where(value = '${data.account-read-identifier-value}' and system = '${data.account-read-identifier-system}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Account by Identifier
    When Get FHIR resource at "http://fhirserver/Account/?identifier=${data.account-read-identifier-system}%7C${data.account-read-identifier-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(identifier.where(value = '${data.account-read-identifier-value}' and system = '${data.account-read-identifier-system}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Account by Status
    When Get FHIR resource at "http://fhirserver/Account/?status=active" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.where(status = 'active').exists()" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Account by Type
    When Get FHIR resource at "http://fhirserver/Account/?type=IMP" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(type.coding.where(code='IMP').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Account by Patient
    When Get FHIR resource at "http://fhirserver/Account/?patient=Patient/${data.account-read-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "${data.account-read-patient-id}" with error message 'There are search results, but they do not fully match the search criteria'
