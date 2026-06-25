# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementGesundheitsstatusRolle
@Observation-Expected-Pregnancy-Delivery-Date-Read
Feature: Read information from a resource of type Observation for the expected pregnancy delivery date (@Observation-Expected-Pregnancy-Delivery-Date-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset must be stored in the configuration variable 'medication-observation-expected-pregnancy-delivery-date-read-id'.

      Create an Observation resource with these fields:
      * Id: the value of the configuration variable 'medication-observation-expected-pregnancy-delivery-date-read-id'
      * Profile: ISiKSchwangerschaftErwarteterEntbindungstermin
      * Status: final
      * Code:
        - Coding:
          * System: http://loinc.org
          * Code: 11779-6
          * Display: Delivery date Estimated from last menstrual period
          * Version: 2.81 (can be configured with the property 'loinc-version')
      * Patient: Patient from the Patient-Read-Extended test case
      * Performer: Practitioner from the Practitioner-Read test case
      * Encounter: Encounter from the Encounter-Read-In-Progress test case
      * Effective date/time: 2026-01-06
      * Value date/time: 2026-01-06
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Observation"

  Scenario: Read and Validate expected pregnancy delivery date Observation by its ID
    When Get FHIR resource at "http://fhirserver/Observation/${data.medication-observation-expected-pregnancy-delivery-date-read-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKSchwangerschaftErwarteterEntbindungstermin"
    And resource has ID "${data.medication-observation-expected-pregnancy-delivery-date-read-id}" with error message "The ID does not match the expected value"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "code.coding.where(system = 'http://loinc.org' and code = '11779-6' and version = '${data.loinc-version}' and display.empty().not()).exists()" with error message 'The LOINC code for the expected pregnancy delivery date does not match the expected value'
    And element "subject" references resource with ID "Patient/${data.patient-read-extended-id}" with error message "The referenced patient does not match the expected value"
    And element "performer" references resource with ID "Practitioner/${data.practitioner-read-id}" with error message "The referenced performer does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${data.encounter-read-in-progress-id}" with error message "The referenced encounter does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "effective.toString().contains('2026-01-06')" with error message 'The effective date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "value.toString().contains('2026-01-06')" with error message 'The expected pregnancy delivery date value does not match the expected value'
