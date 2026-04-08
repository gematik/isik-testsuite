# language: en
@Stufe5
@Medikation
@Mandatory
@List-Search
Feature: Testing search parameters against a resource of type Medication List (@List-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The List-Read test case must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "List"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "List"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | code             | token           |
      | date             | date            |
      | encounter        | reference       |
      | item             | reference       |
      | patient          | reference       |
      | status           | token           |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |

  Scenario: Search for the List by ID
    Then Get FHIR resource at "http://fhirserver/List/?_id=${data.list-read-id}" with content type "xml"
    And response bundle contains resource with ID "${data.list-read-id}" with error message "The requested List ${data.list-read-id} is not contained in the response bundle"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "List" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationsListe"

  Scenario: Search for the List by Count
    When Get FHIR resource at "http://fhirserver/List/?_count" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'total > 0 and entry.resource.count() > 0' with error message 'No search results were found'

  Scenario: Search for the List that belong to a Patient, by Patient Reference
    Then Get FHIR resource at "http://fhirserver/List/?patient=Patient/${data.medication-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "Patient/${data.medication-patient-id}"

  Scenario: Search for the List that belong to a Patient, by Patient Identifier
    Then Get FHIR resource at "http://fhirserver/List/?patient.identifier=${data.medication-patient-identifier}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.where(subject.reference.replaceMatches('/_history/.+','').matches('Patient/${data.medication-patient-id}$')).exists()" with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Search for the List that belong to a Patient, by Tag
    When Get FHIR resource at "http://fhirserver/List/?_tag=${data.tag-system}%7C${data.tag-value}&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the List that belong to a Patient, by Code
    Then Get FHIR resource at "http://fhirserver/List/?code=http://terminology.hl7.org/CodeSystem/list-example-use-codes%7Cmedications&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(code.coding.where(code = 'medications' and system = 'http://terminology.hl7.org/CodeSystem/list-example-use-codes').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the List that belong to a Patient, by Date
    Then Get FHIR resource at "http://fhirserver/List/?date=gt2026-01-01&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And response bundle contains resource with ID "${data.list-read-id}" with error message "The requested List ${data.list-read-id} is not contained in the response bundle"

  Scenario: Search for the List that belong to a Patient, by Encounter Reference
    Then Get FHIR resource at "http://fhirserver/List/?encounter=Encounter/${data.medication-encounter-id}&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "encounter" in all bundle resources references resource with ID "Encounter/${data.medication-encounter-id}"

  Scenario: Search for the List that belong to a Patient, by Encounter Identifier
    Then Get FHIR resource at "http://fhirserver/List/?encounter.identifier=${data.medication-encounter-identifier}&patient=Patient/${data.medication-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.where(encounter.reference.replaceMatches('/_history/.+','').matches('Encounter/${data.medication-encounter-id}$')).exists()" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the List that belong to a Patient, by Status
    Then Get FHIR resource at "http://fhirserver/List/?status=current&patient=Patient/${data.medication-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(status = 'current')" with error message 'There are search results, but they do not fully match the search criteria'
