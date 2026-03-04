# language: en
@Stufe5
@Dokumentenaustausch
@Mandatory
@DocumentReference-Post
Feature: Upload of a DocumentReference with POST Operation (Dokumentenbereitstellung) (@DocumentReference-Post)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST be able to resolve the Patient and Encounter referenced in the DocumentReference. The embedded document MUST be extracted, persisted separately, and made available via the Binary endpoint of the API."
    Given the Preconditions:
      """
      This set of tests assumes that the system under test supports the create interaction for the DocumentReference resource.
      The test dataset must be entered in the system under test according to the specifications (manually).

      The following values from the configuration file must be used in the resource to be created:
       - The masterIdentifier value to be used (variable name: 'documentreference-post-master-identifier-value')
       - The reference to a valid Encounter resource ID (variable name: 'documentreference-read-encounter-id')
       - The reference to a valid Patient resource ID to be used (variable name: 'documentreference-read-patient-id')
      """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "create" for resource "DocumentReference"

  Scenario: POST a DocumentBundle with known patient and encounter
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send POST request to "http://fhirserver/DocumentReference" with body "!{file('src/test/resources/features/Stufe5/Dokumentenaustausch/fixtures/DocumentReference-Post-Correct.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "20\d"
    # Caution! The following checks assume that a representation of the new resource has been returned directly in the response. This is guaranteed by the createOperation which sends the header 'Prefer: return=representation' internally.
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKDokumentenMetadaten"
    And FHIR current response body evaluates the FHIRPath "masterIdentifier.where(system = 'urn:ietf:rfc:3986' and value = '${data.documentreference-post-master-identifier-value}').exists()" with error message 'The version-specific OID of the document does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "identifier.where(system = 'urn:uuid:96fdda7c-d067-4183-912e-bf5ee74998a8' and value = '129.6.58.42.11111').exists()" with error message 'The identifier does not match the expected value'
    And TGR current response with attribute "$.body.status.content" matches "current"
    And TGR current response with attribute "$.body.docStatus.content" matches "final"
    And FHIR current response body evaluates the FHIRPath "content.attachment.title = 'Molekularpathologiebefund vom 12.02.26'" with error message 'The document title does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "type.coding.where(system = 'http://dvmd.de/fhir/CodeSystem/kdl' and code = 'PT130102' and display = 'Molekularpathologiebefund').exists()" with error message 'The document type (KDL) code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "type.coding.where(system = 'http://ihe-d.de/CodeSystems/IHEXDStypeCode' and code = 'PATH' and display = 'Pathologiebefundberichte').exists()" with error message 'The document type (XDS) code does not match the expected value'
    And element "subject" references resource with ID "${data.documentreference-read-patient-id}" with error message "The patient reference does not match the expected value"
    And element "context.encounter" references resource with ID "${data.documentreference-read-encounter-id}" with error message "The patient reference does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "author.display.contains('Harold Hippocrates')" with error message 'The document author does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "securityLabel.coding.where(code = 'N' and system = 'http://terminology.hl7.org/CodeSystem/v3-Confidentiality').exists()" with error message 'The confidentiality does not match the expected value'
    # The originally POSTed resource contained a creation datetime with another time zone. We use date equality function, which takes care of time conversion issues depending on the time zone.
    And FHIR current response body evaluates the FHIRPath "content.where(attachment.where(contentType = 'application/pdf' and (language = 'de' or language.startsWith('de-')) and url.exists() and data.exists().not() and creation = @2026-02-12T12:50:50+01:00).exists() and format.where(code = 'urn:ihe:iti:xds:2017:mimeTypeSufficient' and system = 'http://ihe.net/fhir/ihe.formatcode.fhir/CodeSystem/formatcode').exists()).exists()" with error message 'The attachment does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "context.where(facilityType.coding.where(code = 'KHS' and system = 'http://ihe-d.de/CodeSystems/PatientBezogenenGesundheitsversorgung').exists() and practiceSetting.where(coding.where(code = 'ALLG' and system = 'http://ihe-d.de/CodeSystems/AerztlicheFachrichtungen').exists()).exists()).exists()" with error message 'The context does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "category.coding.where(code = 'BEF' and system = 'http://ihe-d.de/CodeSystems/IHEXDSclassCode' and display = 'Befundbericht').exists()" with error message 'The document class does not match the expected value'

  Scenario Outline: POST an incorrect DocumentBundle
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send POST request to "http://fhirserver/DocumentReference" with body "!{file('src/test/resources/features/Stufe5/Dokumentenaustausch/fixtures/<inputFile>')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "<responseCode>"
    And FHIR current response body evaluates the FHIRPath "issue.where(severity = 'error' or 'fatal').count() >= 1" with error message 'The OperationOutcome does not contain the required issue(s)'

    Examples:
      | inputFile                                         | responseCode |
      | DocumentReference-Post-UnknownPatient.json        | 422          |
      | DocumentReference-Post-UnknownEncounter.json      | 422          |
      | DocumentReference-Post-MissingAttachmentData.json | 4\d\d        |