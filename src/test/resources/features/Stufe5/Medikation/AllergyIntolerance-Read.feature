# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementGesundheitsstatusRolle
@ISiKCapabilityStatementAMTSRolle
@AllergyIntolerance-Read
Feature: Read Information from a resource of type AllergyIntolerance (@AllergyIntolerance-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'medication-allergyintolerance-read-id'.

      Create an AllergyIntolerance resource in your system, with the following values:

      * ID: a valid Id (can be configured with the property 'medication-allergyintolerance-read-id')
      * Clinical Status Code:
        - Coding:
          * System: http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical
          * Code: active
      * Verification Status Code:
        - Coding:
          * System: http://terminology.hl7.org/CodeSystem/allergyintolerance-verification
          * Code: confirmed
      * Allergy Code:
        - Coding:
          * System: http://snomed.info/sct
          * Code: 256262001
          * Display: Betula pendula pollen
          * Version: 20251115 (can be configured with the property 'snomed-ct-version')
      * Type: must be 'allergy' or 'intolerance'
      * Category: must be one between 'food', 'medication', 'environment', 'biologic'
      * Criticality: must be one between 'low', 'high', 'unable-to-access'
      * Patient: reference to a valid Patient Id (can be configured with the property 'medication-allergyintolerance-read-patient-id')
      * Encounter: reference to a valid Encounter Id (can be configured with the property 'medication-allergyintolerance-read-encounter-id')
      * Recorder: any display value
      * Asserter: any display value
      * Start Date of the Allergy/Intolerance: any
      * Recorded Date: any
      * Note:
        - Author Reference: reference to a valid Person/Role/Organization (can be configured with the property 'medication-allergyintolerance-read-note-author-id')
        - Time: a valid date time
        - Text: any
      * Reaction:
        - Manifestation Coding:
          * System: http://snomed.info/sct
          * Code: 76067001
          * Display: Sneezing (finding)
          * Version: 20251115 (can be configured with the property 'snomed-ct-version')
        - Severity: must be one between 'mild', 'moderate' or 'severe'
        - Exposure Route Coding:
          * System: http://snomed.info/sct
          * Code: 14910006
          * Display: Inspiration
          * Version: 20251115 (can be configured with the property 'snomed-ct-version')
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "AllergyIntolerance"

  Scenario: Read and Validate the AllergyIntolerance by its ID
    When Get FHIR resource at "http://fhirserver/AllergyIntolerance/${data.medication-allergyintolerance-read-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKAllergieUnvertraeglichkeit"
    And resource has ID "${data.medication-allergyintolerance-read-id}" with error message "The ID does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "type = 'allergy' or type = 'intolerance'" with error message "The Type must be allergy or intolerance"
    And FHIR current response body evaluates the FHIRPath "category.where($this = 'food' or $this = 'medication' or $this = 'environment' or $this = 'biologic').exists()" with error message "The Category must be food, medication, environment, or biologic"
    And FHIR current response body evaluates the FHIRPath "criticality.where($this = 'low' or $this = 'high' or $this = 'unable-to-access').exists()" with error message "The Criticality must be low, high, or unable-to-access."
    And FHIR current response body evaluates the FHIRPath "clinicalStatus.coding.where(system = 'http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical' and code = 'active').exists()" with error message "The Clinical status does not have the value 'active'"
    And FHIR current response body evaluates the FHIRPath "verificationStatus.coding.where(system = 'http://terminology.hl7.org/CodeSystem/allergyintolerance-verification' and code = 'confirmed').exists()" with error message "The Verification status does not have the value 'confirmed'"
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = '256262001' and display = 'Betula pendula pollen' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}').exists()" with error message "The Code does not meet the preconditions."
    And FHIR current response body evaluates the FHIRPath "reaction.manifestation.coding.where(code = '76067001' and display = 'Sneezing (finding)' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}').exists()" with error message "The Manifestation Coding does not meet the preconditions."
    And FHIR current response body evaluates the FHIRPath "reaction.exposureRoute.coding.where(code = '14910006' and display = 'Inspiration' and system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}').exists()" with error message "The Exposure Route Coding does not meet the preconditions."
    And FHIR current response body evaluates the FHIRPath "reaction.severity.where($this = 'mild' or $this = 'moderate' or $this = 'severe').exists()" with error message "Reaction Severity must be mild, moderate, or severe."
    And FHIR current response body evaluates the FHIRPath "onset is dateTime" with error message "onsetDateTime is missing"
    And FHIR current response body evaluates the FHIRPath "recordedDate.ofType(dateTime).exists()" with error message "onsetDateTime is missing"
    And FHIR current response body evaluates the FHIRPath "recorder.display.exists()" with error message "Recorder content is missing."
    And FHIR current response body evaluates the FHIRPath "asserter.display.exists()" with error message "Asserter content is missing."
    And FHIR current response body evaluates the FHIRPath "note.text.exists()" with error message "Note text content is missing."
    And FHIR current response body evaluates the FHIRPath "note.time.exists()" with error message "Note time is missing and required."
    And FHIR current response body evaluates the FHIRPath "note.author.reference.exists()" with error message "Note author reference is missing and required."
    And element "patient" references resource with ID "Patient/${data.medication-allergyintolerance-read-patient-id}" with error message "The referenced patient does not match the expected value"
    # Validate the referenced resources at the end -> Tiger performs new Requests
    And referenced "Patient" resource with id "${data.medication-allergyintolerance-read-patient-id}" conforms to a valid v5 "ISiKPatient" profile

