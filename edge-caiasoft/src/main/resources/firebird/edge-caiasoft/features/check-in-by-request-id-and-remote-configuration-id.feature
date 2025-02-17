Feature: test Caiasoft check in by request id and remote storage id

  Background:
    * url baseUrl
    * callonce login { tenant: 'diku', name: 'diku_admin', password: 'admin' }
    * callonce variables
    * def headers = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapitoken)', 'Accept': '*/*'  }

  Scenario: create test data
    Given path '/remote-storage/configurations'
    And headers headers
    And request
    """
    {
        "id": "#(remoteStorageId)",
        "name": "RSTest",
        "providerName": "CAIA_SOFT",
        "url": "http://endpoint",
        "accessionDelay": 2,
        "accessionTimeUnit": "minutes",
        "accessionWorkflowDetails": "Change permanent location"
    }
    """
    When method POST
    Then status 201

    Given path 'remote-storage/mappings'
    And headers headers
    And request
    """
    {
      "folioLocationId": "#(remoteFolioLocationId)",
      "configurationId": "#(remoteStorageId)"
    }
    """
    When method POST
    Then status 201


    Given path '/inventory/instances'
    And headers headers
    And request
    """
    {
        "id": "#(instanceId)",
        "source": "FOLIO",
        "title": "Interesting Times",
        "alternativeTitles": [],
        "editions": [],
        "series": [],
        "instanceTypeId": "#(instanceTypeId)"
    }
    """
    When method POST
    Then status 201

    Given path 'holdings-storage/holdings'
    And headers headers
    And request
    """
    {
        "id": "#(holdingsRecordId)",
        "formerIds": [],
        "instanceId": "#(instanceId)",
        "permanentLocationId": "#(remoteFolioLocationId)",
        "effectiveLocationId": "#(remoteFolioLocationId)",
        "electronicAccess": [],
        "callNumber": "PR6056.I4588 B749 2016"
    }
    """
    When method POST
    Then status 201

    Given path 'inventory/items'
    And headers headers
    And request
    """
    {
        "id": "#(itemId)",
        "title": "A semantic web primer",
        "status": {
            "name": "Available",
            "date": "2021-05-12T03:22:24.508+00:00"
        },
        "callNumber": "TK5105.88815 . A58 2004 FT MEADE",
        "contributorNames": [
            {
                "name": "Antoniou, Grigoris"
            },
            {
                "name": "Van Harmelen, Frank"
            }
        ],
        "formerIds": [],
        "discoverySuppress": null,
        "holdingsRecordId": "#(holdingsRecordId)",
        "barcode": "#(itemBarcode)",
        "itemLevelCallNumber": "TK5105.88815 . A58 2004 FT MEADE",
        "materialType": {
            "id": "1a54b431-2e4f-452d-9cae-9cee66c9a892",
            "name": "book"
        },
          "permanentLoanType": {
            "id": "2b94c631-fca9-4892-a730-03ee529ffe27",
            "name": "Can Circulate"
        },
        "permanentLocation": {
            "id": "#(remoteFolioLocationId)",
            "name": "Main Library"
        }
    }
    """
    When method POST
    Then status 201

    Given path '/groups'
    And headers headers
    And request
    """
      {
         "group": "#(caiasoftGroupName)",
         "desc": "basic caiasoft test group",
         "expirationOffsetInDays": 365,
         "id": "#(caiasoftGroupId)"
      }
    """
    When method POST
    Then status 201

    Given path '/users'
    And headers headers
    And request
    """
    {
        "id": "#(requesterId)",
        "type": "patron",
        "active": true,
        "barcode": "2720954947208678280",
        "personal": {
            "lastName": "testUser",
            "addresses": [],
            "firstName": "testUserCaiasoft"
        },
        "proxyFor": [],
        "username": "testUserCaiasoft",
        "departments": [],
        "patronGroup": "#(caiasoftGroupId)"
    }
    """
    When method POST
    Then status 201

    Given path '/request-policy-storage/request-policies'
    And headers headers
    And request
    """
    {
        "id": "#(caiasoftPageRequestPolicyId)",
        "name": "#(caiasoftPageRequestPolicyName )",
        "description" : "description",
        "requestTypes": [
            "Page"
        ]
    }
    """
    When method POST
    Then status 201

    * def caiasoftRules = '\n\ng ' + caiasoftGroupId + ' : l d9cd0bed-1b49-4b5e-a7bd-064b8d177231 r ' + caiasoftPageRequestPolicyId + ' n 122b3d2b-4788-4f1e-9117-56daa91cb75c o cd3f6cac-fa17-4079-9fae-2fb28e521412 i ed892c0e-52e0-4cd9-8133-c0ef07b4a709'
    Given path '/circulation/rules'
    And headers headers
    When method GET
    Then status 200
    * def body = $
    * def initialCirculationRules = body.rulesAsText
    * def newRules = body.rulesAsText + caiasoftRules
    * set body.rulesAsText = newRules

    Given path '/circulation/rules'
    And headers headers
    And request body
    When method PUT
    Then status 204

    * call pause 5

    Given path '/circulation/requests'
    And headers headers
    And request
    """
    {
      "id": "#(requestId)",
      "requestType": "Page",
      "requestDate": "2017-07-29T22:25:37Z",
      "requesterId": "#(requesterId)",
      "requestLevel": "Item",
      "instanceId": "#(instanceId)",
      "holdingsRecordId": "#(holdingsRecordId)",
      "itemId": "#(itemId)",
      "fulfilmentPreference": "Hold Shelf",
      "requestExpirationDate": "2025-07-25T22:25:37Z",
      "pickupServicePointId":"3a40852d-49fd-4df2-a1f9-6e2641a6e91f",
      "position": 1
    }
    """
    When method POST
    Then status 201

    * set body.rulesAsText = initialCirculationRules

    Given path '/circulation/rules'
    And headers headers
    And request body
    When method PUT
    Then status 204

    * call pause 5

  Scenario: check in by requestId and remoteStorageId
    Given url edgeUrl
    And path '/caiasoftService/Requests/', requestId, '/route/', remoteStorageId
    And param apikey = apikey
    And request ''
    When method POST
    Then status 200

  Scenario: clean test remote storage
    Given path '/remote-storage/configurations', remoteStorageId
    And headers headers
    When method DELETE
    Then status 204

  Scenario: clean test mapping
    Given path '/remote-storage/mappings', remoteFolioLocationId
    And headers headers
    When method DELETE
    Then status 204

  Scenario: clean test item

    Given path 'inventory/items', itemId
    And headers headers
    When method DELETE
    Then status 204

  Scenario: clean test holding record

    Given path 'holdings-storage/holdings', holdingsRecordId
    And headers headers
    When method DELETE
    Then status 204

  Scenario: clean test instance

    Given path 'inventory/instances', instanceId
    And headers headers
    When method DELETE
    Then status 204

  Scenario: clean test request

    Given path 'circulation/requests', requestId
    And headers headers
    When method DELETE
    Then status 204

  Scenario: clean test requester

    Given path 'users/', requesterId
    And headers headers
    When method DELETE
    Then status 204

   Scenario: clean test group

     Given path '/groups/', caiasoftGroupId
     And headers headers
     When method DELETE
     Then status 204

   Scenario: clean test policy

     Given path '/request-policy-storage/request-policies/', caiasoftPageRequestPolicyId
     And headers headers
     When method DELETE
     Then status 204

