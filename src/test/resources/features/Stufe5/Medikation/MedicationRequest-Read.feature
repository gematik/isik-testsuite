# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementMedikationVerordnungRolle
@MedicationRequest-Read
Feature: Read Information from a resource of type MedicationRequest (@MedicationRequest-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The Medication-Read test case must have been executed successfully beforehand.
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resources for this test data set must be stored in the configuration variable 'medicationrequest-read-id'.

      Create a MedicationRequest resource in your system with the following values:
      * Id: any (store the ID in the configuration variable 'medicationrequest-read-id')
      * Status: completed
      * Intent: order
      * Referenced medication: an ISiKMedication resource with ATC code V03AB23 (store the ID in the configuration variable 'medicationrequest-medication-id')
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in the configuration variable 'medication-patient-id')
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in the configuration variable 'medication-encounter-id')
      * Associated encounter identifier: identifier of the linked encounter
      * Authored date: 2026-02-03
      * Requester: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in the configuration variable 'medication-practitioner-id')
      * Note: Test note
      * Dosage Instruction:
        - Text: any (not empty)
        - Patient instruction: any (not empty)
        - Dose: 1 Infusion solution
        - Site:
          * Code: 738956005
          * Display: Oral
          * System: http://snomed.info/sct
          * Version: 20251115 (can be configured with the property 'snomed-ct-version')
        - Timing:
           * Repeat on: morning, noon and evening
           * Event Dates: 2026-02-03, 2026-02-04, 2026-02-05
      * Dispense quantity requested: 20 Infusion solutions
      * Substitution allowed: Yes
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "MedicationRequest"

  Scenario: Read and Validate the MedicationRequest by its ID
    Then Get FHIR resource at "http://fhirserver/MedicationRequest/${medikation.medicationrequest-read-id}" with content type "xml"
    And resource has ID "${medikation.medicationrequest-read-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationsVerordnung"
    And TGR current response with attribute "$..status.value" matches "completed"
    And TGR current response with attribute "$..intent.value" matches "order"
    And FHIR current response body evaluates the FHIRPath "note.text.empty().not()" with error message 'The note element is missing or empty'
    And element "medication" references resource with ID "Medication/${medikation.medicationrequest-medication-id}" with error message "The referenced medication does not match the expected value"
    And element "subject" references resource with ID "Patient/${medikation.medication-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${medikation.medication-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "encounter.identifier.value = '${medikation.medication-encounter-identifier-value}'" with error message 'The associated encounter identifier does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "authoredOn.toString().contains('2026-02-03')" with error message 'The authored date does not match the expected value'
    And element "requester" references resource with ID "Practitioner/${medikation.medication-practitioner-id}" with error message "The requester does not match the expected value"
    # The following assertions enable both single and multiple dosage-elements to be used in order to encode repeated application
    And FHIR current response body evaluates the FHIRPath "dosageInstruction.all(site.coding.where(code = '738956005' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${medikation.snomed-ct-version}' and display = 'Oral'))" with error message 'The administration site does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosageInstruction.all(text.empty().not())" with error message 'The free-text dosage instructions does not contain any text'
    And FHIR current response body evaluates the FHIRPath "dosageInstruction.all(patientInstruction.empty().not())" with error message 'The patient instruction does not contain any text'
    And FHIR current response body evaluates the FHIRPath "dosageInstruction.all(doseAndRate.dose.where(value ~ 1 and unit.empty().not() and system = 'http://unitsofmeasure.org' and code ='1').exists())" with error message 'Dose and rate information does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "(dosageInstruction.timing.repeat.when contains 'MORN') and (dosageInstruction.timing.repeat.when contains 'NOON') and (dosageInstruction.timing.repeat.when contains 'EVE')" with error message 'Timing repeat information does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosageInstruction.timing.event.empty().not()" with error message 'Timing event information has not been provided'
    And FHIR current response body evaluates the FHIRPath "dispenseRequest.quantity.where(value ~ 20 and unit.empty().not() and system = 'http://unitsofmeasure.org' and code = '1').exists()" with error message 'The requested dispense quantity does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "substitution.allowed.value = true"
    # Validate the referenced resources at the end -> Tiger performs new Requests
    And referenced "Encounter" resource with id "${medikation.medication-encounter-id}" conforms to a valid v5 "ISiKKontaktGesundheitseinrichtung" profile
    And referenced "Patient" resource with id "${medikation.medication-patient-id}" conforms to a valid v5 "ISiKPatient" profile
    And referenced "Practitioner" resource with id "${medikation.medication-practitioner-id}" conforms to a valid v5 "ISiKPersonImGesundheitsberuf" profile
    And referenced "Medication" resource with id "${medikation.medication-read-id}" conforms to a valid v5 "ISiKMedikament" profile