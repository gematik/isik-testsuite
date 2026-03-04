# language: en
@Stufe5
@Dokumentenaustausch
@Mandatory
@DocumentReference-Read
Feature: Read information from a resource of type DocumentReference (@DocumentReference-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset must be stored in the configuration variable 'documentreference-read-id'.
      - A valid Patient resource (conform to ISiKPatient) must exist in the system under test, and its ID must be stored in the configuration variable 'documentreference-read-patient-id'.
      - A valid Encounter resource (conform to ISIKKontaktGesundheitseinrichtung) must exist in the system under test, and its ID must be stored in the configuration variable 'documentreference-read-encounter-id'.
      - A valid Binary PDF resource (conform to ISIKBinary) must exist in the system under test, and its ID must be stored in the configuration variable 'documentreference-read-binary-id'.
      - A valid DocumentReference resource that is referenced as "replaces" must exist in the system under test, and its ID must be stored in the configuration variable 'documentreference-read-replaces-id'.

      Create the following DocumentReference Resource in your system:

      * Master Identifier of the document:
        - Value: defaults to urn:oid:1.2.840.113556.1.8000.2554.58783.21864.3474.19410.44358.58254.41281.46340, can be customised with variable 'documentreference-read-masteridentifier-value'
        - System: defaults to urn:ietf:rfc:3986, can be customised with the variable 'documentreference-read-masteridentifier-system'
      * External identifier:
        - Value: defaults to 129.6.58.42.33726, can be customised with the variable 'documentreference-read-externalidentifier-value'
        - System: defaults to urn:uuid:96fdda7c-d067-4183-912e-bf5ee74998a8, can be customised with the variable 'documentreference-read-externalidentifier-system'
      * Status: current
      * Document Processing status: final
      * Document Category:
        - Code: DOK
        - Display: Dokumente ohne besondere Form (Notizen)
      * Document type (KDL):
         - Code: VL160105
         - Display: Pflegebericht
      * Document type (XDS):
         - Code: PFLG
         - Display: Pflegedokumentation
      * Author: Maxine Mustermann
      * Relationship to other documents: This document replaces another document (the linked DocumentReference resource must be stored in the configuration variable 'documentreference-read-replaces-id' and referenced in relatesTo.target.reference)
      * Confidentiality: normal
      * Content Attachment:
        - Language: German
        - Type of Document: PDF
        - Creation Date: 2026-01-31T14:50:50+01:00
        - Title: Pflegebericht vom 31.01.26
        - URL: reference to a Binary PDF resource (the ID of the corresponding FHIR resource must be stored in the configuration variable 'documentreference-read-binary-id')
      * Content Format:
        - Code: urn:ihe:iti:xds:2017:mimeTypeSufficient
        - Display: mimeType Sufficient
      * Context:
        - Facility: Hospital
          - Code: KHS
          - Display: Krankenhaus
        - Clinical Specialty: ALLG
        - Event:
          - Code: E100
          - Display: ambulanter Kontakt
          - System: http://ihe-d.de/CodeSystems/FallkontextBeiDokumentenerstellung
        - Encounter: reference to an Encounter resource (the ID of the corresponding FHIR resource must be stored in the configuration variable 'documentreference-read-encounter-id')
      * Patient reference: reference to a Patient resource (the ID of the corresponding FHIR resource must be stored in the configuration variable 'documentreference-read-patient-id')
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "DocumentReference"

  Scenario: Read document metadata by ID
    When Get FHIR resource at "http://fhirserver/DocumentReference/${data.documentreference-read-id}" with content type "json"
    And resource has ID "${data.documentreference-read-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKDokumentenMetadaten"
    And FHIR current response body evaluates the FHIRPath "masterIdentifier.where(system = '${data.documentreference-read-masteridentifier-system}' and value = '${data.documentreference-read-masteridentifier-value}').exists()" with error message 'The version-specific OID of the document does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "identifier.where(system = '${data.documentreference-read-externalidentifier-system}' and value = '${data.documentreference-read-externalidentifier-value}').exists()" with error message 'The identifier does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "status = 'current'" with error message 'The document metadata status does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "docStatus = 'final'" with error message 'The document processing status does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "type.coding.where(system = 'http://dvmd.de/fhir/CodeSystem/kdl' and code = 'VL160105' and display = 'Pflegebericht').exists()" with error message 'The document type (KDL) code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "type.coding.where(system = 'http://ihe-d.de/CodeSystems/IHEXDStypeCode' and code = 'PFLG' and display = 'Pflegedokumentation').exists()" with error message 'The document type (XDS) code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "author.display.contains('Maxine Mustermann')" with error message 'The document author does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "relatesTo.where(code = 'replaces' and target.reference.exists()).exists()" with error message 'The relationship to the replaced document does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "securityLabel.coding.where(code = 'N' and system = 'http://terminology.hl7.org/CodeSystem/v3-Confidentiality').exists()" with error message 'The confidentiality does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "content.where(attachment.where(contentType = 'application/pdf' and (language = 'de' or language.startsWith('de-')) and url.exists() and creation = @2026-01-31T14:50:50+01:00).exists() and format.where(code = 'urn:ihe:iti:xds:2017:mimeTypeSufficient' and system = 'http://ihe.net/fhir/ihe.formatcode.fhir/CodeSystem/formatcode').exists()).exists()" with error message 'The attachment does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "content.attachment.url.contains('Binary/${data.documentreference-read-binary-id}')" with error message 'The Binary reference does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "context.where(facilityType.coding.where(code = 'KHS' and system = 'http://ihe-d.de/CodeSystems/PatientBezogenenGesundheitsversorgung').exists() and practiceSetting.where(coding.where(code = 'ALLG' and system = 'http://ihe-d.de/CodeSystems/AerztlicheFachrichtungen').exists()).exists()).exists()" with error message 'The context Facility and Specialty does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "context.where(event.coding.where(code = 'E100' and system = 'http://ihe-d.de/CodeSystems/FallkontextBeiDokumentenerstellung' and display = 'ambulanter Kontakt').exists()).exists()" with error message 'The context Event does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'DOK' and system = 'http://ihe-d.de/CodeSystems/IHEXDSclassCode' and display = 'Dokumente ohne besondere Form (Notizen)').exists()" with error message 'The document class does not match the expected value'
    And element "subject" references resource with ID "${data.documentreference-read-patient-id}" with error message "The reference to Patient does not match the expected value"
    And element "context.encounter" references resource with ID "${data.documentreference-read-encounter-id}" with error message "The reference to Encounter does not match the expected value"
    And referenced "Encounter" resource with id "${data.documentreference-read-encounter-id}" conforms to a valid v5 "ISiKKontaktGesundheitseinrichtung" profile
    And referenced "Patient" resource with id "${data.documentreference-read-patient-id}" conforms to a valid v5 "ISiKPatient" profile

  Scenario: Read the Binary resource referenced in the DocumentReference resource
    When Get FHIR resource at "http://fhirserver/Binary/${data.documentreference-read-binary-id}" with content type "json"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKBinary"
    And resource has ID "${data.documentreference-read-binary-id}" with error message "The Binary ID does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "contentType.value = 'application/pdf'" with error message 'The content type does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "data.value.empty().not()" with error message 'The data value does not match the expected value'
