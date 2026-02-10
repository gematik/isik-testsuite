# language: en
@Stufe5
@Basis
@Mandatory
@Encounter-Read-Finished
Feature: Read Information from a resource of type Encounter with status "finished" (@Encounter-Read-Finished)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The Account-Read test case must have been executed successfully beforehand.
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset and the assigned facility-internal admission number must be stored in the configuration variable 'encounter-read-finished-id'.

      Create an Encounter resource with these fields:

      * Admission number: Any (Please, set it in the configuration variable 'encounter-read-finished-identifier-value')
      * Status: finished
      * Type: inpatient (normalstationaer)
      * Patient: the patient from the Account-Read test case
      * Class: IMP
      * Admission reason: referral by a doctor
      * Department: General Surgery
      * Admission reason (first and second level): hospital treatment, fully inpatient
      * Period: 2026-01-06 to 2026-01-08
      * Account: the billing case from the Account-Read test case
      * Account (identifier): the identifier of the linked billing case
      * Location: Room Z001
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Encounter"

  Scenario: Read and Validate finished Encounter by its ID
    When Get FHIR resource at "http://fhirserver/Encounter/${data.encounter-read-finished-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKKontaktGesundheitseinrichtung"
    And resource has ID "${data.encounter-read-finished-id}" with error message "The returned Encounter resource has not the expected ID"
    And TGR current response with attribute "$..status.value" matches "finished"
    And FHIR current response body evaluates the FHIRPath "identifier.where(system = '${data.encounter-read-finished-identifier-system}' and value='${data.encounter-read-finished-identifier-value}').exists()" with error message 'The Encounter does not contain the correct admission number'
    And FHIR current response body evaluates the FHIRPath "class.where(code = 'IMP' and system = 'http://terminology.hl7.org/CodeSystem/v3-ActCode').exists()" with error message 'The Encounter does not contain the correct class code'
    And FHIR current response body evaluates the FHIRPath "type.coding.where(code = 'normalstationaer' and system = 'http://fhir.de/CodeSystem/kontaktart-de').exists()" with error message 'The Encounter does not contain the correct type'
    And FHIR current response body evaluates the FHIRPath "serviceType.coding.where(code = '1500' and system = 'http://fhir.de/CodeSystem/dkgev/Fachabteilungsschluessel').exists()" with error message 'The Encounter does not contain the correct department code'
    And element "subject" references resource with ID "${data.account-read-patient-id}" with error message "The referenced Patient does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "period.start.toString().contains('2026-01-06')" with error message 'The Encounter does not contain a valid start date'
    And FHIR current response body evaluates the FHIRPath "period.end.toString().contains('2026-01-08')" with error message 'The Encounter does not contain a valid end date.'
    And FHIR current response body evaluates the FHIRPath "hospitalization.admitSource.coding.where(code = 'E' and system = 'http://fhir.de/CodeSystem/dgkev/Aufnahmeanlass').exists()" with error message 'The Encounter does not contain the correct admission reason'
    And FHIR current response body evaluates the FHIRPath "extension.where(url = 'http://fhir.de/StructureDefinition/Aufnahmegrund' and extension.where(url = 'ErsteUndZweiteStelle' and value.code = '01' and value.system = 'http://fhir.de/CodeSystem/dkgev/AufnahmegrundErsteUndZweiteStelle').exists()).exists()" with error message 'The encounter does not contain the correct admission reason'
    And element "account" references resource with ID "Account/${data.account-read-id}" with error message "The linked billing case does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "account.identifier.value = '${data.account-read-identifier-value}'" with error message 'The identifier of the linked billing case does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "location.location.identifier.where(system = 'https://test.krankenhaus.de/fhir/sid/zimmerId' and value = 'Z001').exists()" with error message 'The location does not contain the correct code'
