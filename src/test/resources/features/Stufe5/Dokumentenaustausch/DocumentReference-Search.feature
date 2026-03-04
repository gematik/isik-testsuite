# language: en
@Stufe5
@Dokumentenaustausch
@Mandatory
@DocumentReference-Search
Feature: Testing search parameters against a resource of type DocumentReference (@DocumentReference-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The DocumentReference-Read test case must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "DocumentReference"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "DocumentReference"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | patient          | reference       |
      | status           | token           |
      | identifier       | token           |
      | type             | token           |
      | category         | token           |
      | creation         | date            |
      | encounter        | reference       |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |

  Scenario: Search for the DocumentReference metadata by ID
    When Get FHIR resource at "http://fhirserver/DocumentReference/?_id=${data.documentreference-read-id}" with content type "xml"
    And response bundle contains resource with ID "${data.documentreference-read-id}" with error message "The requested DocumentReference ${data.documentreference-read-id} is not contained in the response bundle"

  Scenario: Search for the DocumentReference by Count
    When Get FHIR resource at "http://fhirserver/DocumentReference/?_count" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'total > 0 and entry.resource.count() > 0' with error message 'No search results were found'

  Scenario: Search for DocumentReference that belong to a Patient
    When Get FHIR resource at "http://fhirserver/DocumentReference/?patient=Patient/${data.documentreference-read-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "${data.documentreference-read-patient-id}"

  @Optional
  Scenario: Search for the DocumentReference that belong to a Patient, by Document Tag
    When Get FHIR resource at "http://fhirserver/DocumentReference/?_tag=${data.tag-system}%7C${data.tag-value}&patient=Patient/${data.documentreference-read-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the DocumentReference that belong to a Patient, by Document Status
    When Get FHIR resource at "http://fhirserver/DocumentReference/?status=current&patient=Patient/${data.documentreference-read-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(status = 'current')" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the DocumentReference that belong to a Patient, by Document Identifier
    When Get FHIR resource at "http://fhirserver/DocumentReference/?identifier=${data.documentreference-search-identifier-value}&patient=Patient/${data.documentreference-read-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(identifier.where(value = '${data.documentreference-search-identifier-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for DocumentReference that belong to a Patient, knowing their identifier
    Then Get FHIR resource at "http://fhirserver/DocumentReference/?patient.identifier=${data.documentreference-search-patient-identifier-system}%7C${data.documentreference-search-patient-identifier-value}&patient=Patient/${data.documentreference-read-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found.'

  Scenario: Search for the DocumentReference that belong to a Patient, by Type
    When Get FHIR resource at "http://fhirserver/DocumentReference/?type=${data.documentreference-search-type-code}&patient=Patient/${data.documentreference-read-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(type.coding.where(code = '${data.documentreference-search-type-code}').exists())" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the DocumentReference that belong to a Patient, by Category
    When Get FHIR resource at "http://fhirserver/DocumentReference/?category=${data.documentreference-search-class-code}&patient=Patient/${data.documentreference-read-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(category.coding.where(code = '${data.documentreference-search-class-code}').exists())" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the DocumentReference that belong to a Patient, by Encounter
    When Get FHIR resource at "http://fhirserver/DocumentReference/?encounter=Encounter/${data.documentreference-read-encounter-id}&patient=Patient/${data.documentreference-read-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(context.encounter.where(reference.replaceMatches('/_history/.+','').matches('\\b${data.documentreference-read-encounter-id}$')).exists())" with error message 'The requested DocumentReference ${data.documentreference-read-id} is not contained in the response bundle'

  Scenario: Search for the DocumentReference that belong to a Patient, by Creation Date
    When Get FHIR resource at "http://fhirserver/DocumentReference/?creation=2026-01-31&patient=Patient/${data.documentreference-read-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(content.attachment.where(creation.toString().contains('2026-01-31')).exists())" with error message 'There are search results, but they do not fully match the search criteria.'
