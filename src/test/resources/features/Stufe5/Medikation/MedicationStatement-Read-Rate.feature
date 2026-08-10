# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementMedikationInformationRolle
@MedicationStatement-Read-Rate
Feature: Read Information from a resource of type MedicationStatement with Rate data (@MedicationStatement-Read-Rate)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'medicationstatement-read-rate-id'.

      Create a MedicationStatement resource in your system with the following values:
      * Id: any (store the ID in 'medicationstatement-read-rate-id')
      * Status: active
      * Referenced medication: any medication that can be administered with a rate
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in 'medication-patient-id')
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in 'medication-encounter-id')
      * Effective date: 2022-07-01
      * Dosage (text): any (not empty)
      * Dosage:
        * Quantity: 1000ml
        * Timing: Repeat on morning, noon and evening
      * Dosage site:
        * Code: 6073002
        * Display: Structure of ligament of left superior vena cava
        * System: http://snomed.info/sct
        * Version: 20251115 (can be configured with the property 'snomed-ct-version')
      * Dosage route:
        * Code: 255560000
        * Display: Intravenous
        * System: http://snomed.info/sct
        * Version: 20251115 (can be configured with the property 'snomed-ct-version')
      * Dosage rate: 50 ml/h
    """

  Scenario: Read and Validate the MedicationStatement with Rate data by its ID
    Then Get FHIR resource at "http://fhirserver/MedicationStatement/${medikation.medicationstatement-read-rate-id}" with content type "xml"
    And resource has ID "${medikation.medicationstatement-read-rate-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationsInformation"
    And TGR current response with attribute "$..status.value" matches "active"
    And FHIR current response body evaluates the FHIRPath "dosage.where(text.empty().not() and doseAndRate.dose.where(code = 'mL' and system = 'http://unitsofmeasure.org' and unit.hasValue() and value ~ 1000).exists()).exists()" with error message 'The dosage does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "(dosage.timing.repeat.when contains 'MORN') and (dosage.timing.repeat.when contains 'NOON') and (dosage.timing.repeat.when contains 'EVE')" with error message 'Timing repeat information does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosage.doseAndRate.rate.numerator.where(value ~ 50 and unit.hasValue() and code = 'mL' and system = 'http://unitsofmeasure.org').exists() and dosage.doseAndRate.rate.denominator.where(value ~ 1 and unit = 'h' and code = 'h' and system = 'http://unitsofmeasure.org').exists()" with error message 'The rate does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosage.route.coding.where(system='http://snomed.info/sct' and code='255560000' and version = 'http://snomed.info/sct/11000274103/version/${medikation.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The route does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosage.site.coding.where(code = '6073002' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${medikation.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The administration site does not match the expected value'
