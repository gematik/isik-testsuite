# language: en
@Stufe5
@Basis
@Mandatory
@RelatedPerson-Search
Feature: Testing search parameters against a resource of type RelatedPerson (@RelatedPerson-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The RelatedPerson-Read test case must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "xml"
    And CapabilityStatement contains interaction "search-type" for resource "RelatedPerson"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "RelatedPerson"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | patient          | reference       |

    @Optional
    Examples:
      | searchParamValue   | searchParamType |
      | _tag               | token           |
      | name               | string          |
      | address            | string          |
      | address-city       | string          |
      | address-country    | string          |
      | address-postalcode | string          |

  Scenario: Search for RelatedPerson by ID
    When Get FHIR resource at "http://fhirserver/RelatedPerson/?_id=${data.relatedperson-read-id}" with content type "xml"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And response bundle contains resource with ID "${data.relatedperson-read-id}" with error message "The requested RelatedPerson ${data.relatedperson-read-id} is not contained in the response bundle"

  @Optional
  Scenario: Optional Search for RelatedPerson resource by Tag and ID
    When Get FHIR resource at "http://fhirserver/RelatedPerson/?_tag=${data.tag-system}%7C${data.tag-value}&_id=${data.relatedperson-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for RelatedPerson resource by Count
    When Get FHIR resource at "http://fhirserver/RelatedPerson/?_count=1" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= 1' with error message 'The _count parameter was not applied as expected'

  Scenario: Search for RelatedPerson by Patient ID
    When Get FHIR resource at "http://fhirserver/RelatedPerson/?patient=${data.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "patient" in all bundle resources references resource with ID "${data.patient-read-id}"
    And response bundle contains resource with ID "${data.relatedperson-read-id}" with error message "The requested RelatedPerson ${data.relatedperson-read-id} is not contained in the response bundle"

  @Optional
  Scenario: Optional Search for RelatedPerson by first name and Patient
    When Get FHIR resource at "http://fhirserver/RelatedPerson/?name=Maxine&patient=${data.patient-read-id}" with content type "xml"
    And response bundle contains resource with ID "${data.relatedperson-read-id}" with error message "The requested RelatedPerson ${data.relatedperson-read-id} is not contained in the response bundle"
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.given contains 'Maxine')" with error message 'There are search results, but they do not fully match the search criteria'
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "RelatedPerson" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKAngehoeriger"

  @Optional
  Scenario: Optional Search for RelatedPerson by address (city) and Patient
    When Get FHIR resource at "http://fhirserver/RelatedPerson/?address-city=Berlin&patient=${data.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(city = 'Berlin').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Optional Search for RelatedPerson by address (country) and Patient
    When Get FHIR resource at "http://fhirserver/RelatedPerson/?address-country=DE&patient=${data.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(country = 'DE').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Optional Search for RelatedPerson by address (postal code) and Patient
    When Get FHIR resource at "http://fhirserver/RelatedPerson/?address-postalcode=13187&patient=${data.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(postalCode.contains('13187')).exists())" with error message 'There are search results, but they do not fully match the search criteria'
