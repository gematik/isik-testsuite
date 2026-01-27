# language: en
@Stufe5
@Basis
@Mandatory
@Practitioner-Read
Feature: Read Information from a resource of type Practitioner (@Practitioner-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset must be stored in the configuration variable 'practitioner-read-id'.

      Create a Practitioner resource with these fields:

      * First name: Walter
      * Last name: Musterarzt
      * Gender: male
      * Lifelong Doctor number (Arztnummer): 123456789
      * Unified training number (EFN): 123456789123456
      * Telematik-ID: 123456789
      * Address: Musterweg 13 11111 Berlin
      * Address (district): Wilmersdorf
      * Gender: Male
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Practitioner"

  Scenario: Read and Validate Practitioner resource by its ID
    When Get FHIR resource at "http://fhirserver/Practitioner/${data.practitioner-read-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKPersonImGesundheitsberuf"
    And resource has ID "${data.practitioner-read-id}" with error message "The ID does not match the expected value"
    And TGR current response with attribute "$..gender.value" matches "male"
    And FHIR current response body evaluates the FHIRPath "name.where(use='official').given.matches('Walter')"
    And FHIR current response body evaluates the FHIRPath "name.where(use='official').family.matches('Musterarzt')"
    And FHIR current response body evaluates the FHIRPath "identifier.where(system='https://fhir.kbv.de/NamingSystem/KBV_NS_Base_ANR').exists().not() or (identifier.where(system='https://fhir.kbv.de/NamingSystem/KBV_NS_Base_ANR').exists() and identifier.where(system='https://fhir.kbv.de/NamingSystem/KBV_NS_Base_ANR').value = '123456789')" with error message 'The found LANR number does not match the requirement'
    And FHIR current response body evaluates the FHIRPath "identifier.where(system='http://fhir.de/sid/bundesaerztekammer/efn').exists().not() or (identifier.where(system='http://fhir.de/sid/bundesaerztekammer/efn').exists() and identifier.where(system='http://fhir.de/sid/bundesaerztekammer/efn').value = '123456789123456')" with error message 'The found EFN value does not match the requirement'
    And FHIR current response body evaluates the FHIRPath "identifier.where(system='https://gematik.de/fhir/sid/telematik-id').exists().not() or identifier.where(system='https://gematik.de/fhir/sid/telematik-id' and value = '123456789').exists()" with error message 'The Telematik-ID does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "address.where(type = 'both' and city = 'Berlin' and postalCode = '11111' and country = 'DE' and line = 'Musterweg 13' and line.extension.where(url = 'http://hl7.org/fhir/StructureDefinition/iso21090-ADXP-streetName' and value = 'Musterweg').exists() and line.extension.where(url = 'http://hl7.org/fhir/StructureDefinition/iso21090-ADXP-houseNumber' and value = '13').exists()).exists()" with error message 'The address does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "address.extension.where(url = 'http://hl7.org/fhir/StructureDefinition/iso21090-ADXP-precinct' and (value as string) = 'Wilmersdorf').exists()" with error message 'District is incorrectly specified'
