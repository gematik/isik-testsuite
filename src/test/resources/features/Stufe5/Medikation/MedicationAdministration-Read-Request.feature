# language: en
@Stufe5
#@Medikation
@Disabled
@Optional
@MedicationAdministration-Read-Request
Feature: Read Information from a resource of type MedicationAdministration (Request) (@MedicationAdministration-Read-Request)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      TODO
    """

  Scenario: Read and Validate the MedicationAdministration with request details by ID
    Then Get FHIR resource at "http://fhirserver/MedicationAdministration/${data.medicationadministration-read-request-id}" with content type "xml"
    And resource has ID "${data.medicationadministration-read-request-id}"
