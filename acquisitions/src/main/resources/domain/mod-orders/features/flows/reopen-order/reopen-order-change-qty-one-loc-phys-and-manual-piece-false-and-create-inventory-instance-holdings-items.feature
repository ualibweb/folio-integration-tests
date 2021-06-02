@parallel=false
Feature: reopen-order-change-qty-one-loc-phys-and-manual-piece-false-and-create-inventory-instance-holdings-items

  Background:
    * url baseUrl
    #* callonce dev {tenant: 'test_orders'}
    * callonce loginAdmin testAdmin
    * def okapitokenAdmin = okapitoken
    * callonce loginRegularUser testUser
    * def okapitokenUser = okapitoken
    * def headersAdmin = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapitokenAdmin)', 'Accept': 'application/json'  }
    * def headersUser = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapitokenUser)', 'Accept': '*/*'  }
    * configure headers = headersUser

    * callonce variables

    * def orderId = callonce uuid1
    * def poLineId = callonce uuid2

    * configure retry = { count: 4, interval: 1000 }

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

    * def orderLine = read('classpath:samples/mod-orders/orderLines/minimal-physical-order-line.json')
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

    Given path 'orders/composite-orders', orderId
    And request orderResponse
    When method PUT
    Then status 204

  Scenario: Close order and release encumbrances
    # ============= get order to close ===================
    Given path 'orders/composite-orders', orderId
    And retry until response.workflowStatus == "Open"
    When method GET
    Then status 200
    * def orderResponse = $
    * remove orderResponse.compositePoLines
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
    * set orderResponse.compositePoLines[0].cost.quantityPhysical = 3
    * set orderResponse.compositePoLines[0].locations[0].quantityPhysical = 3
    * set orderResponse.workflowStatus = 'Open'

  Given path 'orders/composite-orders', orderId
    And request orderResponse
    When method PUT
    Then status 400
    And match $.errors contains deep {code: 'locationCannotBeModifiedAfterOpen'}


  Scenario: delete poline
    Given path 'orders/order-lines', poLineId
    When method DELETE
    Then status 204

  Scenario: delete composite orders
    Given path 'orders/composite-orders', orderId
    When method DELETE
    Then status 204

