# language: en
@Stufe5
@Medikation
@Mandatory
@MedicationTransaction-Post
Feature: Upload of an ISiK medication transaction bundle with the POST operation (@MedicationTransaction-Post)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST support FHIR transaction bundles for the Medikation module and be able to resolve the referenced Patient, Encounter and Condition resources."
    Given the Preconditions:
      """
        - The MedicationStatement-Read test case must have been executed successfully beforehand.

        For the execution of this test case, the following resources must exist in the system under test:
        * Patient: a valid ISiKPatient resource - the Id can be customised with the variable 'medication-patient-id'
        * Encounter: a valid ISiKKontaktGesundheitseinrichtung resource - the Id can be customised with the variable 'medication-encounter-id'
        * Condition: a valid ISiKDiagnose resource - the Id can be customised with the variable 'medication-condition-id'
      """

  Scenario: Read and Validation of the CapabilityStatement
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains system interaction "transaction"

  Scenario: POST a valid medication transaction bundle
    Given TGR set default header "Content-Type" to "application/fhir+json"
    And TGR set default header "Prefer" to "return=representation"
    When TGR send POST request to "http://fhirserver/" with body "!{file('src/test/resources/features/Stufe5/Medikation/fixtures/MedicationTransaction-Post-Fixture.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "20\d"
    And FHIR current response body is a valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationTransactionResponse"
    And FHIR current response body evaluates the FHIRPath "id.exists()" with error message 'No ID was assigned to the transaction response bundle'
    And FHIR current response body evaluates the FHIRPath "type = 'transaction-response'" with error message 'The response bundle does not have the type transaction-response'
    And FHIR current response body evaluates the FHIRPath "entry.count() = 2" with error message 'The transaction response bundle does not contain exactly the expected two entries'
    And FHIR current response body evaluates the FHIRPath "entry.all(fullUrl.exists())" with error message 'At least one transaction response entry does not contain a fullUrl'
    And FHIR current response body evaluates the FHIRPath "entry.all(request.exists().not())" with error message 'A transaction response entry unexpectedly contains a request element'
    And FHIR current response body evaluates the FHIRPath "entry.all(response.exists())" with error message 'At least one transaction response entry does not contain a response element'
    And FHIR current response body evaluates the FHIRPath "entry.all(response.status.matches('^20\\d( .*)?$'))" with error message 'At least one transaction response entry does not contain a successful HTTP status'
    And FHIR current response body evaluates the FHIRPath "entry.all(response.location.exists())" with error message 'At least one transaction response entry does not contain a response location'
    And FHIR current response body evaluates the FHIRPath "entry.where(response.location.contains('MedicationStatement/') and resource is MedicationStatement).count() = 1" with error message 'The transaction response does not contain exactly one MedicationStatement representation'
    And FHIR current response body evaluates the FHIRPath "entry.where(response.location.contains('Medication/') and resource is Medication).count() = 1" with error message 'The transaction response does not contain exactly one Medication representation'
    And FHIR current response body evaluates the FHIRPath "entry.where(resource is MedicationStatement).all(resource.meta.profile.where($this = 'https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikationsInformation').exists())" with error message 'The MedicationStatement in the transaction response does not conform to the expected ISiK profile'
    And FHIR current response body evaluates the FHIRPath "entry.where(resource is MedicationStatement).all(resource.status = 'active')" with error message 'The MedicationStatement in the transaction response does not have status active'
    And FHIR current response body evaluates the FHIRPath "entry.where(resource is MedicationStatement).all(resource.subject.reference.replaceMatches('/_history/.+','').matches('\\bPatient/${data.medication-patient-id}$'))" with error message 'The MedicationStatement subject reference does not match the expected patient'
    And FHIR current response body evaluates the FHIRPath "entry.where(resource is MedicationStatement).all(resource.context.reference.replaceMatches('/_history/.+','').matches('\\bEncounter/${data.medication-encounter-id}$'))" with error message 'The MedicationStatement context reference does not match the expected encounter'
    And FHIR current response body evaluates the FHIRPath "entry.where(resource is MedicationStatement).all(resource.reasonReference.where(reference.replaceMatches('/_history/.+','').matches('\\bCondition/${data.medication-condition-id}$')).exists())" with error message 'The MedicationStatement reason reference does not match the expected condition'
    And FHIR current response body evaluates the FHIRPath "entry.where(resource is MedicationStatement).all(resource.medication.reference.exists())" with error message 'The MedicationStatement in the transaction response does not reference a medication'
    And FHIR current response body evaluates the FHIRPath "entry.where(resource is MedicationStatement).all(resource.extension.where(url = 'https://gematik.de/fhir/isik/StructureDefinition/ExtensionISiKAcceptedRisk').exists())" with error message 'The MedicationStatement in the transaction response does not contain the accepted risk extension'
    And FHIR current response body evaluates the FHIRPath "entry.where(resource is MedicationStatement).all(resource.extension.where(url = 'https://gematik.de/fhir/isik/StructureDefinition/ExtensionISiKMedikationsart').exists())" with error message 'The MedicationStatement in the transaction response does not contain the medication type extension'
    And FHIR current response body evaluates the FHIRPath "entry.where(resource is MedicationStatement).all(resource.extension.where(url = 'https://gematik.de/fhir/isik/StructureDefinition/ExtensionISiKSelbstmedikation').exists())" with error message 'The MedicationStatement in the transaction response does not contain the self-medication extension'
    And FHIR current response body evaluates the FHIRPath "entry.where(resource is MedicationStatement).all(resource.extension.where(url = 'https://gematik.de/fhir/isik/StructureDefinition/ExtensionISiKBehandlungsziel').exists())" with error message 'The MedicationStatement in the transaction response does not contain the treatment goal extension'
    And FHIR current response body evaluates the FHIRPath "entry.where(resource is MedicationStatement).all(resource.dosage.where(patientInstruction.exists() and doseAndRate.dose.where(value = 1 and system = 'http://unitsofmeasure.org' and code = '1').exists()).exists())" with error message 'The MedicationStatement dosage does not match the expected Must-Support content'
    And FHIR current response body evaluates the FHIRPath "entry.where(resource is Medication).all(resource.meta.profile.where($this = 'https://gematik.de/fhir/isik/StructureDefinition/ISiKMedikament').exists())" with error message 'The Medication in the transaction response does not conform to the expected ISiK profile'
    And FHIR current response body evaluates the FHIRPath "entry.where(resource is Medication).all(resource.status = 'active')" with error message 'The Medication in the transaction response does not have status active'
    And FHIR current response body evaluates the FHIRPath "entry.where(resource is Medication).all(resource.code.coding.where(system = 'http://fhir.de/CodeSystem/bfarm/atc' and version = '${data.atc-code-version}' and code = 'V03AB23' and display = 'Acetylcystein').exists())" with error message 'The Medication in the transaction response does not contain the expected ATC coding'

  Scenario: POST an invalid medication transaction bundle without request elements
    Given TGR set default header "Content-Type" to "application/fhir+json"
    When TGR send POST request to "http://fhirserver/" with body "!{file('src/test/resources/features/Stufe5/Medikation/fixtures/MedicationTransaction-Post-MissingRequest-Fixture.json')}"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "4\d\d"
    And FHIR current response body evaluates the FHIRPath "$this is OperationOutcome" with error message 'The response does not contain an OperationOutcome resource'
    And FHIR current response body evaluates the FHIRPath "issue.where(severity = 'error' or severity = 'fatal').count() >= 1" with error message 'The OperationOutcome does not contain the expected issue(s)'

