# language: en
@Stufe5
@Basis
@Optional
@Location-Bed-Placement-Read
Feature: Read Information from a resource of type Location that identifies the placement of beds (@Location-Bed-Placement-Read)

  @Precondition:
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH). Here it is tested whether the resource is returned according to the location status as 'active'."
    Given the Preconditions:
    """
      - The Organization-Read and Location-Room-Read test cases must have been executed successfully beforehand.
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset must be stored in the configuration variable 'location-room-read-id'.

      Create a Location resource with these fields:

      * Name: B022
      * Physical type: Bed
      * Operational status: Occupied
      * Managing organization: Reference to the Organization resource from the test case Organization-Read
      * Part of: Reference to the Location resource from the test case Location-Room-Read
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validate Bed Placement Location by its ID
    When Get FHIR resource at "http://fhirserver/Location/${data.location-bed-placement-read-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKStandortBettenstellplatz"
    And resource has ID "${data.location-bed-placement-read-id}" with error message "The ID does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "name = 'B022'" with error message 'The Location name does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "operationalStatus.where(code = 'O' and system = 'http://terminology.hl7.org/CodeSystem/v2-0116').exists()" with error message 'The Location operational status code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "physicalType.coding.where(system = 'http://terminology.hl7.org/CodeSystem/location-physical-type' and code = 'bd').exists()" with error message 'The Location physical type code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "managingOrganization.where(reference = 'Organization/${data.organization-read-id}').exists()" with error message 'The Location managing organization reference does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "partOf.where(reference = 'Location/${data.location-room-read-id}').exists()" with error message 'The Location partOf reference does not match the expected value'
