# language: en
@Stufe5
@Basis
@Mandatory
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
    When Get FHIR resource at "http://fhirserver/Practitioner/?_id=${data.practitioner-read-id}" with content type "xml"
    And response bundle contains resource with ID "${data.practitioner-read-id}" with error message "The requested Practitioner resource ${data.practitioner-read-id} is not contained in the response bundle"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"

  @Optional
  Scenario: Search for Practitioner resource by Tag
    When Get FHIR resource at "http://fhirserver/Practitioner/?_tag=${data.tag-system}%7C${data.tag-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Practitioner resource by Count
    When Get FHIR resource at "http://fhirserver/Practitioner/?_count" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'total > 0 and entry.resource.count() > 0' with error message 'No search results were found'

  Scenario: Search for Practitioner resource by Identifier LANR
    When Get FHIR resource at "http://fhirserver/Practitioner/?identifier=https://fhir.kbv.de/NamingSystem/KBV_NS_Base_ANR%7C123456789" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And response bundle contains resource with ID "${data.practitioner-read-id}" with error message "The requested Practitioner resource ${data.practitioner-read-id} is not contained in the response bundle"
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(identifier.where(system='https://fhir.kbv.de/NamingSystem/KBV_NS_Base_ANR' and value='123456789').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Practitioner resource by Identifier Telematik-ID
    When Get FHIR resource at "http://fhirserver/Practitioner/?identifier=https%3A%2F%2Fgematik.de%2Ffhir%2Fsid%2Ftelematik-id%7C123456789" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And response bundle contains resource with ID "${data.practitioner-read-id}" with error message "The requested Practitioner resource ${data.practitioner-read-id} is not contained in the response bundle"
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(identifier.where(system='https://gematik.de/fhir/sid/telematik-id' and value='123456789').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Practitioner resource by First Name (given)
    When Get FHIR resource at "http://fhirserver/Practitioner/?given=Walter" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.given.where($this.startsWith('Walter')).exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Practitioner resource by Last Name (family)
    When Get FHIR resource at "http://fhirserver/Practitioner/?family=Musterarzt" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.family.where($this.startsWith('Musterarzt')).exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Practitioner resource by First Name (negative test)
    When Get FHIR resource at "http://fhirserver/Practitioner/?given=Max" with content type "xml"
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Practitioner).where(id.replaceMatches('/_history/.+','').matches('\\b${data.practitioner-read-id}$')).count()=0" with error message 'The resource ${data.practitioner-id} must not be returned here'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Practitioner).all(name.given.where($this.startsWith('Max')).exists())" with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Search for Practitioner resource by Name
    When Get FHIR resource at "http://fhirserver/Practitioner/?name=Musterarzt" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And response bundle contains resource with ID "${data.practitioner-read-id}" with error message "The requested healthcare professional ${data.practitioner-read-id} is not contained in the response bundle"
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.family contains 'Musterarzt')" with error message 'There are search results, but they do not fully match the search criteria'
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "Practitioner" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKPersonImGesundheitsberuf"

  @Optional
  Scenario: Search for Practitioner resource by Address
    When Get FHIR resource at "http://fhirserver/Practitioner/?address:contains=Musterweg" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(line.contains('Musterweg')).count()=1)" with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Search for Practitioner resource by Gender
    When Get FHIR resource at "http://fhirserver/Practitioner/?gender=male" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(gender = 'male')" with error message 'There are search results, but they do not fully match the search criteria'

