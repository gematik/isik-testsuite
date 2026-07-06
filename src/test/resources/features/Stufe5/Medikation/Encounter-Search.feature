# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementLeistungserbringerRolle
@Encounter-Search
Feature: Testing search parameters against a resource of type Encounter, according to the definition of ISiKCapabilityStatementLeistungserbringerRolle (@Encounter-Search @Medikation)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - A valid Encounter resource conform to the Profile ISiKKontaktGesundheitseinrichtung and with ID defined in the property 'medication-encounter-basic-role-id'
      - The Encounter resource MUST have valid `location` and `service-provider` references
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

  Scenario: Search for the encounter by Location
    When Get FHIR resource at "http://fhirserver/Encounter/?location=Location/${data.medication-encounter-location}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath 'entry.resource.all(location.location.reference.replaceMatches("/_history/.+","").matches("\\b${data.medication-encounter-location}$"))' with error message 'There are search results, but they do not fully match the search criteria'
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "Encounter" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKKontaktGesundheitseinrichtung"

  Scenario: Search for the encounter by Service Provider
    When Get FHIR resource at "http://fhirserver/Encounter/?service-provider=${data.medication-encounter-service-provider}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath 'entry.resource.all(serviceProvider.reference.replaceMatches("/_history/.+","").matches("\\b${data.medication-encounter-service-provider}$"))' with error message 'There are search results, but they do not fully match the search criteria'
