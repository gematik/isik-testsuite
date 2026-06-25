# language: en
@Stufe5
@Vitalparameter
@Mandatory
@ISiKCapabilityStatementStammdatenRolle
@Patient-Search
Feature: Testing search parameters against a resource of type Patient, according to the definition of ISiKCapabilityStatementStammdatenRolle (@Patient-Search @Vitalparameter)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - A valid Patient resource conform to the Profile ISiKPatient and with ID defined in the property 'observation-patient-id'
      - Some ISiKPatient Test Instances have been created in the System Under Test for performing different Search Requests
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "xml"
    And CapabilityStatement contains interaction "search-type" for resource "Patient"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Patient"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | identifier       | token           |
      | given            | string          |
      | family           | string          |
      | birthdate        | date            |
      | gender           | token           |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _has             | string          |
      | _tag             | token           |

  Scenario: Search for Patient by ID
    When Get FHIR resource at "http://fhirserver/Patient/?_id=${data.observation-patient-id}" with content type "xml"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And response bundle contains resource with ID "${data.observation-patient-id}" with error message "The requested Patient ${data.observation-patient-id} is not contained in the response bundle"

  Scenario: Search for Patient by identifier
    When Get FHIR resource at "http://fhirserver/Patient/?identifier=http://fhir.de/sid/gkv/kvid-10%7CX485231029" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(identifier.where($this.system = 'http://fhir.de/sid/gkv/kvid-10' and $this.value = 'X485231029').exists())" with error message 'The requested Patient ${data.observation-patient-id} is not contained in the response bundle'

  Scenario: Search for Patients that have a Family Name containing "Mustermann" and Birthdate >= 1955-06-20, group by _count
    When Post FHIR search request to "http://fhirserver/Patient/_search" with content type "json" and parameters:
      | family:contains | birthdate    | _count               |
      | Mustermann      | ge1955-06-20 | ${data.search-count} |
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${data.search-count}' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.family.where($this.contains('Mustermann')).exists())" with error message 'There are search results, but they do not fully match the search criteria'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(birthDate >= @1955-06-20)" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patients that have a Family Name containing "Mustermann" and Gender male, group by _count
    When Post FHIR search request to "http://fhirserver/Patient/_search" with content type "json" and parameters:
      | family:contains | gender | _count               |
      | Mustermann      | male   | ${data.search-count} |
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${data.search-count}' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.family.where($this.contains('Mustermann')).exists())" with error message 'There are search results, but they do not fully match the search criteria'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(gender = 'male')" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Negative test: Search for Patients using ID and Family
    When Post FHIR search request to "http://fhirserver/Patient/_search" with content type "xml" and parameters:
      | _id                | family:contains |
      | NotExistingPatient | Mustermann      |
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(Patient).count() = 0' with error message 'Search results were found when none were expected'
    And bundle does not contain resource "Patient" with ID "NotExistingPatient" with error message "The requested Patient NotExistingPatient is unexpectedly contained in the response bundle"

  Scenario: Search for Patients by Date of birth
    When Post FHIR search request to "http://fhirserver/Patient/_search" with content type "xml" and parameters:
      | birthdate    |
      | ge1955-06-20 |
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(birthDate >= @1955-06-20)" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Patient with an empty search parameter to be ignored
    When Get FHIR resource at "http://fhirserver/Patient/?_id=${data.observation-patient-id}&family=" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    # id might be missing, if the SearchSet includes an OperationOutcome, cf. https://www.hl7.org/fhir/R4/http.html#search
    And FHIR current response body evaluates the FHIRPath "entry.resource.where(id.exists() and id.replaceMatches('/_history/.+','').matches('\\b${data.observation-patient-id}$')).count() = 1" with error message 'The requested Patient ${data.observation-patient-id} is not contained in the response bundle'
