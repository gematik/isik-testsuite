# language: en
@Stufe5
@Medikation
@Mandatory
@MedicationAdministration-Search
Feature: Testing search parameters against a resource of type MedicationAdministration (@MedicationAdministration-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The MedicationAdministration-Read and MedicationAdministration-Read-Extended test cases must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "MedicationAdministration"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "MedicationAdministration"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | code             | token           |
      | context          | reference       |
      | effective-time   | date            |
      | medication       | reference       |
      | patient          | reference       |
      | performer        | reference       |
      | status           | token           |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |

  Scenario: Search for the MedicationAdministration by ID
    Then Get FHIR resource at "http://fhirserver/MedicationAdministration/?_id=${data.medicationadministration-read-id}" with content type "xml"
    And response bundle contains resource with ID "${data.medicationadministration-read-id}" with error message "The requested MedicationAdministration ${data.medicationadministration-read-id} is not contained in the response bundle"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "MedicationAdministration" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationsVerabreichung"

  Scenario: Search for the MedicationAdministration by Count
    When Get FHIR resource at "http://fhirserver/MedicationAdministration/?_count" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'total > 0 and entry.resource.count() > 0' with error message 'No search results were found'

  Scenario: Search for the MedicationAdministration by Patient Reference
    Then Get FHIR resource at "http://fhirserver/MedicationAdministration/?patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "Patient/${data.medication-patient-id}"

  Scenario: Search for the MedicationAdministration by Patient Identifier
    Then Get FHIR resource at "http://fhirserver/MedicationAdministration/?subject.identifier=${data.medication-patient-identifier}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "Patient/${data.medication-patient-id}"

  @Optional
  Scenario: Search for the MedicationAdministration that belong to a Patient, by Tag
    When Get FHIR resource at "http://fhirserver/MedicationAdministration/?_tag=${data.tag-system}%7C${data.tag-value}&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${data.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the MedicationAdministration that belong to a Patient, by Code
    Then Get FHIR resource at "http://fhirserver/MedicationAdministration/?code=http://fhir.de/CodeSystem/bfarm/atc%7CV03AB23&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    # The below assertion checks only entries with existing medication as CodableConcept and ignores others, which can be medicationReferences (cf. ANFISK-314)
    And FHIR current response body evaluates the FHIRPath "entry.resource.where(medication.coding.empty().not()).medication.coding.where(code = 'V03AB23' and system = 'http://fhir.de/CodeSystem/bfarm/atc').exists()" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the MedicationAdministration that belong to a Patient, by Context
    Then Get FHIR resource at "http://fhirserver/MedicationAdministration/?context=Encounter/${data.medication-encounter-id}&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "context" in all bundle resources references resource with ID "Encounter/${data.medication-encounter-id}"

  Scenario: Search for the MedicationAdministration that belong to a Patient, by Context Identifier
    Then Get FHIR resource at "http://fhirserver/MedicationAdministration/?context.identifier=${data.medication-encounter-identifier}&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "context" in all bundle resources references resource with ID "Encounter/${data.medication-encounter-id}"

  Scenario: Search for the MedicationAdministration that belong to a Patient, by Effective Time
    Then Get FHIR resource at "http://fhirserver/MedicationAdministration/?effective-time=gt2026-01-01&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(effective.toString().empty().not() or effective.start.toString().empty().not() or effective.end.toString().empty().not())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the MedicationAdministration that belong to a Patient, by Referenced Medication
    Then Get FHIR resource at "http://fhirserver/MedicationAdministration/?medication=Medication/${data.medication-read-id}&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "medication" in all bundle resources references resource with ID "Medication/${data.medication-read-id}"

  Scenario: Search for the MedicationAdministration that belong to a Patient, by Medication Code
    Then Get FHIR resource at "http://fhirserver/MedicationAdministration/?medication.code=http://fhir.de/CodeSystem/bfarm/atc%7CV03AB23&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And response bundle contains resource with ID "${data.medicationadministration-read-id}" with error message "The requested MedicationAdministration ${data.medicationadministration-read-id} is not contained in the response bundle"

  Scenario: Search for the MedicationAdministration that belong to a Patient, by Performer Reference
    Then Get FHIR resource at "http://fhirserver/MedicationAdministration/?performer=Practitioner/${data.medication-practitioner-id}&patient=Patient/${data.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "performer.actor" in all bundle resources references resource with ID "Practitioner/${data.medication-practitioner-id}"

  Scenario: Search for the MedicationAdministration that belong to a Patient, by Performer Identifier
    Then Get FHIR resource at "http://fhirserver/MedicationAdministration/?performer.identifier=${data.medication-practitioner-identifier}&patient=Patient/${data.medication-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "performer.actor" in all bundle resources references resource with ID "Practitioner/${data.medication-practitioner-id}"

  Scenario: Search for the MedicationAdministration that belong to a Patient, by Status
    Then Get FHIR resource at "http://fhirserver/MedicationAdministration/?status=completed&patient=Patient/${data.medication-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(status = 'completed')" with error message 'There are search results, but they do not fully match the search criteria'
