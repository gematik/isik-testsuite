# language: en
@Stufe5
@Medikation
@Mandatory
@RiskAssessment-Search
Feature: Testing search parameters against a resource of type RiskAssessment (@RiskAssessment-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The RiskAssessment-Read and RiskAssessment-Read-Extended test cases must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "RiskAssessment"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "RiskAssessment"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | date             | date            |
      | encounter        | reference       |
      | patient          | reference       |
      | risk             | token           |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |

  Scenario: Search for the RiskAssessment by ID
    Then Get FHIR resource at "http://fhirserver/RiskAssessment/?_id=${data.RiskAssessment-read-id}" with content type "xml"
    And response bundle contains resource with ID "${data.RiskAssessment-read-id}" with error message "The requested resource with ID ${data.RiskAssessment-read-id} is not contained in the response bundle"
    #And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    #And Check if current response of resource "RiskAssessment" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationsVerordnung"

  Scenario: Search for the RiskAssessment by Count
    When Get FHIR resource at "http://fhirserver/RiskAssessment/?_count=1" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= 1' with error message 'The _count parameter was not applied as expected'

  Scenario: Search for the RiskAssessment by Patient Reference
    Then Get FHIR resource at "http://fhirserver/RiskAssessment/?patient=Patient/${data.riskassessment-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "Patient/${data.riskassessment-patient-id}"

  @Optional
  Scenario: Optional Search for the RiskAssessment that belong to a Patient, by Tag
    When Get FHIR resource at "http://fhirserver/RiskAssessment/?_tag=${data.tag-system}%7C${data.tag-value}&patient=Patient/${data.riskassessment-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  # The search requires that the RiskAssessment has a valid Field "dosageInstruction.timing.event" with a valid date value
  Scenario: Search for the RiskAssessment that belong to a Patient, by Date
    Then Get FHIR resource at "http://fhirserver/RiskAssessment/?date=gt2026-01-01&patient=Patient/${data.riskassessment-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'

  Scenario: Search for the RiskAssessment that belong to a Patient, by Encounter
    Then Get FHIR resource at "http://fhirserver/RiskAssessment/?encounter=Encounter/${data.riskassessment-encounter-id}&patient=Patient/${data.riskassessment-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "encounter" in all bundle resources references resource with ID "Encounter/${data.riskassessment-encounter-id}"

  Scenario: Search for the RiskAssessment that belong to a Patient, by Risk
    Then Get FHIR resource at "http://fhirserver/RiskAssessment/?risk=http://terminology.hl7.org/CodeSystem/risk-probability%7Chigh&patient=Patient/${data.riskassessment-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
