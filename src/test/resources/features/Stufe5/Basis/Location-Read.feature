# language: en
@Stufe5
@Basis
@Optional
@Location-Read
Feature: Read Information from a resource of type Location (@Location-Read)

  @Precondition:
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH). Here it is tested whether the resource is returned according to the location status as 'active'."
    Given the Preconditions:
    """
      - The Organization-Read test case must have been executed successfully beforehand.
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset must be stored in the configuration variable 'location-read-id'.

      Create a Location resource with these fields:

      * Location Identifier:
        * System: http://fhir.de/sid/dkgev/standortnummer
        * Value: any (Please set it in the variable 'location-read-identifier-value')
      * Type: Local Location identifier
        - System: http://terminology.hl7.org/CodeSystem/v3-RoleCode
        - Value: LOCHFID
      * Name: Station A
      * Mode: instance
      * Physical type: Ward
      * Address: Krankenhausstraße 123, 12345 Musterstadt, Germany
      * Position: Latitude 52.52, Longitude 13.405
      * Hours of Operation: Monday to Friday all day, Saturday 8am to 1pm, closed on Sunday
      * Managing organization: Reference to the Organization resource from the test case Organization-Read
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Location"

  Scenario: Read and Validate Location by its ID
    When Get FHIR resource at "http://fhirserver/Location/${data.location-read-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKStandort"
    And resource has ID "${data.location-read-id}" with error message "The ID does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "identifier.where(system = 'http://fhir.de/sid/dkgev/standortnummer' and value = '${data.location-read-identifier-value}').exists()" with error message 'The Organization IKNR does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "type.coding.where(system = 'http://terminology.hl7.org/CodeSystem/v3-RoleCode' and code = 'LOCHFID').exists()" with error message 'The Location type code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "name = 'Station A'" with error message 'The Location name does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "mode = 'instance'" with error message 'The Location mode does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "physicalType.coding.where(system = 'http://terminology.hl7.org/CodeSystem/location-physical-type' and code = 'wa').exists()" with error message 'The Location physical type code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "address.line.where($this = 'Krankenhausstraße 123').exists()" with error message 'The Location address line does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "address.where(city = 'Musterstadt' and postalCode = '12345' and country = 'DE').exists()" with error message 'The Location address does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "position.where(latitude = 52.52 and longitude = 13.405).exists()" with error message 'The Location position does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "hoursOfOperation.where(daysOfWeek.where($this = 'mon') and allDay = true).exists()" with error message 'The hours of operation for Monday do not match the expected value'
    And FHIR current response body evaluates the FHIRPath "hoursOfOperation.where(daysOfWeek.where($this = 'sat') and openingTime = @T08:00:00 and closingTime = @T13:00:00).exists()" with error message 'The Location hours of operation for Saturday do not match the expected value'
    And FHIR current response body evaluates the FHIRPath "managingOrganization.reference = 'Organization/${data.organization-read-id}'" with error message 'The managing Organization reference does not match the expected value'