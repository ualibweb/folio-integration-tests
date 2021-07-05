Feature: UnOpen order with one line and check that items, holdings were not created

  Background:
    * url baseUrl
    # uncomment below line for development
    #* callonce dev {tenant: 'test_orders1'}
    * callonce loginAdmin testAdmin
    * def okapitokenAdmin = okapitoken

    * callonce loginRegularUser testUser
    * def okapitokenUser = okapitoken

    * def headersUser = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapitokenUser)', 'Accept': '*/*'  }
    * def headersAdmin = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapitokenAdmin)', 'Accept': 'application/json'  }

    * configure headers = headersUser
    # load global variables
    * callonce variables

    * def orderId = callonce uuid1
    * def poLineId = callonce uuid2

  Scenario: Create orders
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

  Scenario Outline: Create order lines for <orderLineId>
    * def orderId = <orderId>
    * def poLineId = <orderLineId>
   Given path 'orders/order-lines'
    * def orderLine = read('classpath:samples/mod-orders/orderLines/minimal-physical-order-line.json')
    * set orderLine.id = poLineId
    * set orderLine.purchaseOrderId = orderId
    * set orderLine.physical.createInventory = 'Instance'
    And request orderLine
    When method POST
    Then status 201

    Examples:
      | orderId | orderLineId    |
      | orderId | poLineId |

  Scenario: Open order
    # ============= get order to open ===================
    Given path 'orders/composite-orders', orderId
    When method GET
    Then status 200

    * def orderResponse = $
    * set orderResponse.workflowStatus = "Open"

    # ============= update order to open ===================
    Given path 'orders/composite-orders', orderId
    And request orderResponse
    When method PUT
    Then status 204

  Scenario: Check that order status Open in encumbrance after Open order
    Given path 'finance/transactions'
    And param query = 'transactionType==Encumbrance and encumbrance.sourcePurchaseOrderId==' + orderId
    When method GET
    Then status 200
    * def transaction = karate.jsonPath(response, "$.transactions[?(@.encumbrance.sourcePoLineId=='"+poLineId+"')]")[0]
    And match transaction.amount == 1.0
    And match transaction.currency == 'USD'
    And match transaction.encumbrance.initialAmountEncumbered == 1.0
    And match transaction.encumbrance.status == 'Unreleased'
    And match transaction.encumbrance.orderStatus == 'Open'

  Scenario: UnOpen order
    # ============= get order to open ===================
    Given path 'orders/composite-orders', orderId
    When method GET
    Then status 200

    * def orderResponse = $
    * set orderResponse.workflowStatus = "Pending"

    # ============= update order to open ===================
    Given path 'orders/composite-orders', orderId
    And request orderResponse
    When method PUT
    Then status 204

  Scenario: Check order workflow status is Pending after UnOpen
    # ============= get order to open ===================
    Given path 'orders/composite-orders', orderId
    When method GET
    Then status 200
    * def orderResponse = $
    And match orderResponse.workflowStatus == "Pending"

  Scenario: Check that order status Pending in encumbrance after UnOpen order
    Given path 'finance/transactions'
    And param query = 'transactionType==Encumbrance and encumbrance.sourcePurchaseOrderId==' + orderId
    When method GET
    Then status 200
    * def transaction = karate.jsonPath(response, "$.transactions[?(@.encumbrance.sourcePoLineId=='"+poLineId+"')]")[0]
    And match transaction.amount == 0
    And match transaction.currency == 'USD'
    And match transaction.encumbrance.initialAmountEncumbered == 0
    And match transaction.encumbrance.status == 'Pending'
    And match transaction.encumbrance.orderStatus == 'Pending'

 #Precondition :
    #Manual add pieces is FALSE - means we need to create pieces from code
  Scenario: Check that instances, items, pieces, holdings were created
    * configure headers = headersAdmin
    Given path 'orders/order-lines', poLineId
    When method GET
    Then status 200
    * def poLineResp = $
    * def instanceId = poLineResp.instanceId
    * def poLineNumber = poLineResp.poLineNumber
    #If CreateInventory == None or Instance, then don't replace locationId with holdingId
    * match poLineResp.locations[0].locationId == "#(globalLocationsId)"
    * match poLineResp.locations[0] !contains { holdingId: '#notnull' }

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
    And match $.totalRecords == 0

  #Holding must be created by unique pair : locationId and instanceId
    Given path 'holdings-storage/holdings'
    And param query = 'instanceId==' + instanceId
    When method GET
    Then status 200
    * def holdingsRecords = $.holdingsRecords
    And match $.totalRecords == 0

  Scenario: delete poline
    Given path 'orders/order-lines', poLineId
    When method DELETE
    Then status 204

  Scenario: delete composite orders
    Given path 'orders/composite-orders', orderId
    When method DELETE
    Then status 204