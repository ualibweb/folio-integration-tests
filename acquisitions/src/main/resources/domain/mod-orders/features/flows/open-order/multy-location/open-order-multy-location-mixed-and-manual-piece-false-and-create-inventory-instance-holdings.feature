Feature: open-order-multy-location-mixed-and-manual-piece-false-and-create-inventory-instance-holdings.

  Background:
    * url baseUrl
    # uncomment below line for development
    * callonce dev {tenant: 'test_orders'}
    * callonce login testAdmin
    * def okapitokenAdmin = okapitoken
    * print okapitokenAdmin

    * callonce login testUser
    * def okapitokenUser = okapitoken

    * def headersUser = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapitokenUser)', 'Accept': 'application/json'  }
    * def headersAdmin = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapitokenAdmin)', 'Accept': 'application/json'  }

    * configure headers = headersUser

    # load global variables
    * callonce variables

    * def orderId = callonce uuid1
    * def poLineId = callonce uuid2

    * def fundId = callonce uuid3
    * def budgetId = callonce uuid4

    * configure retry = { count: 4, interval: 1000 }

  Scenario: Create finances
    * call createFund { 'id': '#(fundId)'}
    * call createBudget { 'id': '#(budgetId)', 'allocated': 10000, 'fundId': '#(fundId)'}

  Scenario: Create One-time order
    Given path 'orders/composite-orders'
    And request
    """
    {
      id: '#(orderId)',
      vendor: '#(globalVendorId)',
      orderType: 'One-Time'
    }
    """
    When method POST
    Then status 201

  Scenario: Create order line
    Given path 'orders/order-lines'

    * def orderLine = read('classpath:samples/mod-orders/orderLines/minimal-mixed-order-line.json')
    * set orderLine.id = poLineId
    * set orderLine.purchaseOrderId = orderId
    * set orderLine.cost.quantityPhysical = '2'
    * set orderLine.cost.quantityElectronic = '2'
    * set orderLine.locations[1] = { 'quantity': '2', 'locationId': '#(globalLocationsId2)', 'quantityPhysical': '1', 'quantityElectronic': '1'}
    * set orderLine.physical.createInventory = 'Instance, Holding'
    * set orderLine.eresource.createInventory = 'Instance, Holding'
    And request orderLine
    When method POST
    Then status 201
  Scenario: Open order
    Given path 'orders/composite-orders', orderId
    When method GET
    Then status 200

    * def orderResponse = $
    * set orderResponse.workflowStatus = "Open"
    * set orderResponse.compositePoLines[*].fundDistribution[*].fundId = fundId

    Given path 'orders/composite-orders', orderId
    And request orderResponse
    When method PUT
    Then status 204
    * call pause(1000)

    Given path 'orders/composite-orders', orderId
    When method GET
    Then status 200

    * def orderResponse = $
    * match orderResponse.workflowStatus == "Open"

  #Precondition :
    #Manual add pieces is FALSE - means we need to create pieces from code
    #Create inventory is Instance - means don't create anything in the inventory
  Scenario: Check that instances, items, pieces, holdings were created
    Given path 'orders/order-lines', poLineId
    When method GET
    Then status 200
    * def poLineResp = $
    * def instanceId = poLineResp.instanceId
    * def poLineNumber = poLineResp.poLineNumber
    * def poLineHoldingId = poLineResp.locations[0].holdingId
    * def poLineHoldingId2 = poLineResp.locations[1].holdingId
    #If CreateInventory == Instance, Holding or Instance, Holding, Items, then replace locationId with holdingId
    * match poLineResp.locations[0] !contains { locationId: '#notnull' }
    * match poLineResp.locations[1] !contains { locationId: '#notnull' }

    #Check that InstanceId and poLineId were copied into Title
    Given path 'orders-storage/titles'
    And param limit = 15
    And param offset = 0
    And param lang = 'en'
    And param query = 'poLineId==' + poLineId
    When method GET
    Then status 200
    * def titles = $.titles
    * def titleId = titles[0].id
    And match $.totalRecords == 1
    And match titles[0].poLineId == "#(poLineId)"
    And match titles[0].poLineNumber == "#(poLineNumber)"
    And match titles[0].instanceId == "#(instanceId)"

      #Retrieve order line items location
    Given path 'inventory/items'
    And param query = 'purchaseOrderLineIdentifier==' + poLineId
    When method GET
    Then status 200
    * def items = $.items
    And match $.totalRecords == 0

    Given path 'orders-storage/pieces'
    And param query = 'poLineId==' + poLineId
    When method GET
    Then status 200
    * def pieces = $.pieces
    #Piece must contain link on poLine, title and doesn't contain link on item
      # Piece without location, because Holding was not created and no storage space
      # Quantity of the piece must be the same with poLine physical quantity
    And match $.totalRecords == 4
    * def pieceElec1 = karate.jsonPath(response, "$.pieces[*][?(@.format == 'Electronic')]")[0]
    * def pieceElec2 = karate.jsonPath(response, "$.pieces[*][?(@.format == 'Electronic')]")[1]
    * def piecePhys1 = karate.jsonPath(response, "$.pieces[*][?(@.format == 'Physical')]")[0]
    * def piecePhys2 = karate.jsonPath(response, "$.pieces[*][?(@.format == 'Physical')]")[1]
    #Piece after creation must be "Expected"
    And match pieceElec1 contains {"poLineId": "#(poLineId)", "titleId": "#(titleId)", "receivingStatus": "Expected"}
    And match pieceElec2 contains {"poLineId": "#(poLineId)", "titleId": "#(titleId)", "receivingStatus": "Expected"}
    And match piecePhys1 contains {"poLineId": "#(poLineId)", "titleId": "#(titleId)", "receivingStatus": "Expected"}
    And match piecePhys2 contains {"poLineId": "#(poLineId)", "titleId": "#(titleId)", "receivingStatus": "Expected"}

  #Holding must be created by unique pair : locationId and instanceId
    Given path 'holdings-storage/holdings'
    And param query = 'instanceId==' + instanceId
    When method GET
    Then status 200
    * def holdingsRecords = $.holdingsRecords
    And match $.totalRecords == 2
    * def holdingsRecord1 = karate.jsonPath(response, "$.holdingsRecords[*][?(@.permanentLocationId == '"+globalLocationsId+"')]")[0]
    * def holdingsRecord2 = karate.jsonPath(response, "$.holdingsRecords[*][?(@.permanentLocationId == '"+globalLocationsId2+"')]")[0]
    And match holdingsRecord1 contains {"instanceId": "#(instanceId)", "permanentLocationId": "#(globalLocationsId)"}
    And match holdingsRecord2 contains {"instanceId": "#(instanceId)", "permanentLocationId": "#(globalLocationsId2)"}
    And match holdingsRecord1.id == "#(poLineHoldingId)"

  Scenario: delete poline
    Given path 'orders/order-lines', poLineId
    When method DELETE
    Then status 204

  Scenario: delete composite orders
    Given path 'orders/composite-orders', orderId
    When method DELETE
    Then status 204

