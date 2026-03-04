# language: en
@Stufe5
@Disabled # This Testcase is still under development and will be enabled in a later stage of the project.
@Optional
@DocumentReference-UpdateMetadata
Feature: Update Metadata of an existing DocumentReference with POST Operation (Metadatenupdate) (@DocumentReference-UpdateMetadata)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test SHALL be able to update the status of a document and must delete it, if the status 'entered-in-error' is set."
    Given the Preconditions:
      """
      This test assumes that the system under test supports the creation of a DocumentReference Instance and the update of its metadata.
      """

  Scenario Outline: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "<interactionName>" for resource "DocumentReference"

    Examples:
      | interactionName |
      | create          |
      | update          |
      | delete          |

  Scenario: POST a valid DocumentBundle with known patient and encounter and state "preliminary"
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send POST request to "http://fhirserver/DocumentReference" with body "!{file('src/test/resources/features/Stufe5/Dokumentenaustausch/fixtures/DocumentReference-UpdateMetadata-Initial.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "20\d"
    # Caution! The following checks assume that a representation of the new resource has been returned directly in the response. This is guaranteed by the createOperation which sends the header 'Prefer: return=representation' internally.
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKDokumentenMetadaten"
    Then FHIR evaluate FHIRPath "id" on current response body and store first element as primitive value in variable "data.documentreference-update-stored-id"
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send POST request to "http://fhirserver/DocumentReference/${data.documentreference-update-stored-id}/$update-metadata" with body "!{file('src/test/resources/features/Stufe5/Dokumentenaustausch/fixtures/DocumentReference-UpdateMetadata-Entered-In-Error.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "20\d"
