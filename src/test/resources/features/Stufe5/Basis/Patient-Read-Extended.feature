# language: en
@Stufe5
@Basis
@Mandatory
@Patient-Read-Extended
Feature: Read extended Information from a resource of type Patient (@Patient-Read-Extended)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test dataset must have been entered in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test dataset as well as the assigned facility-internal patient ID must be stored in the configuration variable 'patient-read-extended-id'.

      Create a Patient resource with these fields:
      
      * First name: Miléna,Marçya
      * Last name: Gräfin Müßtermánn (with extensions)
      * Gender: diverse
      * Date of birth: 20.06.1955
      * Phone number: 201-867-5310
      * Link: Reference to another Patient (Please set it in the configuration variable 'patient-read-extended-link-other-patient-id')
      * Link type: see also (seealso)
      * (Optional) Tag: Value defined through the configuration variables 'tag-value' and 'tag-system'
    """

  Scenario: Read and Validate Patient by their ID
    When Get FHIR resource at "http://fhirserver/Patient/${data.patient-read-extended-id}" with content type "xml"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKPatient"
    And resource has ID "${data.patient-read-extended-id}" with error message "The ID does not match the expected value"
    And TGR current response with attribute "$..gender.value" matches "other"
    And TGR current response with attribute "$..birthDate.value" matches "1955-06-20"
    And FHIR current response body evaluates the FHIRPath "name.where(use='official').given.matches('Miléna,Marçya')"
    And FHIR current response body evaluates the FHIRPath "name.where(use='official').family.matches('Gräfin Müßtermánn')"
    And FHIR current response body evaluates the FHIRPath "telecom.where(system='phone').value.matches('201-867-5310')"
    And FHIR current response body evaluates the FHIRPath "gender.extension.where(url = 'http://fhir.de/StructureDefinition/gender-amtlich-de' and value.code = 'D' and value.system = 'http://fhir.de/CodeSystem/gender-amtlich-de').exists()" with error message 'The gender does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "name.family.extension.where(url = 'http://fhir.de/StructureDefinition/humanname-namenszusatz' and value = 'Gräfin').exists()" with error message 'The name suffix is not present'
    And FHIR current response body evaluates the FHIRPath "name.family.extension.where(url = 'http://hl7.org/fhir/StructureDefinition/humanname-own-name' and value = 'Müßtermánn').exists()" with error message 'The last name without suffix is not present'
    And element "link.other" references resource with ID "Patient/${data.patient-read-extended-link-other-patient-id}" with error message "The referenced link does not match the expected value"
    And FHIR current response body evaluates the FHIRPath "link.where(type = 'seealso').exists()" with error message 'The link type does not match the expected value'
