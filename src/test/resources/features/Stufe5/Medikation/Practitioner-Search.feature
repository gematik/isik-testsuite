# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementLeistungserbringerRolle
@Practitioner-Search
Feature: Testing search parameters against a resource of type Practitioner (@Practitioner-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Practitioner-Read test case must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "xml"
    And CapabilityStatement contains interaction "search-type" for resource "Practitioner"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Practitioner"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | identifier       | token           |
      | given            | string          |
      | family           | string          |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |
      | name             | string          |
      | address          | string          |
      | gender           | token           |

  Scenario: Search for Practitioner resource by ID
    When Get FHIR resource at "http://fhirserver/Practitioner/?_id=${data.medication-practitioner-id}" with content type "xml"
    And response bundle contains resource with ID "${data.medication-practitioner-id}" with error message "The requested Practitioner resource ${data.medication-practitioner-id} is not contained in the response bundle"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "Practitioner" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKPersonImGesundheitsberuf"

  Scenario: Search for Practitioner resource by Identifier LANR
    When Get FHIR resource at "http://fhirserver/Practitioner/?identifier=https://fhir.kbv.de/NamingSystem/KBV_NS_Base_ANR%7C123456789" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(identifier.where(system='https://fhir.kbv.de/NamingSystem/KBV_NS_Base_ANR' and value='123456789').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Practitioner resource by Identifier Telematik-ID
    When Get FHIR resource at "http://fhirserver/Practitioner/?identifier=https%3A%2F%2Fgematik.de%2Ffhir%2Fsid%2Ftelematik-id%7C123456789" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(identifier.where(system='https://gematik.de/fhir/sid/telematik-id' and value='123456789').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Practitioners that have the given Name "Walter", group by _count
    When Post FHIR search request to "http://fhirserver/Practitioner/_search" with content type "xml" and parameters:
      | given  | _count               |
      | Walter | ${data.search-count} |
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${data.search-count}' with error message 'Invalid search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.given.where($this.startsWith('Walter')).exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Practitioners that have the family Name "Musterarzt", group by _count
    When Post FHIR search request to "http://fhirserver/Practitioner/_search" with content type "xml" and parameters:
      | family     | _count               |
      | Musterarzt | ${data.search-count} |
    When Get FHIR resource at "http://fhirserver/Practitioner/?family=Musterarzt&_id=${data.medication-practitioner-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${data.search-count}' with error message 'Invalid search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.family.where($this.startsWith('Musterarzt')).exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: (Negative Test) Search for Practitioners that have the given Name "NotExistingName", group by _count
    When Post FHIR search request to "http://fhirserver/Practitioner/_search" with content type "xml" and parameters:
      | given           | _count               |
      | NotExistingName | ${data.search-count} |
    When Get FHIR resource at "http://fhirserver/Practitioner/?given=Max&_id=${data.medication-practitioner-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() = 0' with error message 'Invalid search results were found'

  @Optional
  Scenario: Optional Search for Practitioners that have the given Tag, group by _count
    When Post FHIR search request to "http://fhirserver/Practitioner/_search" with content type "xml" and parameters:
      | _tag                                  | _count               |
      | ${data.tag-system}\|${data.tag-value} | ${data.search-count} |
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${data.search-count}' with error message 'Invalid search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Optional Search for Practitioners that have the Name "Musterarzt", group by _count
    When Post FHIR search request to "http://fhirserver/Practitioner/_search" with content type "xml" and parameters:
      | name       | _count               |
      | Musterarzt | ${data.search-count} |
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${data.search-count}' with error message 'Invalid search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.family contains 'Musterarzt')" with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Optional Search for Practitioners that have the Address that contains "Musterweg", group by _count
    When Post FHIR search request to "http://fhirserver/Practitioner/_search" with content type "xml" and parameters:
      | address:contains | _count               |
      | Musterweg        | ${data.search-count} |
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${data.search-count}' with error message 'Invalid search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(line.contains('Musterweg')).count()=1)" with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Optional Search for Practitioners that have the Gender "male", group by _count
    When Post FHIR search request to "http://fhirserver/Practitioner/_search" with content type "xml" and parameters:
      | gender | _count               |
      | male   | ${data.search-count} |
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${data.search-count}' with error message 'Invalid search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(gender = 'male')" with error message 'There are search results, but they do not fully match the search criteria'
