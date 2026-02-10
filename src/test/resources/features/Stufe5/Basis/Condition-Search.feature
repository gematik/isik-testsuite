# language: en
@Stufe5
@Basis
@Mandatory
@Condition-Search
Feature: Testing search parameters against a resource of type Condition (@Condition-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Condition-Read-Active test case must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "Condition"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Condition"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | patient          | reference       |
      | subject          | reference       |
      | encounter        | reference       |
      | recorded-date    | date            |
      | related          | reference       |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |
      | clinical-status  | token           |
      | category         | token           |

  Scenario: Search for the Condition by ID
    When Get FHIR resource at "http://fhirserver/Condition/?_id=${data.condition-read-active-id}" with content type "xml"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And response bundle contains resource with ID "${data.condition-read-active-id}" with error message "The requested Condition ${data.condition-read-active-id} is not contained in the response bundle"

  @Optional
  Scenario: Search for the Condition by Tag
    When Get FHIR resource at "http://fhirserver/Condition/?_tag=${data.tag-system}%7C${data.tag-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Condition by Count
    When Get FHIR resource at "http://fhirserver/Condition/?_count" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'total > 0 and entry.resource.count() > 0' with error message 'No search results were found'

  Scenario: Search for the Condition by Patient (Search Parameter 'subject')
    When Get FHIR resource at "http://fhirserver/Condition/?subject=Patient/${data.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "${data.patient-read-id}"

  Scenario: Search for the Condition by Patient(Search Parameter 'patient')
    When Get FHIR resource at "http://fhirserver/Condition/?patient=Patient/${data.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "${data.patient-read-id}"

  Scenario: Search for the Condition by Encounter
    When Get FHIR resource at "http://fhirserver/Condition/?encounter=${data.encounter-read-in-progress-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "encounter" in all bundle resources references resource with ID "${data.encounter-read-in-progress-id}"

  Scenario: Search for the Condition by Recorded Date with 'ge' Modifier
    When Get FHIR resource at "http://fhirserver/Condition/?recorded-date=ge2021-02-12" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath 'entry.resource.all(recordedDate >= @2021-02-12T00:00:00+01:00)' with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Condition by Recorded Date with 'le' Modifier
    When Get FHIR resource at "http://fhirserver/Condition/?recorded-date=le2050-01-01" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath 'entry.resource.all(recordedDate <= @2050-01-01T23:59:59+01:00)' with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Search for the Condition by Clinical Status
    When Get FHIR resource at "http://fhirserver/Condition/?clinical-status=http://terminology.hl7.org/CodeSystem/condition-clinical%7Cactive" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(clinicalStatus.coding.code.where($this = 'active').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Search for the Condition by ID and Clinical Status
    When Get FHIR resource at "http://fhirserver/Condition/?_id=${data.condition-read-active-id}&clinical-status=http://terminology.hl7.org/CodeSystem/condition-clinical%7Cinactive" with content type "json"
    And bundle does not contain resource "Condition" with ID "${data.condition-read-active-id}" with error message "The requested CodeSystem ${data.condition-read-active-id}} should not be part of the search result"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.all(clinicalStatus.coding.code.where($this = "active").exists().not())' with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Search for the Condition by Clinical Status with ':not' Modifier
    When Get FHIR resource at "http://fhirserver/Condition/?clinical-status:not=http://terminology.hl7.org/CodeSystem/condition-clinical%7Cinactive" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath 'entry.resource.all(clinicalStatus.coding.code.where($this = "inactive").exists().not())' with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Search for the Condition by Category
    When Get FHIR resource at "http://fhirserver/Condition/?category=encounter-diagnosis" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath 'entry.resource.all(category.coding.where(code = "encounter-diagnosis").exists())' with error message 'There are search results, but they do not fully match the search criteria'
