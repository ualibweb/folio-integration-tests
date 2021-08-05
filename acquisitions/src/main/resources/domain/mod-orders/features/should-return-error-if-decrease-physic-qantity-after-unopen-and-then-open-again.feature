Feature: Check that after unopen order we can decrease quantity and in open order time error will be returned.

  Background:
    * url baseUrl
    # uncomment below line for development
    * callonce dev {tenant: 'test_orders3'}
    * callonce loginAdmin testAdmin
    * def okapitokenAdmin = okapitoken
    * print okapitokenAdmin

    * callonce loginRegularUser testUser
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
    * configure headers = headersAdmin
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
    * set orderLine.locations[0].quantityPhysical = 2
    * set orderLine.locations[0].quantity = 2
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

  Scenario: Retrieve order line items before update location
    * configure headers = headersAdmin
    Given path 'inventory/items'
    And param query = 'purchaseOrderLineIdentifier==' + poLineId
    When method GET
    Then status 200
    * def items = $.items
    And match $.totalRecords == 2
    And match items[*].effectiveLocation.id == ["#(globalLocationsId)", "#(globalLocationsId)"]


  Scenario: Retrieve order line pieces before update location
    Given path 'orders-storage/pieces'
    And param query = 'poLineId==' + poLineId
    When method GET
    Then status 200
    * def pieces = $.pieces
    And match $.totalRecords == 2
    And match pieces[*].locationId == ["#(globalLocationsId)", "#(globalLocationsId)"]

  Scenario: UnOpen order
    Given path 'orders/composite-orders', orderId
    When method GET
    Then status 200

    * def orderResponse = $
    * set orderResponse.workflowStatus = "Pending"

    Given path 'orders/composite-orders', orderId
    And request orderResponse
    And header X-Okapi-Permissions = 'orders.item.unopen'
    When method PUT
    Then status 204

  Scenario: Get poLine and decrease order line physical quantity
    Given path 'orders/order-lines', poLineId
    When method GET
    Then status 200

    * def poLineResponse = $
    * set poLineResponse.cost.quantityPhysical = 1
    * set poLineResponse.locations[0].quantityPhysical = 1
    * set poLineResponse.locations[0].quantity = 1

    Given path 'orders/order-lines', poLineId
    And request poLineResponse
    When method PUT
    Then status 204

  Scenario: Open order after unopen
    Given path 'orders/composite-orders', orderId
    When method GET
    Then status 200

    * def orderResponse = $
    * set orderResponse.workflowStatus = "Open"

    Given path 'orders/composite-orders', orderId
    And request orderResponse
    When method PUT
    Then status 422

  Scenario: delete poline
    Given path 'orders/order-lines', poLineId
    When method DELETE
    Then status 204

  Scenario: delete composite orders
    Given path 'orders/composite-orders', orderId
    When method DELETE
    Then status 204

