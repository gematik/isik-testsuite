# language: en
@Stufe5
@Medikation
@Mandatory
@MedicationStatement-Read
Feature: Read Information from a resource of type MedicationStatement (@MedicationStatement-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The Medication-Read test case must have been executed successfully beforehand.
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'medicationstatement-read-id'.

      Create a MedicationStatement resource in your system with the following values:
      * Id: any (store the ID in 'medicationstatement-read-id')
      * Status: active
      * Referenced medication: the medication from test case Medication-Read
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in 'medication-patient-id')
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in 'medication-encounter-id')
      * Period: 2026-02-03
      * Date asserted: 2026-02-27
      * Reason for medication: any, either as reference to an ISiKDiagnosis (store ID in 'medication-condition-id') or as code
      * Note: any (not empty)
      * Dosage:
        - Text: any (not empty)
        - Patient instruction: any (not empty)
        - Timing: morning, noon, evening
        - Quantity: 1 tablet per day
        - Timing: Repeat on morning, noon and evening
      * Dosage (free-text instruction): any (not empty)
      * Dosage (patient instruction): any (not empty)
      * Dosage (timing): morning, noon, evening
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "MedicationStatement"

  Scenario: Read and Validate the MedicationStatement by its ID
    Then Get FHIR resource at "http://fhirserver/MedicationStatement/${data.medicationstatement-read-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationsInformation"
    And resource has ID "${data.medicationstatement-read-id}"
    And TGR current response with attribute "$..status.value" matches "active"
    And FHIR current response body evaluates the FHIRPath "note.text.empty().not()" with error message 'The note does not contain any value'
    And FHIR current response body evaluates the FHIRPath "effective.start.toString().contains('2026-02-03')" with error message 'The period does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dateAsserted.toString().contains('2026-02-27')" with error message 'The date asserted does not match the expected value'
    # The following assertions enable both single and multiple dosage-elements to be used in order to encode repeated application
    And FHIR current response body evaluates the FHIRPath "dosage.all(text.empty().not())" with error message 'The free-text dosage instructions do not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosage.all(patientInstruction.empty().not())" with error message 'Patient instructions do not contain any value'
    And FHIR current response body evaluates the FHIRPath "dosage.all(doseAndRate.dose.where(value ~ 1 and unit.empty().not() and system = 'http://unitsofmeasure.org' and code ='1').exists())" with error message 'Dose and rate information does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "(dosage.timing.repeat.when contains 'MORN') and (dosage.timing.repeat.when contains 'NOON') and (dosage.timing.repeat.when contains 'EVE')" with error message 'Timing repeat information does not match the expected value'
    And element "medication" references resource with ID "Medication/${data.medication-read-id}" with error message "The referenced medication does not match the expected value"
    And element "subject" references resource with ID "Patient/${data.medication-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "context" references resource with ID "Encounter/${data.medication-encounter-id}" with error message "The referenced encounter does not match the expected value"
    # Validate the referenced resources at the end -> Tiger performs new Requests
    And referenced "Encounter" resource with id "${data.medication-encounter-id}" conforms to a valid v5 "ISiKKontaktGesundheitseinrichtung" profile
    And referenced "Patient" resource with id "${data.medication-patient-id}" conforms to a valid v5 "ISiKPatient" profile
    And referenced "Condition" resource with id "${data.medication-condition-id}" conforms to a valid v5 "ISiKDiagnose" profile
    And referenced "Medication" resource with id "${data.medication-read-id}" conforms to a valid v5 "ISiKMedikament" profile