# language: en
@Stufe5
@Medikation
@Mandatory
@Medication-Read
Feature: Read Information from a resource of type Medication (@Medication-Read)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST return the complete resource in response to an HTTP GET request to its URL (READ)."
    Given the Preconditions:
    """
      - The test data set must have been recorded in the system under test according to the specifications (manually).
      - The ID of the corresponding FHIR resource for this test data set must be stored in the configuration variable 'medication-read-id'.

      Create a Medication resource in your system with the following values:
      * Id: The value of the configuration variable 'medication-read-id'
      * A single ATC Code:
        * code: V03AB23
        * display: Acetylcystein
        * system: http://fhir.de/CodeSystem/bfarm/atc
        * version: any (the value of the configuration variable 'atc-code-version')
      * Status: active
      * Batch lot number: 123
      * Amount: 20 effervescent tablets per package
      * Ingredient: Reference to a valid ingredient with ATC code V03AB23 (the Id can be stored in the variable 'medication-read-referenced-ingredient').
    """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "Medication"

  Scenario: Read and Validate the Medication by its ID
    Then Get FHIR resource at "http://fhirserver/Medication/${data.medication-read-id}" with content type "xml"
    And resource has ID "${data.medication-read-id}"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikament"
    And TGR current response with attribute "$..Medication.status.value" matches "active"
    And TGR current response with attribute "$..batch.lotNumber.value" matches "123"
    And FHIR current response body evaluates the FHIRPath "code.coding.where(code = 'V03AB23' and system = 'http://fhir.de/CodeSystem/bfarm/atc' and display = 'Acetylcystein' and version.hasValue()).exists()" with error message 'The code does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "amount.where(numerator.value = 20 and numerator.system = 'http://unitsofmeasure.org' and numerator.unit.exists() and numerator.code = '1' and denominator.value = 1 and denominator.system = 'http://unitsofmeasure.org' and denominator.unit.exists() and denominator.code = '1').exists()" with error message 'The amount does not match the expected value'
    And FHIR current response body evaluates the FHIRPath "ingredient.item.exists()" with error message 'No reference to the ingredient exists'
    And element "ingredient.item" references resource with ID "${data.medication-read-referenced-ingredient}" with error message "The ingredient reference does not match the expected value."
