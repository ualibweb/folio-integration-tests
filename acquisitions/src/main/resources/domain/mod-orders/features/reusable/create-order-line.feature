Feature: Create order line
  # parameters: orderId, poLineId, fundId

  Background:
    * url baseUrl

  Scenario: createOrderLine
    * def poLine = read('classpath:samples/mod-orders/orderLines/minimal-order-line.json')
    * set poLine.id = poLineId
    * set poLine.purchaseOrderId = orderId
    * set poLine.fundDistribution[0].fundId = fundId
    * set poLine.fundDistribution[0].code = fundId

    Given path 'orders/order-lines'
    And request poLine
    When method POST
    Then status 201
