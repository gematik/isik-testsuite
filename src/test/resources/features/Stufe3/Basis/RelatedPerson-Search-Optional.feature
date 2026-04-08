@Stufe3
@Basis
@Optional
@RelatedPerson-Search-Optional
Feature: Testen von KANN-Suchparametern gegen relatedperson-read (@RelatedPerson-Search-Optional)

  @vorbedingung
  @Optional
  Scenario: Vorbedingung
    Given Testbeschreibung: "Das zu testende System MUSS die zuvor angelegte Ressource bei einer Suche anhand des Parameters finden und in den Suchergebnissen zurückgeben (SEARCH)."
    Given Mit den Vorbedingungen:
    """
        - Der Testfall RelatedPerson-Read muss zuvor erfolgreich ausgeführt worden sein.
    """

  @Optional
  Scenario: Read und Validierung des CapabilityStatements
    Then Get FHIR resource at "http://fhirserver/metadata" with content type "xml"
    And FHIR current response body evaluates the FHIRPaths:
    """
      rest.where(mode = "server").resource.where(type = "RelatedPerson" and interaction.where(code = "search-type").exists()).exists()
      rest.where(mode = "server").resource.where(type = "RelatedPerson" and searchParam.where(name = "name" and type = "string").exists()).exists()
      rest.where(mode = "server").resource.where(type = "RelatedPerson" and searchParam.where(name = "address" and type = "string").exists()).exists()
      rest.where(mode = "server").resource.where(type = "RelatedPerson" and searchParam.where(name = "address-city" and type = "string").exists()).exists()
      rest.where(mode = "server").resource.where(type = "RelatedPerson" and searchParam.where(name = "address-country" and type = "string").exists()).exists()
      rest.where(mode = "server").resource.where(type = "RelatedPerson" and searchParam.where(name = "address-postalcode" and type = "string").exists()).exists()
    """

  @Optional
  Scenario: Suche nach Angehoerigen anhand des Vornamens
    Then Get FHIR resource at "http://fhirserver/RelatedPerson/?name=Maxine" with content type "xml"
    And response bundle contains resource with ID "${data.relatedperson-read-id}" with error message "Die gesuchte Angehoerige ${data.relatedperson-read-id} ist nicht im Responsebundle enthalten"
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(name.given contains 'Maxine')" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'
    And FHIR current response body is a valid CORE resource and conforms to profile "https://hl7.org/fhir/StructureDefinition/Bundle"
    And Check if current response of resource "RelatedPerson" is valid isik3-basismodul resource and conforms to profile "https://gematik.de/fhir/isik/v3/Basismodul/StructureDefinition/ISiKAngehoeriger"

  @Optional
  Scenario: Suche nach Angehoerigen anhand der Adresse (Stadt)
    Then Get FHIR resource at "http://fhirserver/RelatedPerson/?address-city=Berlin" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(city = 'Berlin').exists())" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

  @Optional
  Scenario: Suche nach Angehoerigen anhand der Adresse (Land)
    Then Get FHIR resource at "http://fhirserver/RelatedPerson/?address-country=DE" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(country = 'DE').exists())" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'

  @Optional
  Scenario: Suche nach Angehoerigen anhand der Adresse (Postleitzahl)
    Then Get FHIR resource at "http://fhirserver/RelatedPerson/?address-postalcode=10117" with content type "xml"
    And FHIR current response body evaluates the FHIRPath 'entry.resource.count() > 0' with error message 'Es wurden keine Suchergebnisse gefunden'
    And FHIR current response body evaluates the FHIRPath "entry.resource.all(address.where(postalCode.contains('10117')).exists())" with error message 'Es gibt Suchergebnisse, diese passen allerdings nicht vollständig zu den Suchkriterien.'
