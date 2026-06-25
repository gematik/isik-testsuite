# language: en
@Stufe5
@Basis
@Mandatory
@ISiKCapabilityStatementGesundheitsstatusRolle
@ISiKCapabilityStatementAMTSRolle
@AllergyIntolerance-Search
Feature: Testing search parameters against a resource of type AllergyIntolerance (@AllergyIntolerance-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The AllergyIntolerance-Read test case must have been executed successfully beforehand.
      - This Search Scenario performs the following conditions exist:
        * At least one Resource with ID as specified in the property 'allergyintolerance-read-id'
        * At least one Resource with clinical-status 'active'
        * At least one Resource with type 'allergy'
        * At least one Resource with patient that references to the ID as specified in the property 'allergyintolerance-read-patient-id'
        * At least one Resource with category 'environment'
        * At least one Resource with onset Date before than 2026-01-01
        * At lease one Resource with (recorder) date after 2026-01-01
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "AllergyIntolerance"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "AllergyIntolerance"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _tag             | token           |
      | _count           | number          |
      | clinical-status  | token           |
      | patient          | reference       |
      | date             | date            |
      | category         | token           |
      | type             | token           |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _has             | string          |

  Scenario: Search for the AllergyIntolerance resource by ID
    When Get FHIR resource at "http://fhirserver/AllergyIntolerance/?_id=${data.allergyintolerance-read-id}" with content type "xml"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And response bundle contains resource with ID "${data.allergyintolerance-read-id}" with error message "The requested AllergyIntolerance ${data.allergyintolerance-read-id} is not contained in the response bundle."

  Scenario: Search for AllergyIntolerance resources that have the Type 'allergy', group by _count
    When Post FHIR search request to "http://fhirserver/AllergyIntolerance/_search" with content type "xml" and parameters:
      | type    | _count               |
      | allergy | ${data.search-count} |
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() >= 0 and entry.resource.count() <= ${data.search-count}' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(type = 'allergy').exists()" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for AllergyIntolerance resources that have the Clinical Status 'active', group by _count
    When Post FHIR search request to "http://fhirserver/AllergyIntolerance/_search" with content type "xml" and parameters:
      | clinical-status | _count               |
      | active          | ${data.search-count} |
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${data.search-count}' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(clinicalStatus.coding.where(system = 'http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical' and code = 'active').exists()).exists()" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the AllergyIntolerance resources by Patient, group by _count
    When Get FHIR resource at "http://fhirserver/AllergyIntolerance/?_count=${data.search-count}&patient=Patient/${data.allergyintolerance-read-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${data.search-count}' with error message 'No search results were found'
    And element "patient" in all bundle resources references resource with ID "${data.allergyintolerance-read-patient-id}" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the AllergyIntolerance resources that have the Category 'environment', group by _count
    When Get FHIR resource at "http://fhirserver/AllergyIntolerance/?_count=${data.search-count}&category=environment" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${data.search-count}' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(category.where($this = 'environment').exists()).exists()" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the AllergyIntolerance by registered Date (registered) after 2026-01-01, group by _count
    When Get FHIR resource at "http://fhirserver/AllergyIntolerance/?date=ge2026-01-01&_count=${data.search-count}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${data.search-count}' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(recordedDate is dateTime and recordedDate > @2026-01-01).exists()" with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Optional Search for AllergyIntolerance resources that have the given Tag, group by _count
    When Post FHIR search request to "http://fhirserver/AllergyIntolerance/_search" with content type "xml" and parameters:
      | _tag                                  | _count               |
      | ${data.tag-system}\|${data.tag-value} | ${data.search-count} |
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${data.search-count}' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'
