# language: en
@Stufe5
@Medikation
@Mandatory
@MedicationRequest-Read-Extended
Feature: Read Information from a resource of type MedicationRequest with extended data (@MedicationRequest-Read-Extended)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The MedicationRequest-Read test case must have been executed successfully beforehand.
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resources for this test data set must be stored in the configuration variable 'medicationrequest-read-extended-id'.

      Create a MedicationRequest resource in your system with the following values:
      * Id: any (store the ID in the configuration variable 'medicationrequest-read-extended-id')
      * Status: completed
      * Intent: order
      * Medication (ATC):
        * code: R01AA04
        * Display: Phenylephrine
        * System: http://fhir.de/CodeSystem/bfarm/atc
        * Version: any (the value of the configuration variable 'atc-code-version')
      * Extensions:
        * Accepted Risk: Increased feel of dizziness
        * Medication Type: acute (Medikationsart 'akut')
        * Treatment goal: Post therapy improvement of nasal congestion (Behandlungsziel)
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in the configuration variable 'medication-patient-id')
      * Patient identifier: identifier of the linked patient (store the identifier in 'medication-patient-identifier'; used for search tests)
      * Requester: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in the configuration variable 'medication-practitioner-id')
      * Requester identifier: identifier of the requester (store the identifier in 'medication-practitioner-identifier'; used for search tests)
      * Reason Reference: any (the linked Condition resource must conform to ISiKCondition; store the ID in the configuration variable 'medication-condition-id')
      * Dosage Instruction:
         * Timing Repeat: 8 times, for a duration of 8 days, with a frequency of every 1 day and a period of 1 day
         * Dosage Rate Quantity: 500 mL of Infusion solution
    """

  Scenario: Read and Validate the MedicationRequest with extended data by its ID
    Then Get FHIR resource at "http://fhirserver/MedicationRequest/${data.medicationrequest-read-extended-id}" with content type "json"
    And resource has ID "${data.medicationrequest-read-extended-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationsVerordnung"
    And FHIR current response body evaluates the FHIRPath "status = 'completed'" with error message "The expected status does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "intent = 'order'" with error message "The expected intent does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "medication.coding.where(code = 'R01AA04' and system = 'http://fhir.de/CodeSystem/bfarm/atc' and version = '${data.atc-code-version}' and display = 'Phenylephrine').exists()" with error message 'The coded medication does not match the expected value'
    And element "subject" references resource with ID "Patient/${data.medication-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "requester" references resource with ID "Practitioner/${data.medication-practitioner-id}" with error message "The requester does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "reasonReference.where(reference = 'Condition/Condition-Read-Active-Example').exists()" with error message "The expected reason reference has not been found"
    And FHIR current response body evaluates the FHIRPath "extension.where(url = 'https://gematik.de/fhir/isik/StructureDefinition/ExtensionISiKAcceptedRisk').exists()" with error message "The expected ExtensionISiKAcceptedRisk entry has not been found"
    And FHIR current response body evaluates the FHIRPath "extension.where(url = 'https://gematik.de/fhir/isik/StructureDefinition/ExtensionISiKMedikationsart').exists()" with error message "The expected ExtensionISiKMedikationsart entry has not been found"
    And FHIR current response body evaluates the FHIRPath "extension.where(url = 'https://gematik.de/fhir/isik/StructureDefinition/ExtensionISiKBehandlungsziel').exists()" with error message "The expected ExtensionISiKBehandlungsziel entry has not been found"
    And FHIR current response body evaluates the FHIRPath "dosageInstruction.timing.repeat.where(count = 8 and frequency = 1 and duration = 8 and period = 1 and durationUnit = 'd' and periodUnit = 'd').exists()" with error message 'The dosage timing does not match the expected value'
