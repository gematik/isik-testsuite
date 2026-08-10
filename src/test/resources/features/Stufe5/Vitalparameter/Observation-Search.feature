# language: en
@Stufe5
@Vitalparameter
@Mandatory
@ISiKCapabilityStatementVitalSignStandardSourceRolle
@Observation-Search
Feature: Testing search parameters against a resource of type Observation (@Observation-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find the previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Observation test cases must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "Observation"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Observation"

    Examples:
      | searchParamValue          | searchParamType |
      | _id                       | token           |
      | _count                    | number          |
      | status                    | token           |
      | category                  | token           |
      | date                      | date            |
      | code                      | token           |
      | patient                   | reference       |
      | encounter                 | reference       |
      | combo-code                | token           |
      | combo-code-value-quantity | composite       |
      | component-code            | token           |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | subject          | reference       |
      | _tag             | token           |

  Scenario: Search for the Observation by ID
    Then Get FHIR resource at "http://fhirserver/Observation/?_id=${vitalparameter.observation-read-arterial-blood-pressure-id}" with content type "xml"
    And response bundle contains resource with ID "${vitalparameter.observation-read-arterial-blood-pressure-id}" with error message "The requested Observation ${vitalparameter.observation-read-arterial-blood-pressure-id} is not contained in the response bundle"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "Observation" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKBlutdruckSystemischArteriell"

  @Optional
  Scenario: Search for the Observation by Tag and ID
    When Get FHIR resource at "http://fhirserver/Observation/?_tag=${vitalparameter.tag-system}%7C${vitalparameter.tag-value}&_id=${vitalparameter.observation-read-arterial-blood-pressure-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${vitalparameter.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${vitalparameter.observation-read-arterial-blood-pressure-id}" with error message "The requested Observation ${vitalparameter.observation-read-arterial-blood-pressure-id} is not contained in the response bundle"

  Scenario: Search for the Observation by Count
    When Get FHIR resource at "http://fhirserver/Observation/?_count=2" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= 2' with error message 'The _count parameter was not applied as expected'

  Scenario: Search for the Observation that belong to a Patient, by Status
    Then Get FHIR resource at "http://fhirserver/Observation/?status=final&patient=Patient/${vitalparameter.observation-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(status = 'final')" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Observation that belong to a Patient, by Category
    Then Get FHIR resource at "http://fhirserver/Observation/?category=vital-signs&patient=Patient/${vitalparameter.observation-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(category.coding.where(code = 'vital-signs').exists())" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Observation that belong to a Patient, by Date
    Then Get FHIR resource at "http://fhirserver/Observation/?date=2026-03-05&patient=Patient/${vitalparameter.observation-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(effective.toString().contains('2026-03-05'))" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Observation that belong to a Patient, by Date with 'le' Modifier
    Then Get FHIR resource at "http://fhirserver/Observation/?patient=Patient/${vitalparameter.observation-patient-id}&date=le2027-01-01" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(effective.exists())" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Observation that belong to a Patient, by Code
    Then Get FHIR resource at "http://fhirserver/Observation/?code=85354-9&patient=Patient/${vitalparameter.observation-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(code.coding.where(code = '85354-9' and system = 'http://loinc.org').exists())" with error message 'There are search results, but they do not fully match the search criteria.'
    And response bundle contains resource with ID "${vitalparameter.observation-read-arterial-blood-pressure-id}" with error message "The requested Observation ${vitalparameter.observation-read-arterial-blood-pressure-id} is not contained in the response bundle"

  Scenario: Search for the Observation by Patient (Search Parameter 'patient')
    Then Get FHIR resource at "http://fhirserver/Observation/?patient=Patient/${vitalparameter.observation-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "Patient/${vitalparameter.observation-patient-id}"

  @Optional
  Scenario: Optional Search for the Observation by Patient (Search Parameter 'subject')
    Then Get FHIR resource at "http://fhirserver/Observation/?subject=Patient/${vitalparameter.observation-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "Patient/${vitalparameter.observation-patient-id}"

  Scenario: Search for the Observation that belong to a Patient, by Encounter
    Then Get FHIR resource at "http://fhirserver/Observation/?encounter=Encounter/${vitalparameter.observation-encounter-id}&patient=Patient/${vitalparameter.observation-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(encounter.reference.replaceMatches('/_history/.+','').matches('\\b${vitalparameter.observation-encounter-id}$'))" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Observation that belong to a Patient, by Combo Code
    Then Get FHIR resource at "http://fhirserver/Observation/?combo-code=8462-4&patient=Patient/${vitalparameter.observation-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(code.coding.where(code = '8462-4' and system = 'http://loinc.org').exists() or component.where(code.coding.where(code = '8462-4' and system = 'http://loinc.org').exists()).exists())" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Observation that belong to a Patient, by Combo Code Value Quantity
    Then Get FHIR resource at "http://fhirserver/Observation/?patient=Patient/${vitalparameter.observation-patient-id}&combo-code-value-quantity=8480-6$107" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all((code.coding.where(code = '8480-6' and system = 'http://loinc.org').exists() or component.where(code.coding.where(code = '8480-6' and system = 'http://loinc.org').exists()).exists()) and (value.value ~ '107' or component.where(value.value ~ '107').exists()))" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the Observation that belong to a Patient, by Component Code
    Then Get FHIR resource at "http://fhirserver/Observation/?component-code=8480-6&patient=Patient/${vitalparameter.observation-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(component.where(code.coding.where(code = '8480-6' and system = 'http://loinc.org').exists()).exists())" with error message 'There are search results, but they do not fully match the search criteria.'

