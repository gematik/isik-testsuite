# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementMedikationVerordnungRolle
@MedicationRequest-Search
Feature: Testing search parameters against a resource of type MedicationRequest (@MedicationRequest-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The MedicationRequest-Read and MedicationRequest-Read-Extended test cases must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "MedicationRequest"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "MedicationRequest"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | authoredon       | date            |
      | code             | token           |
      | date             | date            |
      | encounter        | reference       |
      | intent           | token           |
      | medication       | reference       |
      | patient          | reference       |
      | requester        | reference       |
      | status           | token           |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _tag             | token           |

  Scenario: Search for the MedicationRequest by ID
    Then Get FHIR resource at "http://fhirserver/MedicationRequest/?_id=${medikation.medicationrequest-read-id}" with content type "xml"
    And response bundle contains resource with ID "${medikation.medicationrequest-read-id}" with error message "The requested resource with ID ${medikation.medicationrequest-read-id} is not contained in the response bundle"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "MedicationRequest" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationsVerordnung"

  Scenario: Search for the MedicationRequest by Count
    When Get FHIR resource at "http://fhirserver/MedicationRequest/?_count=1" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= 1' with error message 'The _count parameter was not applied as expected'

  Scenario: Search for the MedicationRequest by Patient Reference
    Then Get FHIR resource at "http://fhirserver/MedicationRequest/?patient=Patient/${medikation.medication-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "Patient/${medikation.medication-patient-id}"

  Scenario: Search for the MedicationRequest by Patient Identifier
    Then Get FHIR resource at "http://fhirserver/MedicationRequest/?patient.identifier=${medikation.medication-patient-identifier}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(subject.identifier.value='${medikation.medication-patient-identifier}' or subject.reference.replaceMatches('/_history/.+','').matches('Patient/${medikation.medication-patient-id}$'))" with error message 'There are search results, but they do not fully match the search criteria'

  @Optional
  Scenario: Optional Search for the MedicationRequest that belong to a Patient, by Tag
    When Get FHIR resource at "http://fhirserver/MedicationRequest/?_tag=${medikation.tag-system}%7C${medikation.tag-value}&patient=Patient/${medikation.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${medikation.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the MedicationRequest that belong to a Patient, by Authored Date
    Then Get FHIR resource at "http://fhirserver/MedicationRequest/?authoredon=gt2026-01-01&patient=Patient/${medikation.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(authoredOn.toString().empty().not())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the MedicationRequest that belong to a Patient, by Code
    Then Get FHIR resource at "http://fhirserver/MedicationRequest/?code=R01AA04&patient=Patient/${medikation.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    # The below assertion checks only entries with existing medication as CodableConcept and ignores others, which can be medicationReferences (cf. ANFISK-314)
    And FHIR current response body evaluates the FHIRPath "entry.resource.where(medication.coding.empty().not()).medication.coding.where(code = 'R01AA04' and system = 'http://fhir.de/CodeSystem/bfarm/atc').exists()" with error message 'There are search results, but they do not fully match the search criteria'

  # The search requires that the MedicationRequest has a valid Field "dosageInstruction.timing.event" with a valid date value
  Scenario: Search for the MedicationRequest that belong to a Patient, by Date
    Then Get FHIR resource at "http://fhirserver/MedicationRequest/?date=gt2026-01-01&patient=Patient/${medikation.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(dosageInstruction.timing.event.empty().not())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the MedicationRequest that belong to a Patient, by Encounter
    Then Get FHIR resource at "http://fhirserver/MedicationRequest/?encounter=Encounter/${medikation.medication-encounter-id}&patient=Patient/${medikation.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "encounter" in all bundle resources references resource with ID "Encounter/${medikation.medication-encounter-id}"

  Scenario: Search for the MedicationRequest that belong to a Patient, by Encounter Identifier
    Then Get FHIR resource at "http://fhirserver/MedicationRequest/?encounter.identifier=${medikation.medication-encounter-identifier-value}&patient=Patient/${medikation.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'

  Scenario: Search for the MedicationRequest that belong to a Patient, by Intent
    Then Get FHIR resource at "http://fhirserver/MedicationRequest/?intent=order&patient=Patient/${medikation.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(intent = 'order')" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the MedicationRequest that belong to a Patient, by Referenced Medication
    Then Get FHIR resource at "http://fhirserver/MedicationRequest/?medication=Medication/${medikation.medicationrequest-medication-id}&patient=Patient/${medikation.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "medication" in all bundle resources references resource with ID "Medication/${medikation.medicationrequest-medication-id}"

  Scenario: Search for the MedicationRequest that belong to a Patient, by Medication Code
    Then Get FHIR resource at "http://fhirserver/MedicationRequest/?medication.code=V03AB23&patient=Patient/${medikation.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And response bundle contains resource with ID "${medikation.medicationrequest-read-id}" with error message "The MedicationRequest with ID ${medikation.medicationrequest-read-id} is not contained in the response bundle"

  Scenario: Search for the MedicationRequest that belong to a Patient, by Requester Reference
    Then Get FHIR resource at "http://fhirserver/MedicationRequest/?requester=Practitioner/${medikation.medication-practitioner-id}&patient=Patient/${medikation.medication-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "requester" in all bundle resources references resource with ID "Practitioner/${medikation.medication-practitioner-id}"

  Scenario: Search for the MedicationRequest that belong to a Patient, by Requester Identifier
    Then Get FHIR resource at "http://fhirserver/MedicationRequest/?requester.identifier=${medikation.medication-practitioner-identifier}&patient=Patient/${medikation.medication-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(requester.identifier.value='${medikation.medication-practitioner-identifier}' or requester.reference.replaceMatches('/_history/.+','').matches('Practitioner/${medikation.medication-practitioner-id}$'))" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the MedicationRequest that belong to a Patient, by Status
    Then Get FHIR resource at "http://fhirserver/MedicationRequest/?status=completed&patient=Patient/${medikation.medication-patient-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(status = 'completed')" with error message 'There are search results, but they do not fully match the search criteria'
    