# language: en
@Stufe5
@Basis
@Mandatory
@Procedure-Search
Feature: Testing search parameters against a resource of type Procedure (@Procedure-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Procedure-Read test case must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "xml"
    And CapabilityStatement contains interaction "search-type" for resource "Procedure"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Procedure"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | status           | token           |
      | category         | token           |
      | code             | token           |
      | patient          | reference       |
      | encounter        | reference       |
      | date             | date            |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |
      | subject          | reference       |

  Scenario: Search for Procedure resource by ID
    When Get FHIR resource at "http://fhirserver/Procedure/?_id=${data.procedure-read-id}" with content type "xml"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And response bundle contains resource with ID "${data.procedure-read-id}" with error message "The requested Procedure ${data.procedure-read-id} is not contained in the response bundle"

  @Optional
  Scenario: Search for Procedure resource by Tag
    When Get FHIR resource at "http://fhirserver/Procedure/?_tag=${data.tag-system}%7C${data.tag-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Procedure resource by Count
    When Get FHIR resource at "http://fhirserver/Procedure/?_count" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'total > 0 and entry.resource.count() > 0' with error message 'No search results were found'

  Scenario: Search for Procedures by Status
    When Get FHIR resource at "http://fhirserver/Procedure/?status=completed" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all((status = 'completed').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Procedures by Category
    When Get FHIR resource at "http://fhirserver/Procedure/?category=http://snomed.info/sct%7C387713003" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all((category.where(coding.code = '387713003' and coding.system = 'http://snomed.info/sct' and coding.version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}')).exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Procedures by Code (OPS)
    When Get FHIR resource at "http://fhirserver/Procedure/?code=http://fhir.de/CodeSystem/bfarm/ops%7C5-470.11" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all((code.coding.where(code = '5-470.11' and system = 'http://fhir.de/CodeSystem/bfarm/ops')).exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Procedures by Performed Date
    When Get FHIR resource at "http://fhirserver/Procedure/?date=le2050-01-01" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(performedDateTime.exists().not() or performedDateTime <= @2050-01-01T23:59:59+01:00)" with error message 'There are search results, but they do not fully match the search criteria'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(performedPeriod.start.exists().not() or performedPeriod.start <= @2050-01-01T23:59:59+01:00)" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Procedures by Patient reference
    When Get FHIR resource at "http://fhirserver/Procedure/?patient=Patient/${data.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "${data.patient-read-id}"

  Scenario Outline: Search for Procedures by references
    When Get FHIR resource at "http://fhirserver/Procedure/?<path>=<query><data>" with content type "<contentType>"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath 'entry.resource.all(<entrytype>.reference.replaceMatches("/_history/.+","").matches("\\b<data>$"))' with error message 'There are search results, but they do not fully match the search criteria'

    Examples:
      | contentType | entrytype | path      | query      | data                                  |
      | xml         | encounter | encounter | Encounter/ | ${data.encounter-read-in-progress-id} |
      | json        | subject   | patient   | Patient/   | ${data.patient-read-id}               |

  Scenario: Negative search for Procedure by ID and status
    When Get FHIR resource at "http://fhirserver/Procedure/?_id:not=${data.procedure-read-id}&status:not=completed" with content type "xml"
    And bundle does not contain resource "Procedure" with ID "${data.procedure-read-id}" with error message "There are search results, but they do not fully match the search criteria"
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(Procedure).all(status.exists() and (status = 'completed').not())" with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Search for Procedures by Subject reference
    When Get FHIR resource at "http://fhirserver/Procedure/?subject=Patient/${data.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "${data.patient-read-id}"