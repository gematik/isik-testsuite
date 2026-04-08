@Stufe3
@Basis
@Mandatory
@RelatedPerson-Read
Feature: Lesen der Ressource RelatedPerson (@RelatedPerson-Read)

  @vorbedingung
  Scenario: Vorbedingung
    Given Testbeschreibung: "Das zu testende System MUSS die angelegte Ressource bei einem HTTP GET auf deren URL korrekt und vollständig zurückgeben (READ)."
    Given Mit den Vorbedingungen:
    """
        - der Testdatensatz muss im zu testenden System gemäß der Vorgaben (manuell) erfasst worden sein.
        - die ID der korrespondierenden FHIR-Ressource zu diesem Testdatensatz muss in der Konfigurationsvariable 'relatedperson-read-id' hinterlegt sein.

        Testdatensatz (Name: Wert)
        Legen Sie folgende Angehörige in Ihrem System an:
        Vorname: Maxine
        Nachname: Mustermann
        Addresse: Unter den Linden 3, 10117 Berlin, Deutschland
        Patientenbezug: Der Patient aus Testfall Patient-Read
    """

  Scenario: Read und Validierung des CapabilityStatements
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "json"
    And CapabilityStatement contains interaction "read" for resource "RelatedPerson"

  Scenario: Read einer RelatedPerson-Ressource anhand ihrer ID
    Then Get FHIR resource at "http://fhirserver/RelatedPerson/${data.relatedperson-read-id}" with content type "xml"
    And resource has ID "${data.relatedperson-read-id}"
    And FHIR current response body is a valid isik3-basismodul resource and conforms to profile "https://gematik.de/fhir/isik/v3/Basismodul/StructureDefinition/ISiKAngehoeriger"
    And TGR current response with attribute "$..name.given.value" matches "Maxine"
    And TGR current response with attribute "$..name.family.value" matches "Mustermann"
    And FHIR current response body evaluates the FHIRPath "address.where(type = 'both' and city = 'Berlin' and postalCode = '10117' and country = 'DE' and line = 'Unter den Linden 3' and line.extension.where(url = 'http://hl7.org/fhir/StructureDefinition/iso21090-ADXP-streetName' and value = 'Unter den Linden').exists() and line.extension.where(url = 'http://hl7.org/fhir/StructureDefinition/iso21090-ADXP-houseNumber' and value = '3').exists()).exists()" with error message 'Die Adresse entspricht nicht dem Erwartungswert'
    And element "patient" references resource with ID "${data.patient-read-id}" with error message "${data.patient-read-id} ist nicht als Patient eingetragen"
