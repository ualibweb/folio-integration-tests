Feature: Test codex instances

  Background:
    * url baseUrl

    * callonce login testUser
    * def okapiUserToken = okapitoken

    * def headersUser = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapiUserToken)', 'Accept': '*/*' }
    * configure headers = headersUser

  Scenario: Test GET codex-instances
    Given path 'codex-instances'
    When method GET
    Then status 200

#  Scenario: Test GET codex-instances should return 400 if malformed query parameter
#    Given path 'codex-instances'
#    When method GET
#    Then status 400
#
#  Scenario: Test GET codex-instances should return 422 if validation error
#    Given path 'codex-instances'
#    When method GET
#    Then status 422
#
#  Scenario: Test GET codex-instance by id
#    Given path 'codex-instances/1'
#    When method GET
#    Then status 200
#
#  Scenario: Test GET codex-instance by id should return 404 if item with given id not found
#    Given path 'codex-instances/1'
#    When method GET
#    Then status 404
#
#  Scenario: Test GET codex-instances-sources
#    Given path 'codex-instances-sources'
#    When method GET
#    Then status 200
#
#  Scenario: Test GET codex-instances-sources should return 400 if malformed query parameter
#    Given path 'codex-instances-sources'
#    When method GET
#    Then status 400
