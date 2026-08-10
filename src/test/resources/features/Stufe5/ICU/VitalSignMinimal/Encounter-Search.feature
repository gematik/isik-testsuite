# language: en
@Stufe5
@ICUMinimal
@VitalSignICUSourceMinimalAkteur
@Mandatory
@ISiKCapabilityStatementStammdatenRolle
@ISiKCapabilityStatementLeistungserbringerRolle
@Encounter-Search
Feature: Testing search parameters against a resource of type encounter-read-in-progress, according to the definition of ISiKCapabilityStatementStammdatenRolle (@Encounter-Search)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test MUST find a previously created resource when searched using the parameter and return it in the search results (SEARCH)."
    Given the Preconditions:
    """
      - The Encounter-Read-In-Progress, Encounter-Read-Finished and Account-Read test cases must have been executed successfully beforehand.
    """

  Scenario: Read and Validation of the CapabilityStatement
    When Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "search-type" for resource "Encounter"

  Scenario Outline: Validation of the search parameter definitions in the CapabilityStatement
    And CapabilityStatement contains definition of search parameter "<searchParamValue>" of type "<searchParamType>" for resource "Encounter"

    Examples:
      | searchParamValue | searchParamType |
      | _id              | token           |
      | _count           | number          |
      | identifier       | token           |
      | status           | token           |
      | class            | token           |
      | type             | token           |
      | patient          | reference       |
      | account          | reference       |
      | date             | date            |
      | date-start       | date            |
      | end-date         | date            |

    @Optional
    Examples:
      | searchParamValue | searchParamType |
      | _has             | string          |
      | _tag             | token           |

  Scenario: Search for the encounter by ID
    When Get FHIR resource at "http://fhirserver/Encounter/?_id=${icuminimal.encounter-read-in-progress-id}" with content type "xml"
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And response bundle contains resource with ID "${icuminimal.encounter-read-in-progress-id}" with error message "The requested Encounter ${icuminimal.encounter-read-in-progress-id} is not contained in the response bundle."

  Scenario: Search for the Encounter by Count
    When Get FHIR resource at "http://fhirserver/Encounter/?_count=2" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0 and entry.resource.count() <= 2' with error message 'The _count parameter was not applied as expected'

  Scenario: Search for the Encounter by Status and ID
    When Get FHIR resource at "http://fhirserver/Encounter/?status=in-progress&_id=${icuminimal.encounter-read-in-progress-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(status = 'in-progress')" with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${icuminimal.encounter-read-in-progress-id}" with error message "The requested Encounter ${icuminimal.encounter-read-in-progress-id} is not contained in the response bundle."

  Scenario: Search for the Encounter by Class and Patient
    When Get FHIR resource at "http://fhirserver/Encounter/?class=http://terminology.hl7.org/CodeSystem/v3-ActCode%7CIMP&patient=Patient/${icuminimal.patient-read-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(class.where(code = 'IMP' and system = 'http://terminology.hl7.org/CodeSystem/v3-ActCode').exists())" with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${icuminimal.encounter-read-in-progress-id}" with error message "The requested Encounter ${icuminimal.encounter-read-in-progress-id} is not contained in the response bundle."

  Scenario: Search for the Encounter by Type and Patient
    When Get FHIR resource at "http://fhirserver/Encounter/?type=http://fhir.de/CodeSystem/kontaktart-de%7Cnormalstationaer&patient=Patient/${icuminimal.patient-read-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(type.coding.where(code = 'normalstationaer' and system = 'http://fhir.de/CodeSystem/kontaktart-de').exists())" with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${icuminimal.encounter-read-in-progress-id}" with error message "The requested Encounter ${icuminimal.encounter-read-in-progress-id} is not contained in the response bundle."

  Scenario: Search for the Encounter by Patient and Encounter ID
    When Get FHIR resource at "http://fhirserver/Encounter/?patient=Patient/${icuminimal.patient-read-id}&_id=${icuminimal.encounter-read-in-progress-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "subject" in all bundle resources references resource with ID "${icuminimal.patient-read-id}"
    And response bundle contains resource with ID "${icuminimal.encounter-read-in-progress-id}" with error message "The requested Encounter ${icuminimal.encounter-read-in-progress-id} is not contained in the response bundle."

  Scenario: Search for the Encounter by Account ID and Patient
    When Get FHIR resource at "http://fhirserver/Encounter/?account=${icuminimal.account-read-id}&patient=Patient/${icuminimal.account-read-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "account" in all bundle resources references resource with ID "${icuminimal.account-read-id}"
    And response bundle contains resource with ID "${icuminimal.encounter-read-finished-id}" with error message "The requested Encounter ${icuminimal.encounter-read-finished-id} is not contained in the response bundle."

  Scenario: Search for the Encounter by Account Identifier
    When Get FHIR resource at "http://fhirserver/Encounter/?account:identifier=${icuminimal.account-read-identifier-system}%7C${icuminimal.account-read-identifier-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And element "account" in all bundle resources references resource with ID "${icuminimal.account-read-id}"
    And response bundle contains resource with ID "${icuminimal.encounter-read-finished-id}" with error message "The requested Encounter ${icuminimal.encounter-read-finished-id} is not contained in the response bundle."

  Scenario: Search for the Encounter by Admission Date with 'le' Modifier and Patient
    When Get FHIR resource at "http://fhirserver/Encounter/?date=le2050-01-01&patient=Patient/${icuminimal.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(period.start <= @2050-01-01T23:59:59+01:00 or period.start.empty())" with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${icuminimal.encounter-read-in-progress-id}" with error message "The requested Encounter ${icuminimal.encounter-read-in-progress-id} is not contained in the response bundle."

  Scenario: Search for the Encounter by Admission Date with 'gt' Modifier and Patient
    When Get FHIR resource at "http://fhirserver/Encounter/?date=gt1999-01-01&patient=Patient/${icuminimal.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(period.end >= @1999-01-01T00:00:00+01:00 or period.end.empty())" with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${icuminimal.encounter-read-in-progress-id}" with error message "The requested Encounter ${icuminimal.encounter-read-in-progress-id} is not contained in the response bundle."

  Scenario: Negative Search for the Encounter by Admission Date and Patient
    When Get FHIR resource at "http://fhirserver/Encounter/?date=2026-01-05&patient=Patient/${icuminimal.patient-read-id}" with content type "xml"
    And bundle does not contain resource "Encounter" with ID "${icuminimal.encounter-read-in-progress-id}" with error message "The requested encounter ${icuminimal.encounter-read-in-progress-id} must not be returned here"


  #  Search all encounters, where the stay period intersects with [2026-01-05, 2026-01-14]
  #
  #  Matching instances:
  #
  #  Encounter
  #  start: 2026-01-06 (>left boundary but < right boundary)
  #  end: 2026-01-08 (<right boundary)
  #  Encounter
  #  start: 2026-01-06 (<left boundary)
  #  end: 2021-03-01 (>right boundary)
  #  Encounter
  #  start: 2026-01-05 (=left boundary)
  #  end: 2026-01-05 (=right boundary)
  #  Encounter
  #  start: 2026-01-05 (=end boundary)
  #  end: 2026-01-05 (=end boundary)
  #  Encounter
  #  start: 2021-01-01 (<left boundary)
  #  end: 2026-01-06 (<right boundary but > left boundary)
  #  Encounter
  #  start: 2021-01-01 (<left boundary)
  #  Encounter
  #  start: 2026-01-05 (=left boundary)
  #  Encounter
  #  start: 2026-01-06 (>left boundary but < right boundary)
  #  Encounter
  #  start: 2026-01-05 (=right boundary)
  #  Encounter
  #  end: 2026-01-05 (=left boundary)
  #  Encounter
  #  end: 2026-01-08 (<right boundary but > left boundary)
  #  Encounter
  #  end: 2021-03-01 (=right boundary)
  #  Encounter
  #  end: 2021-03-01 (>right boundary)
  #
  #  Non-matching instances:
  #
  #  Encounter
  #  start: 2021-03-01 (> right boundary)
  #  Encounter
  #  end: 2021-02-10 (< left boundary)
  #  Encounter
  #  start: 2021-03-01 (> right boundary)
  #  end: 2021-04-01 (> right boundary)
  #  Encounter
  #  start: 2020-11-01 (< left boundary)
  #  end: 2021-02-10 (< left boundary)
  #
  #  Expression for non-matching instances: start.exists and start > upper bound or end.exists and end < left bound.
  #  Expression for matching instances: not (expression for non-matching instances)

  Scenario: Search for the Encounter by Admission Date with 'ge' und 'le' Modifiers and Patient
    When Get FHIR resource at "http://fhirserver/Encounter/?date=ge2026-01-05&date=le2026-01-14&patient=Patient/${icuminimal.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.select((period.start.exists() and period.start >  @2026-01-14T23:59:59+01:00) or (period.end.exists() and period.end < @2026-01-05T00:00:00+01:00)).allFalse()" with error message 'There are search results, but they do not fully match the search criteria'

  # Warning: The search parameters date-start and end-date check specific date values from period.start and period.end respectively — they do not perform interval inclusion or overlap like the date search parameter. The date search handles missing start or end dates differently. See HL7 FHIR docs:
  # https://hl7.org/fhir/R4/search.html#date
  # https://hl7.org/fhir/R5/encounter-search.html#Encounter-date-start
  Scenario: Search for the Encounter by Admission Date with the Search parameter 'end-date' and Patient
    When Get FHIR resource at "http://fhirserver/Encounter/?end-date=le2050-01-01&patient=Patient/${icuminimal.account-read-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(period.end <= @2050-01-01T23:59:59+01:00)" with error message 'There are search results, but they do not fully match the search criteria'
    # encounter-read-in-progress-id has start date 2026-01-06 but no end date, so it must not appear in the search results
    And bundle does not contain resource "Encounter" with ID "${icuminimal.encounter-read-in-progress-id}" with error message "The requested encounter ${icuminimal.encounter-read-in-progress-id} must not be returned here."
    # encounter-read-finished-id has start date 2026-01-06 and end date 2026-01-08 in test data, therefore it must appear in the bundle
    And response bundle contains resource with ID "${icuminimal.encounter-read-finished-id}" with error message "The requested encounter ${icuminimal.encounter-read-finished-id} is not contained in the response bundle."

  Scenario: Search for the Encounter by Admission Date with the Search parameter 'date-start' and Patient
    When Get FHIR resource at "http://fhirserver/Encounter/?date-start=ge1999-01-01&patient=Patient/${icuminimal.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(period.start >= @1999-01-01T00:00:00+01:00)" with error message 'There are search results, but they do not fully match the search criteria'
    # encounter-read-in-progress-id has start date 2026-01-06 and must therefore appear in the bundle
    And response bundle contains resource with ID "${icuminimal.encounter-read-in-progress-id}" with error message "The requested encounter ${icuminimal.encounter-read-in-progress-id} is not contained in the response bundle."

  Scenario: Negative Search for the Encounter by Admission Date with the Search parameter 'date-start' and 'ge' Modifier and Patient
    When Get FHIR resource at "http://fhirserver/Encounter/?date-start=ge2026-01-14&patient=Patient/${icuminimal.account-read-patient-id}" with content type "xml"
    # encounter-read-in-progress-id has the start date 2026-01-06 in the test data, therefore it must not appear in the search results
    And bundle does not contain resource "Encounter" with ID "${icuminimal.encounter-read-in-progress-id}" with error message "The requested encounter ${icuminimal.encounter-read-in-progress-id} must not be returned here."

  Scenario: Negative Search for the Encounter by Admission Date with the Search parameter 'end-date' and 'le' Modifier and Patient
    When Get FHIR resource at "http://fhirserver/Encounter/?end-date=le2026-01-05&patient=Patient/${icuminimal.account-read-patient-id}" with content type "xml"
    # encounter-read-finished-id has end date 2026-01-08 in the test data, therefore it must not appear in the search results
    And bundle does not contain resource "Encounter" with ID "${icuminimal.encounter-read-finished-id}" with error message "The requested encounter ${icuminimal.encounter-read-finished-id} must not be returned here."

  Scenario: Search for the Encounter by Admission Date with both Search parameters 'date-start' and 'end-date' and Patient
    When Get FHIR resource at "http://fhirserver/Encounter/?date-start=ge2026-01-05&end-date=le2026-01-14&patient=Patient/${icuminimal.account-read-patient-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(period.start > @2026-01-05T00:00:00+01:00 and period.end < @2026-01-14T23:59:59+01:00).allTrue()" with error message 'There are search results, but they do not fully match the search criteria'
    # encounter-read-in-progress-id has the start date 2026-01-06 in the test data; therefore it must not appear in the search results
    And bundle does not contain resource "Encounter" with ID "${icuminimal.encounter-read-in-progress-id}" with error message "The requested encounter ${icuminimal.encounter-read-in-progress-id} must not be returned here."
    # encounter-read-finished-id has start date 2026-01-06 and end date 2026-01-08 in the test data, therefore it must appear in the bundle
    And response bundle contains resource with ID "${icuminimal.encounter-read-finished-id}" with error message "The requested encounter ${icuminimal.encounter-read-finished-id} is not contained in the response bundle."

  Scenario: Search for the Encounter by Admission Identifier
    When Get FHIR resource at "http://fhirserver/Encounter/?identifier=${icuminimal.encounter-read-in-progress-identifier-system}%7C${icuminimal.encounter-read-in-progress-identifier-value}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(identifier.where(value = '${icuminimal.encounter-read-in-progress-identifier-value}' and system = '${icuminimal.encounter-read-in-progress-identifier-system}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the Encounter by identifier.system
    When Get FHIR resource at "http://fhirserver/Encounter/?identifier=${icuminimal.encounter-read-in-progress-identifier-system}%7C" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(identifier.where(system = '${icuminimal.encounter-read-in-progress-identifier-system}').exists())" with error message 'There are search results, but they do not fully match the search criteria'

  Scenario: Search for the encounter by Location and Patient
    When Get FHIR resource at "http://fhirserver/Encounter/?location=Location/${icuminimal.encounter-read-in-progress-location}&patient=Patient/${icuminimal.patient-read-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath 'entry.resource.all(location.location.reference.replaceMatches("/_history/.+","").matches("\\b${icuminimal.encounter-read-in-progress-location}$"))' with error message 'There are search results, but they do not fully match the search criteria'
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "Encounter" is valid isik5 resource and conforms to profile "https://gematik.de/fhir/isik/StructureDefinition/ISiKKontaktGesundheitseinrichtung"

  Scenario: Search for the encounter by Service Provider and Patient
    When Get FHIR resource at "http://fhirserver/Encounter/?service-provider=${icuminimal.encounter-read-in-progress-service-provider}&patient=Patient/${icuminimal.patient-read-id}" with content type "json"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath 'entry.resource.all(serviceProvider.reference.replaceMatches("/_history/.+","").matches("\\b${icuminimal.encounter-read-in-progress-service-provider}$"))' with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${icuminimal.encounter-read-in-progress-id}" with error message "The requested Encounter ${icuminimal.encounter-read-in-progress-id} is not contained in the response bundle."

  @Optional
  Scenario: Optional Search for the Encounter by Tag and ID
    When Get FHIR resource at "http://fhirserver/Encounter/?_tag=${icuminimal.tag-system}%7C${icuminimal.tag-value}&_id=${icuminimal.encounter-read-in-progress-id}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(meta.tag.where(code='${icuminimal.tag-value}').exists())" with error message 'There are search results, but they do not fully match the search criteria'
    And response bundle contains resource with ID "${icuminimal.encounter-read-in-progress-id}" with error message "The requested Encounter ${icuminimal.encounter-read-in-progress-id} is not contained in the response bundle."

  @Optional
  Scenario: Optional Search for the Encounter by Has and ID
    When Get FHIR resource at "http://fhirserver/Encounter/?_id=${icuminimal.encounter-read-in-progress-id}&_has:Condition:encounter:code=${icuminimal.condition-read-active-code}" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'No search results were found'
    And response bundle contains resource with ID "${icuminimal.encounter-read-in-progress-id}" with error message "The requested Encounter ${icuminimal.encounter-read-in-progress-id} is not contained in the response bundle."
