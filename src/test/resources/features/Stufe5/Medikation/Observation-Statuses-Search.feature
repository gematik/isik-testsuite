# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementGesundheitsstatusRolle
@Observation-Statuses-Search
Feature: Testing search parameters against Observation resources for status-related observations (@Observation-Statuses-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find previously created Observation resources when searched using the supported parameters and return them in the search results (SEARCH)."
    Given the Preconditions:
	"""
	  - The Observation-Alcohol-Abuse-Read test case must have been executed successfully beforehand.
	  - The Observation-Breastfeeding-Read test case must have been executed successfully beforehand.
	  - The Observation-Pregnancy-Status-Read test case must have been executed successfully beforehand.
	  - The Observation-Expected-Pregnancy-Delivery-Date-Read test case must have been executed successfully beforehand.
	  - The Observation-Smoking-Status-Read test case must have been executed successfully beforehand.
	"""

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "Observation"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Observation"

    Examples:
      | searchParamValue          | searchParamType |
      | _id                       | token           |
      | _count                    | number          |
      | status                    | token           |
      | category                  | token           |
      | code                      | token           |
      | patient                   | reference       |
      | date                      | date            |
      | combo-code                | token           |
      | combo-code-value-quantity | composite       |
      | component-code            | token           |
      | encounter                 | reference       |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _has             | string          |
      | _tag             | token           |
      | subject          | reference       |

  Scenario Outline: Search for Observation resources by ID
    When Get FHIR resource at "http://fhirserver/Observation/?_id=<observationId>" with content type "xml"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And response bundle contains resource with ID "<observationId>" with error message "The requested Observation <observationId> is not contained in the response bundle"

    Examples:
      | observationId                                                           |
      | ${data.medication-observation-alcohol-abuse-read-id}                    |
      | ${data.medication-observation-breastfeeding-read-id}                    |
      | ${data.medication-observation-pregnancy-status-read-id}                 |
      | ${data.medication-observation-expected-pregnancy-delivery-date-read-id} |
      | ${data.medication-observation-smoking-status-read-id}                   |

  Scenario: Search for Observation resources by Status "final" and Encounter
    When Get FHIR resource at "http://fhirserver/Observation/?status=http://hl7.org/fhir/observation-status%7Cfinal&encounter=Encounter/${data.encounter-read-in-progress-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(status = 'final')" with error message 'There are search results, but they do not fully match the status search criteria'
    And FHIR current response body evaluates the FHIRPath 'entry.resource.all(encounter.reference.replaceMatches("/_history/.+","").matches("\\b${data.encounter-read-in-progress-id}$"))' with error message 'There are search results, but they do not fully match the encounter search criteria'

  Scenario Outline: Search for Observation resources by Code and Encounter
    When Get FHIR resource at "http://fhirserver/Observation/?code=http://loinc.org%7C<loincCode>&encounter=Encounter/${data.encounter-read-in-progress-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(code.coding.where(code = '<loincCode>' and system = 'http://loinc.org').exists())" with error message 'There are search results, but they do not fully match the code search criteria'
    And response bundle contains resource with ID "<observationId>" with error message "The requested Observation <observationId> is not contained in the response bundle"

    Examples:
      | loincCode | observationId                                                           |
      | 74043-1   | ${data.medication-observation-alcohol-abuse-read-id}                    |
      | 63895-7   | ${data.medication-observation-breastfeeding-read-id}                    |
      | 82810-3   | ${data.medication-observation-pregnancy-status-read-id}                 |
      | 11779-6   | ${data.medication-observation-expected-pregnancy-delivery-date-read-id} |
      | 72166-2   | ${data.medication-observation-smoking-status-read-id}                   |

  Scenario: Search for Observation resources by Patient (search parameter 'patient')
    When Get FHIR resource at "http://fhirserver/Observation/?patient=Patient/${data.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "Patient/${data.patient-read-id}"

  Scenario: Search for Observation resources by Date and Encounter
    When Get FHIR resource at "http://fhirserver/Observation/?date=2026-01-06&encounter=Encounter/${data.encounter-read-in-progress-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(effective.toString().contains('2026-01-06'))" with error message 'There are search results, but they do not fully match the date search criteria'

  Scenario: Search for Observation resources by Encounter and Patient
    When Get FHIR resource at "http://fhirserver/Observation/?encounter=Encounter/${data.encounter-read-in-progress-id}&patient=Patient/${data.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "Patient/${data.patient-read-id}"

  @Optional
  Scenario: Optional Search for Observation resources that have the given Tag, group by _count
    When Post FHIR search request to "http://fhirserver/Observation/_search" with content type "xml" and parameters:
      | _tag                                  | _count               |
      | ${data.tag-system}\|${data.tag-value} | ${data.search-count} |
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= ${data.search-count}' with error message 'Invalid search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Optional Search for Observation resources by Subject (search parameter 'subject')
    When Get FHIR resource at "http://fhirserver/Observation/?subject=Patient/${data.patient-read-extended-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "Patient/${data.patient-read-extended-id}"
