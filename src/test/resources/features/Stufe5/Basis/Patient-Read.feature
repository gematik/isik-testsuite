# language: en
@Stufe5
@Basis
@Mandatory
@Patient-Read
Feature: Read Information from a resource of type Patient (@Patient-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset must be stored in the configuration variable 'patient-read-id'.

      Create a Patient resource with these fields:

      * Status: active
      * First name: Max
      * Last name: Graf von und zu Mustermann
      * Gender: male
      * Address: Musterstraße 3, 1. Etage Hinterhaus, 98765 Musterdorf, Germany
      * District: Wiedikon
      * P.O. Box: 4711 (same city)
      * Date of birth: 12.5.1968
      * Phone number: 201-867-5309
      * Statutory health insurance number: X485231029
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Patient"

  Scenario: Read and Validate Patient by their ID
    When Get FHIR resource at "http://fhirserver/Patient/${data.patient-read-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKPatient"
    And resource has ID "${data.patient-read-id}" with error message "The ID does not match the expected value"
    And TGR current response with attribute "$..gender.value" matches "male"
    And TGR current response with attribute "$..active.value" matches "true"
    And TGR current response with attribute "$..birthDate.value" matches "1968-05-12"
    And FHIR current response body evaluates the FHIRPath "name.where(use='official').given.matches('Max')"
    And FHIR current response body evaluates the FHIRPath "name.where(use='official').family.matches('Graf von und zu Mustermann')"
    And FHIR current response body evaluates the FHIRPath "telecom.where(system='phone').value.matches('201-867-5309')"
    And FHIR current response body evaluates the FHIRPath "identifier.where(value = 'X485231029' and system = 'http://fhir.de/sid/gkv/kvid-10').exists()" with error message 'The statutory health insurance number does not match the expected value'
    # The additionalLocator information can be structured according to DIN 5008 cf. ANFISK-179
    And FHIR current response body evaluates the FHIRPath "address.where(type = 'both' and city = 'Musterdorf' and postalCode = '98765' and country = 'DE' and line.extension.where( url = 'http://hl7.org/fhir/StructureDefinition/iso21090-ADXP-streetName' and value = 'Musterstraße' ).exists() and line.extension.where( url = 'http://hl7.org/fhir/StructureDefinition/iso21090-ADXP-houseNumber' and value = '3' ).exists() and line.where( extension.where( url = 'http://hl7.org/fhir/StructureDefinition/iso21090-ADXP-additionalLocator'  and value.matches('1\\. Etage.+Hinterhaus|Hinterhaus.+1\\. Etage') ).exists() ).matches('1\\. Etage.+Hinterhaus|Hinterhaus.+1\\. Etage' ) ).exists()" with error message 'The address does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "address.extension.where(url = 'http://hl7.org/fhir/StructureDefinition/iso21090-ADXP-precinct' and (value as string) = 'Wiedikon').exists()" with error message 'District is incorrectly specified'
    And FHIR current response body evaluates the FHIRPath "address.where(type = 'postal' and city = 'Musterdorf' and postalCode = '98765' and country = 'DE' and line.where(extension.url = 'http://hl7.org/fhir/StructureDefinition/iso21090-ADXP-postBox' and extension.value = 'Postfach 4711') = 'Postfach 4711').exists()" with error message 'The P.O. Box does not match the expected value'
