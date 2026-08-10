# language: en
@Stufe5
@Connect
@Mandatory
@Smart-Capabilities
Feature: Test of SMART Capabilities (@Smart-Capabilities)

  @Precondition
  Scenario: Precondition
    Given the Test Description: "The system under test must support the SMART-on-FHIR Authentication flow."
    Given the Preconditions:
    """
     A FHIR Resource Server must support the SMART-on-FHIR configuration requirements
    """

  Scenario: Access to SMART-on-FHIR metadata is allowed and content is complete
    When TGR send empty GET request to "http://fhirserver/.well-known/smart-configuration"
    And TGR find the last request
    Then TGR current response with attribute "$.responseCode" matches "200"
    And TGR current response with attribute "$.header.Content-Type" matches ".*application/json.*"
    And TGR current response with attribute "$.body.authorization_endpoint" matches "http[s]?://.*"
    And TGR current response with attribute "$.body.issuer" matches "http[s]?://.*"
    And TGR current response with attribute "$.body.token_endpoint" matches "http[s]?://.*"
    And TGR current response with attribute "$.body.grant_types_supported" matches ".*authorization_code.*"
    And TGR current response with attribute "$.body.grant_types_supported" matches ".*client_credentials.*"
    And TGR current response contains node "$.body.capabilities"
    And TGR current response contains node "$.body.scopes_supported"
    And TGR current response with attribute "$.body.code_challenge_methods_supported" matches ".*S256.*"
    But TGR current response with attribute "$.body.code_challenge_methods_supported" does not match ".*plain.*"