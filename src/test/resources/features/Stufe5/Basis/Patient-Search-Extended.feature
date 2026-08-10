# language: en
@Stufe5
@Basis
@Mandatory
@ISiKCapabilityStatementErweiterteStammdatenRolle
@Patient-Search-Extended
Feature: Testing search parameters against a resource of type Patient, according to the definition of ISiKCapabilityStatementErweiterteStammdatenRolle (@Patient-Search-Extended)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Patient-Read, Patient-Read-Extended and Patient-Search test cases must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "xml"
    And CapabilityStatement contains interaction "search-type" for resource "Patient"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Patient"

    Examples:
      | searchParamValue   | searchParamType |
      | name               | string          |
      | address            | string          |
      | address-city       | string          |
      | address-country    | string          |
      | address-postalcode | string          |
      | active             | token           |
      | telecom            | token           |

  Scenario: Search for Patients by Name, group by _count
    When Get FHIR resource at "http://fhirserver/Patient/?name=Graf&_count=${basis.search-count}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() <= ${basis.search-count}' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.where(family.toString().matches('Graf|Gräfin') or given.where(value.toString().matches('Graf|Gräfin'))).exists())" with error message 'There are search results, but they do not fully match the search criteria'
    And FHIR current response body evaluates the FHIRPath "entry.resource.where(name.prefix.toString().matches('Dr.|Prof.')).exists()" with error message 'There are search results, but they do not fully match the search criteria'
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "Patient" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKPatient"

  Scenario: Search for Patients by Address, group by _count
    When Get FHIR resource at "http://fhirserver/Patient/?address=Berlin&_count=${basis.search-count}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() <= ${basis.search-count}' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(city = 'Berlin').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patients by Address (city), group by _count
    When Get FHIR resource at "http://fhirserver/Patient/?address-city=Berlin&_count=${basis.search-count}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() <= ${basis.search-count}' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(city = 'Berlin').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patients by Address (country), group by _count
    When Get FHIR resource at "http://fhirserver/Patient/?address-country=DE&_count=${basis.search-count}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() <= ${basis.search-count}' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(country = 'DE').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patients by Address (postal code), group by _count
    When Get FHIR resource at "http://fhirserver/Patient/?address-postalcode=10117&_count=${basis.search-count}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() <= ${basis.search-count}' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(postalCode.contains('10117')).exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patients by Status, group by _count
    When Get FHIR resource at "http://fhirserver/Patient/?active=true&_count=${basis.search-count}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() <= ${basis.search-count}' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(active=true)" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patients by Phone Number, group by _count
    When Get FHIR resource at "http://fhirserver/Patient/?telecom=030+1234567&_count=${basis.search-count}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all((telecom = '030 1234567').exists())" with error message 'There are search results, but they do not fully match the search criteria'
