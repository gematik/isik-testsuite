# language: en
@Stufe5
@Medikation
@Mandatory
@List-Read
Feature: Read Information from a resource of type Medication List (@List-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The MedicationStatement-Read test case must have been executed successfully beforehand.
      - The test data set must have been stored in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'list-read-id'.

      Create a List resource in your system with the following values:
      * Status: current
      * Mode: working
      * Patient: Any (the linked Patient resource must conform to ISiKPatient; store the ID in the configuration variable 'medication-patient-id')
      * Encounter: Any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in the configuration variable 'medication-encounter-id')
      * Date: Any (after 2026-01-01)
      * A single entry with the following information:
        - Item: any (the linked MedicationStatement resource must conform to ISiKMedikationsInformation; store the ID in the configuration variable 'medicationstatement-read-id')
        - Date: Any (after 2026-01-01)
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "List"

  Scenario: Read and Validate the Medication List by its ID
    Then Get FHIR resource at "http://fhirserver/List/${data.list-read-id}" with content type "xml"
    And resource has ID "${data.list-read-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationsListe"
    And TGR current response with attribute "$..status.value" matches "current"
    And TGR current response with attribute "$..mode.value" matches "working"
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = 'medications' and system = 'http://terminology.hl7.org/CodeSystem/list-example-use-codes').exists()" with error message 'The code does not match the expected value'
    And element "encounter" references resource with ID "Encounter/${data.medication-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "subject" references resource with ID "Patient/${data.medication-patient-id}" with error message "The referenced patient does not match the expected value"
    # The requirement for minimal date is used to test date search parameter in the List-Search-date test case
    And FHIR current response body evaluates the FHIRPath "date >= @2026-01-01T00:00:00+01:00" with error message 'The list creation date is not provided'
    And FHIR current response body evaluates the FHIRPath "entry.where(item.reference.replaceMatches('/_history/.+','').matches('MedicationStatement/${data.medicationstatement-read-id}$') and date.empty().not()).exists()" with error message 'The list entry does not match the expected value'
    # Validate the referenced resources at the end -> Tiger performs new Requests
    And referenced "Encounter" resource with id "${data.medication-encounter-id}" conforms to a valid v5 "ISiKKontaktGesundheitseinrichtung" profile
    And referenced "Patient" resource with id "${data.medication-patient-id}" conforms to a valid v5 "ISiKPatient" profile
