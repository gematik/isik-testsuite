# language: en
@Stufe5
@Labor
@Mandatory
@ISiKCapabilityStatementLaborMinimalRolle
@Observation-Search
Feature: Testing search parameters against a resource of type Observation, according to the definition of ISiKCapabilityStatementLaborMinimalRolle (@Observation-Search @Labor)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find previously created Observation resources when searched using the mandatory (SHALL) search parameters and return them in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Observation-Read-CRP test case must have been executed successfully beforehand.
      - The Observation-Read-GFR test case must have been executed successfully beforehand.
      - The Observation-Read-Hb test case must have been executed successfully beforehand.
      - The Observation-Read-PCT test case must have been executed successfully beforehand.
      - The Observation-Read-Serumkreatinin test case must have been executed successfully beforehand.
      - The Observation-Read-Thrombozyten test case must have been executed successfully beforehand.
      - The Observation-Read-Troponin test case must have been executed successfully beforehand.
      - The Observation-Read-TSH test case must have been executed successfully beforehand.
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
      | _tag             | token           |
      | _has             | string          |
      | subject          | reference       |

  Scenario Outline: Search for the Observation by ID
    When Get FHIR resource at "http://fhirserver/Observation/?_id=<observationId>" with content type "xml"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And response bundle contains resource with ID "<observationId>" with error message "The requested Observation <observationId> is not contained in the response bundle"

    Examples:
      | observationId                              |
      | ${labor.observation-read-crp-id}             |
      | ${labor.observation-read-gfr-id}             |
      | ${labor.observation-read-hb-id}              |
      | ${labor.observation-read-pct-id}             |
      | ${labor.observation-read-serumkreatinin-id}  |
      | ${labor.observation-read-thrombozyten-id}    |
      | ${labor.observation-read-troponin-id}        |
      | ${labor.observation-read-tsh-id}             |

  Scenario: Search for the Observation by Count
    When Get FHIR resource at "http://fhirserver/Observation/?_count=2" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= 2' with error message 'The _count parameter was not applied as expected'

  Scenario: Search for the Observation that belong to a Patient, by Status
    Then Get FHIR resource at "http://fhirserver/Observation/?status=final&patient=Patient/${labor.observation-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(status = 'final')" with error message 'There are search results, but they do not fully match the status search criteria.'

  Scenario: Search for the Observation that belong to a Patient, by Category
    Then Get FHIR resource at "http://fhirserver/Observation/?category=laboratory&patient=Patient/${labor.observation-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(category.coding.where(code = 'laboratory').exists())" with error message 'There are search results, but they do not fully match the category search criteria.'

  Scenario: Search for the Observation that belong to a Patient, by Date
    Then Get FHIR resource at "http://fhirserver/Observation/?date=2024-05-14&patient=Patient/${labor.observation-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(effective.toString().contains('2024-05-14'))" with error message 'There are search results, but they do not fully match the date search criteria.'

  Scenario Outline: Search for the Observation that belong to a Patient, by Code
    Then Get FHIR resource at "http://fhirserver/Observation/?code=http://loinc.org%7C<loincCode>&patient=Patient/${labor.observation-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(code.coding.where(code = '<loincCode>' and system = 'http://loinc.org').exists())" with error message 'There are search results, but they do not fully match the code search criteria.'
    And response bundle contains resource with ID "<observationId>" with error message "The requested Observation <observationId> is not contained in the response bundle"

    Examples:
      | loincCode | observationId                               |
      | 1988-5    | ${labor.observation-read-crp-id}             |
      | 98980-6   | ${labor.observation-read-gfr-id}             |
      | 718-7     | ${labor.observation-read-hb-id}              |
      | 33959-8   | ${labor.observation-read-pct-id}             |
      | 2160-0    | ${labor.observation-read-serumkreatinin-id}  |
      | 26515-7   | ${labor.observation-read-thrombozyten-id}    |
      | 42757-5   | ${labor.observation-read-troponin-id}        |
      | 3015-5    | ${labor.observation-read-tsh-id}             |

  Scenario: Search for the Observation by Patient (Search Parameter 'patient')
    Then Get FHIR resource at "http://fhirserver/Observation/?patient=Patient/${labor.observation-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "Patient/${labor.observation-patient-id}"

  Scenario: Search for the Observation that belong to a Patient, by Encounter
    Then Get FHIR resource at "http://fhirserver/Observation/?encounter=Encounter/${labor.observation-encounter-id}&patient=Patient/${labor.observation-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(encounter.reference.replaceMatches('/_history/.+','').matches('\\b${labor.observation-encounter-id}$'))" with error message 'There are search results, but they do not fully match the encounter search criteria.'

  Scenario: Search for the Observation that belong to a Patient, by Combo Code
    Then Get FHIR resource at "http://fhirserver/Observation/?combo-code=1988-5&patient=Patient/${labor.observation-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(code.coding.where(code = '1988-5' and system = 'http://loinc.org').exists() or component.where(code.coding.where(code = '1988-5' and system = 'http://loinc.org').exists()).exists())" with error message 'There are search results, but they do not fully match the combo-code search criteria.'
    And response bundle contains resource with ID "${labor.observation-read-crp-id}" with error message "The requested Observation ${labor.observation-read-crp-id} is not contained in the response bundle"

  Scenario: Search for the Observation that belong to a Patient, by Combo Code Value Quantity
    Then Get FHIR resource at "http://fhirserver/Observation/?patient=Patient/${labor.observation-patient-id}&combo-code-value-quantity=1988-5$7.4" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all((code.coding.where(code = '1988-5' and system = 'http://loinc.org').exists() or component.where(code.coding.where(code = '1988-5' and system = 'http://loinc.org').exists()).exists()) and (value.value ~ '7.4' or component.where(value.value ~ '7.4').exists()))" with error message 'There are search results, but they do not fully match the combo-code-value-quantity search criteria.'
    And response bundle contains resource with ID "${labor.observation-read-crp-id}" with error message "The requested Observation ${labor.observation-read-crp-id} is not contained in the response bundle"

  @Optional
  Scenario: Optional Search for the Observation by Patient (Search Parameter 'subject')
    Then Get FHIR resource at "http://fhirserver/Observation/?subject=Patient/${labor.observation-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "Patient/${labor.observation-patient-id}"

  @Optional
  Scenario: Optional Search for the Observation by Tag and Patient
    When Get FHIR resource at "http://fhirserver/Observation/?_tag=${labor.tag-system}%7C${labor.tag-value}&patient=Patient/${labor.observation-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${labor.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'
