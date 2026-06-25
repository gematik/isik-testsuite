# language: en
@Stufe5
@Terminplanung
@Mandatory
@HealthcareService-Search
Feature: Testing search parameters against the HealthcareService resource (@HealthcareService-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the created resource correctly and completely in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The HealthcareService-Read test case must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "HealthcareService"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "HealthcareService"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | active           | token           |
      | service-type     | token           |
      | specialty        | token           |
      | name             | string          |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |

  Scenario: Search for the HealthcareService by ID
    Then Get FHIR resource at "http://fhirserver/HealthcareService/?_id=${data.healthcareservice-read-id}" with content type "xml"
    And response bundle contains resource with ID "${data.healthcareservice-read-id}" with error message "The requested HealthcareService ${data.healthcareservice-read-id} is not contained in the response bundle"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "HealthcareService" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedizinischeBehandlungseinheit"

  @Optional
  Scenario: Optional Search for the HealthcareService by Tag and ID
    When Get FHIR resource at "http://fhirserver/HealthcareService/?_tag=${data.tag-system}%7C${data.tag-value}&_id=${data.healthcareservice-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${data.healthcareservice-read-id}" with error message "The requested HealthcareService ${data.healthcareservice-read-id} is not contained in the response bundle"

  Scenario: Search for the HealthcareService by Count
    When Get FHIR resource at "http://fhirserver/HealthcareService/?_count=1" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= 1' with error message 'The _count parameter was not applied as expected'

  Scenario: Search for the HealthcareService by Active State and ID
    Then Get FHIR resource at "http://fhirserver/HealthcareService/?active=true&_id=${data.healthcareservice-read-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(HealthcareService).count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(HealthcareService).all(active = 'true')" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the HealthcareService by Service Type
    Then Get FHIR resource at "http://fhirserver/HealthcareService/?service-type=${data.healthcareservice-read-servicetype-code}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(HealthcareService).count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(HealthcareService).all(type.coding.where(code='${data.healthcareservice-read-servicetype-code}').exists())" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the HealthcareService by Specialty
    Then Get FHIR resource at "http://fhirserver/HealthcareService/?specialty=urn%3Aoid%3A1.2.276.0.76.5.114%7C142%2Chttp%3A%2F%2Fihe-d.de%2FCodeSystems%2FAerztlicheFachrichtungen%7CNEUR" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(HealthcareService).count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(HealthcareService).all(specialty.coding.where((code = '142' and system ='urn:oid:1.2.276.0.76.5.114') or (code = 'NEUR' and system ='http://ihe-d.de/CodeSystems/AerztlicheFachrichtungen' )).exists())" with error message 'There are search results, but they do not fully match the search criteria.'

  Scenario: Search for the HealthcareService by Name
    Then Get FHIR resource at "http://fhirserver/HealthcareService/?name=${data.healthcareservice-search-name}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.ofType(HealthcareService).count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.ofType(HealthcareService).all(name.contains('${data.healthcareservice-read-name}'))" with error message 'There are search results, but they do not fully match the search criteria.'
