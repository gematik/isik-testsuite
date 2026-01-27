# language: en
@Stufe5
@Basis
@Mandatory
@Patient-Search
Feature: Testing search parameters against a resource of type Patient (@Patient-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Patient-Read & Patient-Read-Extended test cases must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "xml"
    And CapabilityStatement contains interaction "search-type" for resource "Patient"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Patient"

    Examples:
      | searchParamValue   | searchParamType |
      | _id                | token           |
      | _count             | number          |
      | identifier         | token           |
      | given              | string          |
      | family             | string          |
      | birthdate          | date            |
      | gender             | token           |
      | name               | string          |
      | address            | string          |
      | address-city       | string          |
      | address-country    | string          |
      | address-postalcode | string          |
      | active             | token           |
      | telecom            | token           |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |

  Scenario: Search for Patient by ID
    When Get FHIR resource at "http://fhirserver/Patient/?_id=${data.patient-read-id}" with content type "xml"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And response bundle contains resource with ID "${data.patient-read-id}" with error message "The requested Patient ${data.patient-read-id} is not contained in the response bundle"

  @Optional
  Scenario: Search for Patient by Tag
    When Get FHIR resource at "http://fhirserver/Patient/?_tag=${data.tag-system}%7C${data.tag-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patient by Count
    When Get FHIR resource at "http://fhirserver/Patient/?_count" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'total > 0 and entry.resource.count() > 0' with error message 'No search results were found'

  Scenario: Search for Patient by identifier
    When Get FHIR resource at "http://fhirserver/Patient/?identifier=http://fhir.de/sid/gkv/kvid-10%7CX485231029" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(identifier.where($this.system = 'http://fhir.de/sid/gkv/kvid-10' and $this.value = 'X485231029').exists())" with error message 'The requested Patient ${data.patient-read-id} is not contained in the response bundle'

  Scenario: Search for Patient by first name
    When Get FHIR resource at "http://fhirserver/Patient/?given=Max" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.given.where($this.startsWith('Max')).exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patient with parameter family
    When Get FHIR resource at "http://fhirserver/Patient/?family=Graf%20von%20und%20zu%20Mustermann" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.family.where($this.startsWith('Graf von und zu Mustermann')).exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patient by date of birth
    When Get FHIR resource at "http://fhirserver/Patient/?birthdate=1968-05-12" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(birthDate = @1968-05-12)" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patient by ID and date of birth
    When Get FHIR resource at "http://fhirserver/Patient/?_id=${data.patient-read-id}&birthdate=1968-05-12" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(birthDate = @1968-05-12)" with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${data.patient-read-id}" with error message "The requested Patient ${data.patient-read-id} is not contained in the response bundle"

  Scenario: Search for Patient by gender
    When Get FHIR resource at "http://fhirserver/Patient/?gender=male" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(gender = 'male')" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patient by ID and gender
    When Get FHIR resource at "http://fhirserver/Patient/?_id=${data.patient-read-id}&gender=male" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(gender = 'male')" with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${data.patient-read-id}" with error message "The requested Patient ${data.patient-read-id} is not contained in the response bundle"

  Scenario: Search for Patient using family:contains
    When Get FHIR resource at "http://fhirserver/Patient/?_id=${data.patient-read-id}&family:contains=Mustermann" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.family.where($this.contains('Mustermann')).exists())" with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${data.patient-read-id}" with error message "The requested Patient ${data.patient-read-id} is not contained in the response bundle"

  Scenario: Search for Patients by last name with special characters
    When Get FHIR resource at "http://fhirserver/Patient/?family:contains=Gr%C3%A4fin%20M%C3%BC%C3%9Fterm%C3%A1nn" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.where(family = 'Gräfin Müßtermánn').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patients by first name with special characters
    When Get FHIR resource at "http://fhirserver/Patient/?given:contains=An%26na%5C%2CVic%24tor%7Ca" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.where(given.contains('An&na,Vic$tor|a')).exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patient using birthdate=gt
    When Get FHIR resource at "http://fhirserver/Patient/?birthdate=gt1955-07-01" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(birthDate > @1955-07-01)" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patients by Encounter
    When Get FHIR resource at "http://fhirserver/Patient/?_has:Encounter:patient:_id=${data.encounter-read-in-progress-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And response bundle contains resource with ID "${data.patient-read-id}" with error message "The requested Patient ${data.patient-read-id} is not contained in the response bundle"

  Scenario: Negative test: Search for Patients using ID and Family
    When Get FHIR resource at "http://fhirserver/Patient/?_id=${data.patient-read-extended-id}&family:contains=Mustermann" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(Patient).count() = 0' with error message 'Search results were found when none were expected'
    And bundle does not contain resource "Patient" with ID "${data.patient-read-extended-id}" with error message "The requested Patient ${data.patient-read-id} is unexpectedly contained in the response bundle"

  Scenario: Search for Patients by Date of birth
    When Get FHIR resource at "http://fhirserver/Patient/?birthdate=ge1955-06-20" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(birthDate >= @1955-06-20)" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patient with an empty search parameter to be ignored
    When Get FHIR resource at "http://fhirserver/Patient/?_id=${data.patient-read-id}&family=" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    # id might be missing, if searchset includes an OperationOutcome, cf. https://www.hl7.org/fhir/R4/http.html#search
    And FHIR current response body evaluates the FHIRPath "entry.resource.where(id.exists() and id.replaceMatches('/_history/.+','').matches('\\b${data.patient-read-id}$')).count() = 1" with error message 'The requested Patient ${data.patient-read-id} is not contained in the response bundle'

  Scenario: Search for Patients by Name
    When Get FHIR resource at "http://fhirserver/Patient/?name=Graf" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.where(family.toString().matches('Graf|Gräfin') or given.where(value.toString().matches('Graf|Gräfin'))).exists())" with error message 'There are search results, but they do not fully match the search criteria'
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "Patient" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKPatient"

  Scenario: Search for Patients by Address (city)
    When Get FHIR resource at "http://fhirserver/Patient/?address-city=Musterdorf" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(city = 'Musterdorf').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patients by Address (country)
    When Get FHIR resource at "http://fhirserver/Patient/?address-country=DE" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(country = 'DE').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patients by Address (postal code)
    When Get FHIR resource at "http://fhirserver/Patient/?address-postalcode=98765" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(postalCode.contains('98765')).exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patients by Status
    When Get FHIR resource at "http://fhirserver/Patient/?active=true" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(active=true)" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patients by Phone Number
    When Get FHIR resource at "http://fhirserver/Patient/?telecom=201-867-5309" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all((telecom = '201-867-5309').exists())" with error message 'There are search results, but they do not fully match the search criteria'