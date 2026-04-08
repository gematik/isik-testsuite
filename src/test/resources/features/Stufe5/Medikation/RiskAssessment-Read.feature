# language: en
@Stufe5
@Medikation
@Mandatory
@RiskAssessment-Read
Feature: Read Information from a resource of type RiskAssessment (@RiskAssessment-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resources for this test data set must be stored in the configuration variable 'riskassessment-read-id'.

      Create a RiskAssessment resource in your system with the following values:
      * Id: any (store the ID in the configuration variable 'riskassessment-read-id')
      * Status: final
      * Condition: any (the linked Condition resource must conform to ISiKDiagnose; store the ID in the configuration variable 'riskassessment-condition-id')
      * Patient: any (the linked Patient resource must conform to ISiKPatient; store the ID in the configuration variable 'riskassessment-patient-id')
      * Encounter: any (the linked Encounter resource must conform to ISiKKontaktGesundheitseinrichtung; store the ID in the configuration variable 'riskassessment-encounter-id')
      * Basis Observation: any of type Body Weight (the linked Observation resource must conform to ISiKKoerpergewicht; store the ID in the configuration variable 'riskassessment-observation-id')
      * Associated encounter identifier: identifier of the linked encounter
      * Requester: any (the linked Practitioner resource must conform to ISiKPersonImGesundheitsberuf; store the ID in the configuration variable 'medication-practitioner-id')
      * Note: Test note
      * Code: any text (not empty)
      * Text with status "additional" and div element with any content (not empty)
      * Occurrence Date Time: 2026-01-06
      * Prediction:
        - Outcome: any text (not empty)
        - Quantitative risk: high
      * Mitigation: any text (not empty)
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "RiskAssessment"

  Scenario: Read and Validate the RiskAssessment by its ID
    Then Get FHIR resource at "http://fhirserver/RiskAssessment/${data.riskassessment-read-id}" with content type "xml"
    And resource has ID "${data.riskassessment-read-id}"
    #And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKAMTSBewertung"
    And TGR current response with attribute "$..status.value" matches "final"
    And FHIR current response body evaluates the FHIRPath "note.text.empty().not()" with error message 'The note element is missing or empty'
    And element "condition" references resource with ID "Condition/${data.riskassessment-condition-id}" with error message "The referenced condition does not match the expected value"
    And element "subject" references resource with ID "Patient/${data.riskassessment-patient-id}" with error message "The referenced patient does not match the expected value"
    And element "encounter" references resource with ID "Encounter/${data.riskassessment-encounter-id}" with error message "The referenced encounter does not match the expected value"
    And element "basis" references resource with ID "Observation/${data.riskassessment-observation-id}" with error message "The referenced observation does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "occurrence.ofType(dateTime).toString().contains('2026-01-06')" with error message 'The occurrence date does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "text.where(status = 'additional' and div.hasValue()).exists()" with error message 'The expected additional text has not been found'
    And FHIR current response body evaluates the FHIRPath "note.text.empty().not()" with error message 'The note element is missing or empty'
    And FHIR current response body evaluates the FHIRPath "mitigation.empty().not()" with error message 'The expected mitigation description has not been found'
    And FHIR current response body evaluates the FHIRPath "code.text.empty().not()" with error message 'The expected code description has not been found'
    # Validate the referenced resources at the end -> Tiger performs new Requests
    And referenced "Encounter" resource with id "${data.riskassessment-encounter-id}" conforms to a valid v5 "ISiKKontaktGesundheitseinrichtung" profile
    And referenced "Patient" resource with id "${data.riskassessment-patient-id}" conforms to a valid v5 "ISiKPatient" profile
    And referenced "Observation" resource with id "${data.riskassessment-observation-id}" conforms to a valid v5 "ISiKKoerpergewicht" profile
    And referenced "Condition" resource with id "${data.riskassessment-condition-id}" conforms to a valid v5 "ISiKDiagnose" profile