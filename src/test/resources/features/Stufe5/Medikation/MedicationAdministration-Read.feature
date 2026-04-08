# language: en
@Stufe5
@Medikation
@Mandatory
@MedicationAdministration-Read
Feature: Read Information from a resource of type MedicationAdministration (@MedicationAdministration-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The Medication-Read test case must have been executed successfully beforehand.
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resources for this test data set must be stored in the configuration variable 'medicationadministration-read-id'.

      Create a MedicationAdministration resource in your system with the following values:
      * Id: The value of the configuration variable 'medicationadministration-read-id'
      * Status: completed
      * Referenced medication: the medication from test case Medication-Read
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in 'medication-patient-id')
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in 'medication-encounter-id')
      * Associated encounter identifier: identifier of the linked encounter (store in 'medication-encounter-identifier')
      * Effective date/time: 2026-02-03 (time is arbitrary)
      * Performer: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in 'medication-practitioner-id')
      * Reason for medication: any, either by reference to an ISiKDiagnosis (store ID in 'medication-condition-id') or as code
      * Note: Test note
      * Dosage:
        - Text: any (not empty)
        - Dose: 1 Effervescent tablet
        - Site:
          * Code: 738956005
          * Display: Oral
          * System: http://snomed.info/sct
          * Version: 20251115 (can be configured with the property 'snomed-ct-version')
        - Route:
          * Code: 26643006
          * Display: Oral route
          * System: http://snomed.info/sct
          * Version: 20251115 (can be configured with the property 'snomed-ct-version')
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "MedicationAdministration"

  Scenario: Read and Validate the MedicationAdministration by its ID
    Then Get FHIR resource at "http://fhirserver/MedicationAdministration/${data.medicationadministration-read-id}" with content type "xml"
    And resource has ID "${data.medicationadministration-read-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationsVerabreichung"
    And TGR current response with attribute "$..status.value" matches "completed"
    And TGR current response with attribute "$..note.text.value" matches "Test note"
    And element "medication" references resource with ID "Medication/${data.medication-read-id}" with error message "The referenced medication does not match the expected value"
    And element "subject" references resource with ID "Patient/${data.medication-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "context" references resource with ID "Encounter/${data.medication-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And TGR current response with attribute "$..reasonReference.reference.value" matches "Condition/${data.medication-condition-id}"
    And FHIR current response body evaluates the FHIRPath "context.identifier.value = '${data.medication-encounter-identifier}'" with error message 'The associated encounter identifier does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2026-02-03')" with error message 'The effective date/time does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "performer.where(actor.reference.replaceMatches('/_history/.+','').matches('Practitioner/${data.medication-practitioner-id}$')).exists()" with error message 'The performer does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosage.where(text.empty().not() and site.coding.where(code = '738956005' and system = 'http://snomed.info/sct' and display = 'Oral' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}').exists() and dose.where(code = '1' and system = 'http://unitsofmeasure.org' and unit.hasValue() and value ~ 1).exists() and route.coding.where(code = '26643006' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}' and display = 'Oral route').exists()).exists()" with error message 'The dosage does not match the expected value'
    # Validate the referenced resources at the end -> Tiger performs new Requests
    And referenced "Encounter" resource with id "${data.medication-encounter-id}" conforms to a valid v5 "ISiKKontaktGesundheitseinrichtung" profile
    And referenced "Patient" resource with id "${data.medication-patient-id}" conforms to a valid v5 "ISiKPatient" profile
    And referenced "Practitioner" resource with id "${data.medication-practitioner-id}" conforms to a valid v5 "ISiKPersonImGesundheitsberuf" profile
    And referenced "Medication" resource with id "${data.medication-read-id}" conforms to a valid v5 "ISiKMedikament" profile
    And referenced "Condition" resource with id "${data.medication-condition-id}" conforms to a valid v5 "ISiKDiagnose" profile
