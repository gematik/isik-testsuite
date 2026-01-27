# language: en
@Stufe5
@Basis
@Optional
@Organization-Read
Feature: Read Information from a resource of type Organization (@Organization-Read)

  @Precondition:
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH). Here it is tested whether the resource is returned according to the Organization status as 'active'."
    Given the Preconditions:
    """
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset must be stored in the configuration variable 'organization-read-id'.

      Create a Organization resource with these fields:

      * Name: Uniklinik Entenhausen
      * Alias: UKE
      * Active status: true
      * Type: Educational Institute
      * Phone: +49 123 4567890
      * Postal Address: Hauptstraße 12, 12345 Entenhausen, Germany
      * Street Address: Klinikweg 1, 12345 Entenhausen, Germany
      * Telematik-ID: 1234567890
      * Institution Identifier (IKNR): 260120196
      * Facility Number (BSNR): 345678975
      * Organizational Unit ID (OrganisationseinheitenID):
        - Type: SNOMED CT Code 225746001 (from the German National Edition code: 49076000, version: configured with the variable 'snomed-ct-version')
        - Value: 123456
        - System: https://fhir.krankenhaus.example/sid/OrgaID
      * Contact: Name: Dr. Max Mustermann, Phone: +49 987 6543210, Purpose: Billing
      * Part of: Reference to another Organization resource (can be created manually, the ID must be stored in the configuration variable 'organization-read-parent-id')
      * (Optional) Endpoint: Reference to any Endpoint resource
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validate Organization by its ID
    When Get FHIR resource at "http://fhirserver/Organization/${data.organization-read-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKOrganisation"
    And resource has ID "${data.organization-read-id}" with error message "The ID does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "name = 'Uniklinik Entenhausen'" with error message 'The Organization name does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "alias.where($this = 'UKE').exists()" with error message 'The Organization alias does not match the expected value'
    And TGR current response with attribute "$..active.value" matches "true"
    And FHIR current response body evaluates the FHIRPath "type.coding.where(system = 'http://terminology.hl7.org/CodeSystem/organization-type' and code = 'edu').exists()" with error message 'The Organization type code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "telecom.where(system = 'phone' and value = '+49 123 4567890').exists()" with error message 'The Organization phone number does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "identifier.where(system = 'https://gematik.de/fhir/sid/telematik-id' and value = '1234567890').exists()" with error message 'The Organization Telematik-ID does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "identifier.where(system = 'http://fhir.de/sid/arge-ik/iknr' and value = '260120196').exists()" with error message 'The Organization IKNR does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "identifier.where(system = 'https://fhir.kbv.de/NamingSystem/KBV_NS_Base_BSNR' and value = '345678975').exists()" with error message 'The Organization BSNR does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "identifier.where(system = 'https://fhir.krankenhaus.example/sid/OrgaID' and value = '123456' and type.coding.where(system = 'http://snomed.info/sct' and version = 'http://snomed.info/sct/11000274103/version/${data.snomed-ct-version}' and code = '225746001')).exists()" with error message 'The Organization Unit ID does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "address.where(type = 'postal' and line.where($this = 'Hauptstraße 12').exists() and city = 'Entenhausen' and postalCode = '12345' and country = 'DE').exists()" with error message 'The Organization postal address does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "address.where(type = 'physical' and line.where($this = 'Klinikweg 1').exists() and city = 'Entenhausen' and postalCode = '12345' and country = 'DE').exists()" with error message 'The Organization street address does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "contact.where(purpose.coding.where(system = 'http://terminology.hl7.org/CodeSystem/contactentity-type' and code = 'BILL').exists()).exists()" with error message 'The Organization contact purpose does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "contact.where(name.family = 'Mustermann' and name.given.where($this = 'Max')).exists()" with error message 'The Organization contact name does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "contact.telecom.where(system = 'phone' and value = '+49 987 6543210').exists()" with error message 'The Organization contact phone does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "partOf.where(reference = 'Organization/${data.organization-read-parent-id}').exists()" with error message 'The Organization partOf reference does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "endpoint.empty() or endpoint.where(reference.matches('^Endpoint/')).exists()" with error message 'The Organization endpoint reference is not valid'