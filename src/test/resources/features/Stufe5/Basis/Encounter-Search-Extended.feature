# language: en
@Stufe5
@Basis
@Mandatory
@ISiKCapabilityStatementErweiterteStammdatenRolle
@ISiKCapabilityStatementLeistungserbringerRolle
@Encounter-Search-Extended
Feature: Testing search parameters against a resource of type encounter-read-in-progress, according to the definition of ISiKCapabilityStatementErweiterteStammdatenRolle (@Encounter-Search-Extended)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Encounter-Read-In-Progress, Encounter-Read-Finished, Encounter-Search and Account-Read test cases must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "Encounter"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Encounter"

    Examples:
      | searchParamValue | searchParamType |
      | location         | reference       |
      | service-provider | reference       |

  Scenario: Search for the encounter by Location and Patient
    When Get FHIR resource at "http://fhirserver/Encounter/?location=Location/${basis.encounter-read-in-progress-location}&patient=Patient/${basis.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath 'entry.resource.all(location.location.reference.replaceMatches("/_history/.+","").matches("\\b${basis.encounter-read-in-progress-location}$"))' with error message 'There are search results, but they do not fully match the search criteria'
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "Encounter" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKKontaktGesundheitseinrichtung"

  Scenario: Search for the encounter by Service Provider and Patient
    When Get FHIR resource at "http://fhirserver/Encounter/?service-provider=${basis.encounter-read-in-progress-service-provider}&patient=Patient/${basis.patient-read-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath 'entry.resource.all(serviceProvider.reference.replaceMatches("/_history/.+","").matches("\\b${basis.encounter-read-in-progress-service-provider}$"))' with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${basis.encounter-read-in-progress-id}" with error message "The requested Encounter ${basis.encounter-read-in-progress-id} is not contained in the response bundle."