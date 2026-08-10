# language: en
@Stufe5
@Medikation
@Mandatory
@ISiKCapabilityStatementMedikamentRolle
@Medication-Read-Extended
Feature: Read Information from a resource of type Medication with extended data (@Medication-Read-Extended)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'medication-read-extended-id'.

      Create a Medication resource in your system with the following values:
      * Id: The value of the configuration variable 'medication-read-extended-id'
      * Status: active
      * Form:
        - Display: Solution for infusion
        - Code: 11210000
        - System: http://standardterms.edqm.eu
      * Code:
        - Text: Any not empty value
        - Code: L01DB01
        - Display: Doxorubicin
        - System: http://fhir.de/CodeSystem/bfarm/atc
        - Version: any (the value of the configuration variable 'atc-code-version')
      * Ingredient:
        - Substance type: active ingredient
        - Strength:
           - Numerator: 85mg
           - Denominator: 250 mL
        - Coding:
           - Code: L01DB01
           - Display: Doxorubicin
           - System: http://fhir.de/CodeSystem/bfarm/atc
           - Version: any (the value of the configuration variable 'atc-code-version')
        - Extension:
           - URL: https://www.medizininformatik-initiative.de/fhir/core/modul-medikation/StructureDefinition/wirkstofftyp
           - ValueCoding:
              - Code: IN
              - System: https://www.medizininformatik-initiative.de/fhir/core/modul-medikation/CodeSystem/wirkstofftyp
    """

  Scenario: Read and Validate the Medication by its ID
    Then Get FHIR resource at "http://fhirserver/Medication/${medikation.medication-read-extended-id}" with content type "xml"
    And resource has ID "${medikation.medication-read-extended-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikament"
    And TGR current response with attribute "$..Medication.status.value" matches "active"
    And FHIR current response body evaluates the FHIRPath "code.text.empty().not()" with error message 'The code does not contain a valid text value'
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = 'L01DB01' and system = 'http://fhir.de/CodeSystem/bfarm/atc' and display = 'Doxorubicin' and version.hasValue()).exists()" with error message 'The code does not contain the expected information'
    And FHIR current response body evaluates the FHIRPath "form.coding.where(system = 'http://standardterms.edqm.eu' and code = '11210000' and display = 'Solution for infusion').exists()" with error message 'The form does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "ingredient.where(isActive = 'true' and extension.where(url = 'https://www.medizininformatik-initiative.de/fhir/core/modul-medikation/StructureDefinition/wirkstofftyp' and value.where(code = 'IN' and system = 'https://www.medizininformatik-initiative.de/fhir/core/modul-medikation/CodeSystem/wirkstofftyp').exists()).exists() ).exists() and ingredient.where(item.coding.where(code = 'L01DB01' and system = 'http://fhir.de/CodeSystem/bfarm/atc' and display = 'Doxorubicin' and version.hasValue()).exists() and strength.where(numerator.where(value ~ 85 and unit.hasValue() and system = 'http://unitsofmeasure.org' and code = 'mg').exists() and denominator.where(value ~ 250 and unit.hasValue() and system = 'http://unitsofmeasure.org' and code = 'mL').exists()).exists() ).exists()" with error message 'The doxorubicin ingredient description does not match the expected value'
