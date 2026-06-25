# language: en
@Stufe5
@Medikation
@Mandatory
@MedicationStatement-Search
Feature: Testing search parameters against a resource of type MedicationStatement (@MedicationStatement-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The MedicationStatement-Read and MedicationStatement-Read-Extended test cases must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "MedicationStatement"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "MedicationStatement"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | code             | token           |
      | context          | reference       |
      | effective        | date            |
      | medication       | reference       |
      | patient          | reference       |
      | status           | token           |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |

  Scenario: Search for the MedicationStatement by ID
    Then Get FHIR resource at "http://fhirserver/MedicationStatement/?_id=${data.medicationstatement-read-id}" with content type "xml"
    And response bundle contains resource with ID "${data.medicationstatement-read-id}" with error message "The requested MedicationStatement ${data.medicationstatement-read-id} is not contained in the response bundle"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "MedicationStatement" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationsInformation"

  Scenario: Search for the MedicationRequest by Count
    When Get FHIR resource at "http://fhirserver/MedicationStatement/?_count=1" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= 1' with error message 'The _count parameter was not applied as expected'

  Scenario: Search for the MedicationStatement by Patient Reference
    Then Get FHIR resource at "http://fhirserver/MedicationStatement/?patient=Patient/${data.medication-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "Patient/${data.medication-patient-id}"

  Scenario: Search for the MedicationStatement by Patient Identifier
    Then Get FHIR resource at "http://fhirserver/MedicationStatement/?patient.identifier=${data.medication-patient-identifier}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "Patient/${data.medication-patient-id}$"

  @Optional
  Scenario: Optional Search for the MedicationRequest that belong to a Patient, by Tag
    When Get FHIR resource at "http://fhirserver/MedicationStatement/?_tag=${data.tag-system}%7C${data.tag-value}&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the MedicationStatement that belong to a Patient, by Code
    Then Get FHIR resource at "http://fhirserver/MedicationStatement/?code=http://fhir.de/CodeSystem/bfarm/atc%7CV03AB23&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    # The below assertion checks only entries with existing medication as CodableConcept and ignores others, which can be medicationReferences (cf. ANFISK-314)
    And FHIR current response body evaluates the FHIRPath "entry.resource.where(medication.coding.empty().not()).medication.coding.where(code = 'V03AB23' and system = 'http://fhir.de/CodeSystem/bfarm/atc').exists()" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the MedicationStatement that belong to a Patient, by Context
    Then Get FHIR resource at "http://fhirserver/MedicationStatement/?context=Encounter/${data.medication-encounter-id}&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "context" in all bundle resources references resource with ID "Encounter/${data.medication-encounter-id}"

  Scenario: Search for the MedicationStatement that belong to a Patient, by Context Identifier
    Then Get FHIR resource at "http://fhirserver/MedicationStatement/?context.identifier=${data.medication-encounter-identifier-value}&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'

  Scenario: Search for the MedicationStatement that belong to a Patient, by Effective Date
    Then Get FHIR resource at "http://fhirserver/MedicationStatement/?effective=gt2026-01-01&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(effective.toString().empty().not() or effective.start.toString().empty().not() or effective.end.toString().empty().not())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the MedicationStatement that belong to a Patient, by Referenced Medication
    Then Get FHIR resource at "http://fhirserver/MedicationStatement/?medication=Medication/${data.medication-read-id}&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "medication" in all bundle resources references resource with ID "Medication/${data.medication-read-id}"

  Scenario: Search for the MedicationStatement that belong to a Patient, by Medication Code
    Then Get FHIR resource at "http://fhirserver/MedicationStatement/?medication.code=V03AB23&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And response bundle contains resource with ID "${data.medicationstatement-read-id}" with error message "The MedicationStatement with ID ${data.medicationstatement-read-id} is not contained in the response bundle"

  Scenario: Search for the MedicationStatement that belong to a Patient, by Status
    Then Get FHIR resource at "http://fhirserver/MedicationStatement/?status=active&patient=Patient/${data.medication-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(status = 'active')" with error message 'There are search results, but they do not fully match the search criteria'
