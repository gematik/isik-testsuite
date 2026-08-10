# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementKlinischeRolle
@Condition-Search
Feature: Testing search parameters against a resource of type Condition, according to the definition of ISiKCapabilityStatementKlinischeRolle (@Condition-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - Some ISiKDiagnose Test Instances have been created in the System Under Test for performing different Search Requests
      - The id of one of the active ISiKDiagnose Test Instances can be configured with the property `medication-condition-active-id`
      - The id of one of the resolved ISiKDiagnose Test Instances can be configured with the property `medication-condition-resolved-id`
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "Condition"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Condition"

    @Mandatory
    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | patient          | reference       |
      | encounter        | reference       |
      | recorded-date    | date            |
      | related          | reference       |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _has             | string          |
      | _tag             | token           |
      | clinical-status  | token           |
      | subject          | reference       |
      | category         | token           |

  Scenario: Search for the Condition by ID
    When Get FHIR resource at "http://fhirserver/Condition/?_id=${medikation.medication-condition-active-id}" with content type "xml"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And response bundle contains resource with ID "${medikation.medication-condition-active-id}" with error message "The requested Condition ${medikation.medication-condition-active-id} is not contained in the response bundle"
    And Check if current response of resource "Condition" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKDiagnose"

  Scenario: Search for Conditions by Patient (Search Parameter 'patient'), group by _count
    When Get FHIR resource at "http://fhirserver/Condition/?patient=Patient/${medikation.medication-patient-id}&_count=${medikation.search-count}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${medikation.search-count}' with error message 'No valid search results were found'
    And element "subject" in all bundle resources references resource with ID "${medikation.medication-patient-id}"

  Scenario: Search for Conditions by Encounter, group by _count
    When Get FHIR resource at "http://fhirserver/Condition/?encounter=Encounter/${medikation.medication-encounter-id}&_count=${medikation.search-count}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${medikation.search-count}' with error message 'No valid search results were found'
    And element "encounter" in all bundle resources references resource with ID "${medikation.medication-encounter-id}"

  Scenario: Search for Conditions by Recorded Date with 'ge' Modifier and Patient ('patient'), group by _count
    When Get FHIR resource at "http://fhirserver/Condition/?recorded-date=ge2021-02-12&patient=Patient/${medikation.medication-patient-id}&_count=${medikation.search-count}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${medikation.search-count}' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(recordedDate >= @2021-02-12T00:00:00+01:00)" with error message 'There are search results, but they do not match the date criteria'
    And element "subject" in all bundle resources references resource with ID "${medikation.medication-patient-id}"

  @Optional
  Scenario: Optional Search for the Condition by Tag, group by _count
    When Get FHIR resource at "http://fhirserver/Condition/?_tag=${medikation.tag-system}%7C${medikation.tag-value}&_count=${medikation.search-count}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${medikation.search-count}' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${medikation.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Optional Search for Conditions by Patient (Search Parameter 'subject'), group by _count
    When Get FHIR resource at "http://fhirserver/Condition/?subject=Patient/${medikation.medication-patient-id}&_count=${medikation.search-count}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${medikation.search-count}' with error message 'No valid search results were found'
    And element "subject" in all bundle resources references resource with ID "${medikation.medication-patient-id}"

  @Optional
  Scenario: Optional Search for Conditions by Clinical Status 'active', group by _count
    When Get FHIR resource at "http://fhirserver/Condition/?clinical-status=active&_count=${medikation.search-count}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${medikation.search-count}' with error message 'No valid search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(clinicalStatus.coding.where(code='active').exists())" with error message 'There are search results, but they do not match the expected clinical-status'

  @Optional
  Scenario: Optional Search for Conditions by Category 'encounter-diagnosis', group by _count
    When Get FHIR resource at "http://fhirserver/Condition/?category=encounter-diagnosis&_count=${medikation.search-count}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${medikation.search-count}' with error message 'No valid search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(category.coding.where(code='encounter-diagnosis').exists())" with error message 'There are search results, but they do not match the expected category'
