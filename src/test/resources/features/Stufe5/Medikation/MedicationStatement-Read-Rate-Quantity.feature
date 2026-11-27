# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementMedikationInformationRolle
@MedicationStatement-Read-Rate-Quantity
Feature: Read a MedicationStatement with a rate quantity (@MedicationStatement-Read-Rate-Quantity)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'medicationstatement-read-rate-quantity-id'.

      Create a MedicationStatement resource in your system with the following values:
      * Id: the value of the configuration variable 'medicationstatement-read-rate-quantity-id'
      * Status: active
      * Referenced medication: any medication that can be administered with a rate
      * Patient: store the ID in 'medication-patient-id'
      * Encounter: store the ID in 'medication-encounter-id'
      * Effective date: 2026-03-05
      * Dosage text: any (not empty)
      * Dose: 1000 mL
      * Timing: repeat on morning, noon and evening
      * Dosage site:
        - Code: 6073002
        - Display: Structure of ligament of left superior vena cava
        - System: http://snomed.info/sct
        - Version: 20251115 (configured with 'snomed-ct-version')
      * Dosage route:
        - Code: 47625008
        - Display: Intravenous route
        - System: http://snomed.info/sct
        - Version: 20251115 (configured with 'snomed-ct-version')
      * Dosage rate quantity: 50 mL/h
    """

  Scenario: Read and Validate the MedicationStatement with Rate Quantity by its ID
    Then Get FHIR resource at "http://fhirserver/MedicationStatement/${medikation.medicationstatement-read-rate-quantity-id}" with content type "xml"
    And resource has ID "${medikation.medicationstatement-read-rate-quantity-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationsInformation"
    And TGR current response with attribute "$..status.value" matches "active"
    And FHIR current response body evaluates the FHIRPath "dosage.where(text.empty().not() and doseAndRate.dose.where(code = 'mL' and system = 'http://unitsofmeasure.org' and unit.hasValue() and value ~ 1000).exists()).exists()" with error message 'The dosage does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "(dosage.timing.repeat.when contains 'MORN') and (dosage.timing.repeat.when contains 'NOON') and (dosage.timing.repeat.when contains 'EVE')" with error message 'Timing repeat information does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosage.doseAndRate.rate.ofType(Quantity).where(value ~ 50 and unit = 'mL/h' and code = 'mL/h' and system = 'http://unitsofmeasure.org').exists()" with error message 'The rate quantity does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosage.route.coding.where(system='http://snomed.info/sct' and code='47625008' and version = 'http://snomed.info/sct/11000274103/version/${medikation.snomed-ct-version}' and display = 'Intravenous route').exists()" with error message 'The route does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosage.site.coding.where(code = '6073002' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${medikation.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The administration site does not match the expected value'
