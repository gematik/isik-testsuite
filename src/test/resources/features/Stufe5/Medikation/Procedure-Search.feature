# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementKlinischeRolle
@Procedure-Search
Feature: Testing search parameters against a resource of type Procedure, according to the definition of ISiKCapabilityStatementKlinischeRolle (@Procedure-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - Some ISiKProzedur Test Instances have been created in the System Under Test for performing different Search Requests
      - The id of one of the active ISiKProzedur Test Instances can be configured with the property `medication-procedure-id`
      - One Test Resource should have a Category Code 387713003 from the SNOMED-CT Code System
      - One Test Resource should have a Code '5-470.11' from the BfArM OPS Code System
      - One Test Resource should have Status 'completed'
    """

  Scenario: Read and Validation of the CapabilityStatement for ISiKProzedur
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "Procedure"

  Scenario Outline: Validation of the search parameter definitions for Procedure in ISiKCapabilityStatementKlinischeRolle
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Procedure"

    @Mandatory
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
      | _has             | string          |
      | _tag             | token           |
      | subject          | reference       |

  Scenario: Search for Procedure resource by ID
    When Get FHIR resource at "http://fhirserver/Procedure/?_id=${medikation.medication-procedure-id}" with content type "xml"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And response bundle contains resource with ID "${medikation.medication-procedure-id}" with error message "The requested Procedure ${medikation.medication-procedure-id} is not contained in the response bundle"
    And Check if current response of resource "Procedure" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKProzedur"

  Scenario: Search for Procedures by Status 'completed' and Patient
    When Get FHIR resource at "http://fhirserver/Procedure/?status=completed&patient=Patient/${medikation.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${medikation.search-count}' with error message 'No valid search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all((status = 'completed').exists())" with error message 'There are search results, but they do not fully match the search criteria'
    And element "subject" in all bundle resources references resource with ID "${medikation.medication-patient-id}"
    And response bundle contains resource with ID "${medikation.medication-procedure-id}" with error message "The requested Procedure ${medikation.medication-procedure-id} is not contained in the response bundle"

  Scenario: Search for Procedures by Category Code 387713003 and Patient, group by _count
    When Get FHIR resource at "http://fhirserver/Procedure/?patient=Patient/${medikation.medication-patient-id}&category=http://snomed.info/sct%7C387713003&_count=${medikation.search-count}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${medikation.search-count}' with error message 'No valid search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all((category.where(coding.code = '387713003' and coding.system = 'http://snomed.info/sct' and coding.version = 'http://snomed.info/sct/11000274103/version/${medikation.snomed-ct-version}')).exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Procedures by Code 5-470.11 (OPS) and Patient, group by _count
    When Get FHIR resource at "http://fhirserver/Procedure/?patient=Patient/${medikation.medication-patient-id}&code=http://fhir.de/CodeSystem/bfarm/ops%7C5-470.11&_count=${medikation.search-count}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${medikation.search-count}' with error message 'No valid search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all((code.coding.where(code = '5-470.11' and system = 'http://fhir.de/CodeSystem/bfarm/ops')).exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Procedures by Performed Date and Patient, group by _count
    When Get FHIR resource at "http://fhirserver/Procedure/?date=le2050-01-01&patient=Patient/${medikation.medication-patient-id}&_count=${medikation.search-count}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${medikation.search-count}' with error message 'No valid search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(performedDateTime.exists().not() or performedDateTime <= @2050-01-01T23:59:59+01:00)" with error message 'There are search results, but they do not fully match the search criteria'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(performedPeriod.start.exists().not() or performedPeriod.start <= @2050-01-01T23:59:59+01:00)" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for Procedures by Encounter and Patient, group by _count
    When Get FHIR resource at "http://fhirserver/Procedure/?encounter=Encounter/${medikation.medication-encounter-id}&patient=Patient/${medikation.medication-patient-id}&_count=${medikation.search-count}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${medikation.search-count}' with error message 'No valid search results were found'
    And FHIR current response body evaluates the FHIRPath 'entry.resource.all(encounter.reference.replaceMatches("/_history/.+","").matches("\\b${medikation.medication-encounter-id}$"))' with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Negative search for Procedures by Status and Patient, group by _count
    When Get FHIR resource at "http://fhirserver/Procedure/?_id:not=${medikation.medication-procedure-id}&status:not=completed&patient=Patient/${medikation.medication-patient-id}&_count=${medikation.search-count}" with content type "xml"
    And bundle does not contain resource "Procedure" with ID "${medikation.medication-procedure-id}" with error message "There are search results, but they do not fully match the search criteria"

  @Optional
  Scenario: Optional Search for Procedures resource by Tag, group by count
    When Get FHIR resource at "http://fhirserver/Procedure/?_tag=${medikation.tag-system}%7C${medikation.tag-value}&_id=${medikation.medication-procedure-id}&_count=${medikation.search-count}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${medikation.search-count}' with error message 'No valid search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${medikation.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${medikation.medication-procedure-id}" with error message "The requested Procedure ${medikation.medication-procedure-id} is not contained in the response bundle"

  @Optional
  Scenario: Optional Search for Procedures by Subject reference
    When Get FHIR resource at "http://fhirserver/Procedure/?subject=Patient/${medikation.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${medikation.search-count}' with error message 'No valid search results were found'
    And element "subject" in all bundle resources references resource with ID "${medikation.medication-patient-id}"