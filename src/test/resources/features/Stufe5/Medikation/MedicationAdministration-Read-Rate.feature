# language: en
@Stufe5
@Medikation
@Mandatory
@MedicationAdministration-Read-Rate
Feature: Read Information from a resource of type MedicationAdministration (Rate) (@MedicationAdministration-Read-Rate)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The Medication-Read test case must have been executed successfully beforehand.
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resources for this test data set must be stored in the configuration variable 'medicationadministration-read-rate-id'.
      
      Create a MedicationAdministration resource in your system with the following values:
      * Status: completed
      * Referenced medication: the medication from test case Medication-Read
      * Dosage:
        - Text: any (not empty)
        - Dose: 1000mL in total
        - Rate Quantity: 50 mL/h
        - Site:
          * Code: 6073002
          * Display: Structure of ligament of left superior vena cava
          * System: http://snomed.info/sct
          * Version: 20251115 (can be configured with the property 'snomed-ct-version')
        - Route:
          * Code: 255560000
          * Display: Intravenous
          * System: http://snomed.info/sct
          * Version: 20251115 (can be configured with the property 'snomed-ct-version')
    """

  Scenario: Read and Validate the MedicationAdministration with rate details by ID
    Then Get FHIR resource at "http://fhirserver/MedicationAdministration/${data.medicationadministration-read-rate-id}" with content type "xml"
    And resource has ID "${data.medicationadministration-read-rate-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationsVerabreichung"
    And FHIR current response body evaluates the FHIRPath "dosage.text.empty().not()" with error message 'The dosage text is not specified'
    And FHIR current response body evaluates the FHIRPath "dosage.site.coding.where(code = '6073002' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}' and display.empty().not()).exists()" with error message "The dosage site does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "dosage.route.coding.where(code = '255560000' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}' and display.empty().not()).exists()" with error message "The dosage route does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "dosage.dose.code = 'mL' and dosage.dose.system = 'http://unitsofmeasure.org' and dosage.dose.unit.hasValue() and dosage.dose.value ~ 1000" with error message "The total dose does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "(dosage.rate.is(Quantity) and (dosage.rate.code = 'mL/h' and dosage.rate.system = 'http://unitsofmeasure.org' and dosage.rate.unit.hasValue() and dosage.rate.value ~ 50 ) ) or ( dosage.rate.is(Ratio) and ( dosage.rate.numerator.value ~ 50 and dosage.rate.numerator.unit.hasValue() and dosage.rate.numerator.code = 'mL' and dosage.rate.numerator.system = 'http://unitsofmeasure.org' and dosage.rate.denominator.value ~ 1 and dosage.rate.denominator.unit.hasValue() and dosage.rate.denominator.code = 'h' and dosage.rate.denominator.system = 'http://unitsofmeasure.org') )" with error message "The administration rate does not match the expected value"
