# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementMedikamentRolle
@Medication-Search
Feature: Testing search parameters against a resource of type Medication (@Medication-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Medication-Read and Medication-Read-Extended test cases must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "Medication"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Medication"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | code             | token           |
      | form             | token           |
      | ingredient       | reference       |
      | ingredient-code  | token           |
      | lot-number       | token           |
      | status           | token           |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |

  Scenario: Search for the Medication by ID
    Then Get FHIR resource at "http://fhirserver/Medication/?_id=${medikation.medication-read-id}" with content type "xml"
    And response bundle contains resource with ID "${medikation.medication-read-id}" with error message "The requested Medication ${medikation.medication-read-id} is not contained in the response bundle"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "Medication" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikament"

  Scenario: Search for the Medication by Count
    When Get FHIR resource at "http://fhirserver/Medication/?_count=1" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= 1' with error message 'The _count parameter was not applied as expected'

  @Optional
  Scenario: Optional Search for the Medication by Tag and ID
    When Get FHIR resource at "http://fhirserver/Medication/?_tag=${medikation.tag-system}%7C${medikation.tag-value}&_id=${medikation.medication-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${medikation.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Medication by Code and ID
    Then Get FHIR resource at "http://fhirserver/Medication/?code=http://fhir.de/CodeSystem/bfarm/atc%7CV03AB23&_id=${medikation.medication-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all((code.coding.where(code = 'V03AB23' and system = 'http://fhir.de/CodeSystem/bfarm/atc').exists()))" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Medication by Free-Text Code
    Then Get FHIR resource at "http://fhirserver/Medication/?code:text=Infusion" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(code.text.contains('Infusion'))" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Medication by Form
    Then Get FHIR resource at "http://fhirserver/Medication/?form=11210000" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(form.coding.where(code = '11210000').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Medication by Referenced Ingredient
    Then Get FHIR resource at "http://fhirserver/Medication/?ingredient=Medication/${medikation.medication-read-referenced-ingredient}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "ingredient.item" in all bundle resources references resource with ID "${medikation.medication-read-referenced-ingredient}"

  Scenario: Search for the Medication by Ingredient Code (Chaining) and ID
    # Code from the referenced medication-read-referenced-ingredient
    Then Get FHIR resource at "http://fhirserver/Medication/?ingredient.code=V03AB23&_id=${medikation.medication-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And response bundle contains resource with ID "${medikation.medication-read-id}" with error message "The requested Medication ${medikation.medication-read-id} is not contained in the response bundle"

  Scenario: Search for the Medication by Ingredient Code and ID
    Then Get FHIR resource at "http://fhirserver/Medication/?ingredient-code=L01DB01&_id=${medikation.medication-read-extended-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And response bundle contains resource with ID "${medikation.medication-read-extended-id}" with error message "The requested Medication ${medikation.medication-read-extended-id} is not contained in the response bundle"

  Scenario: Search for the Medication by Lot Number and ID
    Then Get FHIR resource at "http://fhirserver/Medication/?lot-number=123&_id=${medikation.medication-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And response bundle contains resource with ID "${medikation.medication-read-id}" with error message "The requested Medication ${medikation.medication-read-id} is not contained in the response bundle"

  Scenario: Search for the Medication by Status and ID
    Then Get FHIR resource at "http://fhirserver/Medication/?status=active&_id=${medikation.medication-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And response bundle contains resource with ID "${medikation.medication-read-id}" with error message "The requested Medication ${medikation.medication-read-id} is not contained in the response bundle"
