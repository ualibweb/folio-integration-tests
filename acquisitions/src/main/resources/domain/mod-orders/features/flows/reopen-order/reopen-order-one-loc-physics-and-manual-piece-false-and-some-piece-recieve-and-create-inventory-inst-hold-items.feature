Feature: reopen-order-one-loc-physics-and-manual-piece-false-and-some-piece-recieve-and-create-inventory-inst-hold-items.

  Background:
    * url baseUrl
    # uncomment below line for development
    #* callonce dev {tenant: 'test_orders'}
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

 #    * def encumbrance1 = karate.jsonPath(response, "$.transactions[?(@.encumbrance.sourcePoLineId=='"+orderLineIdOne+"')]")[0]
#    * def encumbrance2 = karate.jsonPath(response, "$.transactions[?(@.encumbrance.sourcePoLineId=='"+unOpenOrderLineId+"')]")[0]
#    * def expenseClass1Totals = karate.jsonPath(response, "$.budgetExpenseClassTotals[*][?(@.expenseClassName == 'Print')]")
#    * def expenseClass2Totals = karate.jsonPath(response, "$.budgetExpenseClassTotals[*][?(@.expenseClassName == 'Electronic')]")
#    And match expenseClass1Totals[0] contains { "expended": 80.0, "percentageExpended": 40.0 }
#    And match expenseClass2Totals[0] contains { "expended": 120.0, "percentageExpended": 60.0 }
# And match each response.budgetExpenseClassTotals contains {"encumbered": 65.11, "awaitingPayment": 0.6, "expended": 0.00, "percentageExpended": "#notpresent"}
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

    * def orderLine = read('classpath:samples/mod-orders/orderLines/minimal-order-line.json')
    * set orderLine.id = poLineId
    * set orderLine.purchaseOrderId = orderId
    * set orderLine.cost.quantityPhysical = 2
    * set orderLine.locations[0] = { 'quantity': '2', 'locationId': '#(globalLocationsId)', 'quantityPhysical': '2'}
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
    * call pause(3000)

  #Precondition :
    #Manual add pieces is FALSE - means we need to create pieces from code
  Scenario: Check that instances, items, pieces, holdings were created
    Given path 'orders/order-lines', poLineId
    When method GET
    Then status 200
    * def poLineResp = $
    * def instanceId = poLineResp.instanceId
    * def poLineNumber = poLineResp.poLineNumber
    * def poLineHoldingId = poLineResp.locations[0].holdingId
    #If CreateInventory == Instance, Holding or Instance, Holding, Items, then replace locationId with holdingId
    * match poLineResp.locations[0] !contains { locationId: '#notnull' }

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
    And match $.totalRecords == 2
    * def item1 = items[0]
    * def item2 = items[1]
    * def itemId1 = item1.id
    * def itemId2 = item2.id
    And match item1.effectiveLocation.id == "#(globalLocationsId)"
    And match item1.status.name == "On order"
    And match item2.effectiveLocation.id == "#(globalLocationsId)"
    And match item1.holdingsRecordId == "#(poLineHoldingId)"
    And match item2.holdingsRecordId == "#(poLineHoldingId)"
    And match item2.status.name == "On order"

    Given path 'orders-storage/pieces'
    And param query = 'poLineId==' + poLineId
    When method GET
    Then status 200
    * def pieces = $.pieces
    #Piece must contain link on location, poLine, title and item in inventory
    #Quantity of the piece must be the same with poLine physical quantity
    And match $.totalRecords == 2
    * def piece1 = karate.jsonPath(response, '$.pieces[*][?(@.itemId == "' + itemId1 + '")]')[0]
    * def piece2 = karate.jsonPath(response, '$.pieces[*][?(@.itemId == "' + itemId2 + '")]')[0]
    #Piece after creation must be "Expected"
    And match piece1 contains {"locationId": "#(globalLocationsId)", "poLineId": "#(poLineId)", "titleId": "#(titleId)", "receivingStatus": "Expected"}
    And match piece2 contains {"locationId": "#(globalLocationsId)", "poLineId": "#(poLineId)", "titleId": "#(titleId)", "receivingStatus": "Expected"}


  #Holding must be created by unique pair : locationId and instanceId
    Given path 'orders/check-in'
    * def checkIn = read('classpath:samples/mod-orders/check-in/check-in-one.json')
    * set checkIn.toBeCheckedIn[0].poLineId = poLineId
    * set checkIn.toBeCheckedIn[0].checkInPieces[0].id = piece1.id
    * set checkIn.toBeCheckedIn[0].checkInPieces[0].locationId = piece1.locationId
    And request checkIn
    When method POST
    Then status 200
    And match $.totalRecords == 1
    And match $.receivingResults[0].processedSuccessfully == 1
    And match $.receivingResults[0].receivingItemResults[0].processingStatus.type == "success"

     #Retrieve order line items location
    Given path 'inventory/items'
    And param query = 'purchaseOrderLineIdentifier==' + poLineId
    When method GET
    Then status 200
    * def items = $.items
    And match $.totalRecords == 2
    * def item1 = karate.jsonPath(response, '$.items[*][?(@.status.name == "In process")]')[0]
    * def item2 = karate.jsonPath(response, '$.items[*][?(@.status.name == "On order")]')[0]
    * def itemId1 = item1.id
    * def itemId2 = item2.id
    And match item1.effectiveLocation.id == "#(globalLocationsId)"
    And match item1.status.name == "In process"
    And match item2.effectiveLocation.id == "#(globalLocationsId)"
    And match item1.holdingsRecordId == "#(poLineHoldingId)"
    And match item2.holdingsRecordId == "#(poLineHoldingId)"
    And match item2.status.name == "On order"


    #Holding must be created by unique pair : locationId and instanceId
    Given path 'holdings-storage/holdings'
    And param query = 'instanceId==' + instanceId
    When method GET
    Then status 200
    * def holdingsRecords = $.holdingsRecords
    And match $.totalRecords == 1
    And match holdingsRecords[0] contains {"id": "#(poLineHoldingId)", "instanceId": "#(instanceId)", "permanentLocationId": "#(globalLocationsId)"}


  Scenario: Close order and release encumbrances
    # ============= get order to close ===================
    Given path 'orders-storage/purchase-orders', orderId
    And retry until response.workflowStatus == "Open"
    When method GET
    Then status 200
    * def orderResponse = $
    * remove orderResponse.compositePoLines
    * print "PRINT " + orderResponse
    * set orderResponse.workflowStatus = "Closed"

    # ============= update order to close ===================
    Given path 'orders/composite-orders', orderId
    And request orderResponse
    When method PUT
    Then status 204

    Given path 'orders/composite-orders', orderId
    And retry until response.workflowStatus == "Closed"
    When method GET
    Then status 200
    * match $.workflowStatus == "Closed"

  Scenario: Reopen the order
    Given path 'orders/composite-orders', orderId
    When method GET
    Then status 200
    And match $.workflowStatus == 'Closed'

    * def orderResponse = $
    * set orderResponse.workflowStatus = 'Open'

    Given path 'orders/composite-orders', orderId
    And request orderResponse
    When method PUT
    Then status 204

  Scenario: After order is closed, then received Piece/Item status should not be changed
       #Retrieve order line items location
    Given path 'inventory/items'
    And param query = 'purchaseOrderLineIdentifier==' + poLineId
    When method GET
    Then status 200
    * def items = $.items
    And match $.totalRecords == 2
    * def item1 = karate.jsonPath(response, '$.items[*][?(@.status.name == "In process")]')[0]
    * def item2 = karate.jsonPath(response, '$.items[*][?(@.status.name == "On order")]')[0]
    * def itemId1 = item1.id
    * def itemId2 = item2.id
    And match item1.effectiveLocation.id == "#(globalLocationsId)"
    And match item1.status.name == "In process"
    And match item2.effectiveLocation.id == "#(globalLocationsId)"
    And match item2.status.name == "On order"

    Given path 'orders-storage/pieces'
    And param query = 'poLineId==' + poLineId
    When method GET
    Then status 200
    * def pieces = $.pieces
    #Piece must contain link on location, poLine, title and item in inventory
    #Quantity of the piece must be the same with poLine physical quantity
    And match $.totalRecords == 2
    * def piece1 = karate.jsonPath(response, '$.pieces[*][?(@.itemId == "' + itemId1 + '")]')[0]
    * def piece2 = karate.jsonPath(response, '$.pieces[*][?(@.itemId == "' + itemId2 + '")]')[0]
    #Piece after creation must be "Expected"
    And match piece1 contains {"locationId": "#(globalLocationsId)", "poLineId": "#(poLineId)", "receivingStatus": "Received"}
    And match piece2 contains {"locationId": "#(globalLocationsId)", "poLineId": "#(poLineId)", "receivingStatus": "Expected"}

  Scenario: delete poline
    Given path 'orders/order-lines', poLineId
    When method DELETE
    Then status 204

  Scenario: delete composite orders
    Given path 'orders/composite-orders', orderId
    When method DELETE
    Then status 204

