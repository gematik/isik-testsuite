# language: en
@Stufe5
@Medikation
@Mandatory
@MedicationStatement-Read-Extended
Feature: Read Information from a resource of type MedicationStatement with extended data (@MedicationStatement-Read-Extended)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The ID of the corresponding FHIR resources for this test data set must be stored in the configuration variable 'medicationstatement-read-extended-id'.

      Create a MedicationStatement resource in your system with the following values:
      * Id: any (store the ID in 'medicationstatement-read-extended-id')
      * Status: active
      * Medication (ATC coded with display value): Acetylcystein
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in 'medication-patient-id')
      * Patient identifier: identifier of the linked patient (store in 'medication-patient-identifier'; used for search tests)
      * Effective date: 2026-03-05
      * Reason for medication: any SNOMED CT coded diagnosis
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in the configuration variable 'medication-encounter-id')
      * Associated encounter identifier: identifier of the linked encounter (store in 'medication-encounter-identifier'; used for search tests)
      * Dosage timing repeat: after meal
      * Dosage frequency: 2-3 times per day
      * As-needed medication: no
      * Dosage site:
        * Code: 738956005
        * Display: Oral
        * System: http://snomed.info/sct
        * Version: 20251115 (can be configured with the property 'snomed-ct-version')
      * Dosage route:
        * Code: 26643006
        * Display: Oral route
        * System: http://snomed.info/sct
        * Version: 20251115 (can be configured with the property 'snomed-ct-version')
      * Maximum dose per period: 600mg/day
      * Maximum dose per administration: 200mg
    """

  Scenario: Read and Validate the MedicationStatement with extended data by its ID
    Then Get FHIR resource at "http://fhirserver/MedicationStatement/${data.medicationstatement-read-extended-id}" with content type "xml"
    And resource has ID "${data.medicationstatement-read-extended-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationsInformation"
    And TGR current response with attribute "$..status.value" matches "active"
    And FHIR current response body evaluates the FHIRPath "medication.coding.where(code = 'V03AB23' and system = 'http://fhir.de/CodeSystem/bfarm/atc' and display = 'Acetylcystein' and version = '${data.atc-code-version}').exists()" with error message 'The coded medication does not match the expected value'
    And element "subject" references resource with ID "Patient/${data.medication-patient-id}" with error message "The referenced patient does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2026-03-05')" with error message 'The effective date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "reasonCode.coding.where(code.empty().not() and system.empty().not() and display.empty().not()).exists()" with error message 'The reason for medication is not specified correctly'
    And FHIR current response body evaluates the FHIRPath "dosage.first().timing.repeat.when = 'PC'" with error message 'The dosage repeat value does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosage.first().timing.repeat.frequency = 2 and dosage.first().timing.repeat.frequencyMax = 3 and dosage.first().timing.repeat.period = 1 and dosage.first().timing.repeat.periodUnit = 'd'" with error message 'The dosage frequency does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosage.first().asNeeded = false" with error message 'The as-needed value does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosage.first().site.coding.where(system='http://snomed.info/sct' and code='738956005' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The dosage site does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosage.first().route.coding.where(system='http://snomed.info/sct' and code='26643006' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}' and display.empty().not()).exists()" with error message 'The dosage route does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosage.first().maxDosePerPeriod.numerator.value ~ 600 and dosage.first().maxDosePerPeriod.numerator.system = 'http://unitsofmeasure.org' and dosage.first().maxDosePerPeriod.numerator.code = 'mg' and dosage.first().maxDosePerPeriod.numerator.unit.hasValue() and dosage.first().maxDosePerPeriod.denominator.value ~ 1 and dosage.first().maxDosePerPeriod.denominator.system = 'http://unitsofmeasure.org' and dosage.first().maxDosePerPeriod.denominator.code = 'd' and dosage.first().maxDosePerPeriod.denominator.unit.hasValue()" with error message 'The maximum dose per period does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "dosage.first().maxDosePerAdministration.value ~ 200 and dosage.first().maxDosePerAdministration.system = 'http://unitsofmeasure.org' and dosage.first().maxDosePerAdministration.code = 'mg' and dosage.first().maxDosePerAdministration.unit.hasValue()" with error message 'The maximum dose per administration does not match the expected value'
    # Validate the referenced resources at the end -> Tiger performs new Requests
    And referenced "Encounter" resource with id "${data.medication-encounter-id}" conforms to a valid v5 "ISiKKontaktGesundheitseinrichtung" profile
    And referenced "Patient" resource with id "${data.medication-patient-id}" conforms to a valid v5 "ISiKPatient" profile