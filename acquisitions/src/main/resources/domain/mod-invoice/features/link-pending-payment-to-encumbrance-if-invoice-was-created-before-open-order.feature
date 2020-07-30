Feature: Should populate encumbrance in the "Pending payments transaction" if the invoice line was created from an order line before opening the order

  Background:
    * url baseUrl
    # uncomment below line for development
    * callonce dev {tenant: 'test_invoices'}
    * callonce login testAdmin
    * def okapitokenAdmin = okapitoken

    * callonce login testUser
    * def okapitokenUser = okapitoken

    * def headersUser = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapitokenUser)', 'Accept': '*/*'  }
    * def headersAdmin = { 'Content-Type': 'application/json', 'x-okapi-token': '#(okapitokenAdmin)', 'Accept': '*/*'  }
    * configure readTimeout = 600000
    * configure headers = headersUser
  #-------------- Init global variables and load templates. !Variables must be before templates initialization --------
    * callonce variables
    * callonce read('classpath:global/load-shared-templates.feature')

  Scenario: Should populate encumbrance in the "Pending payments transaction" if the invoice line was created from an order line before opening the order
    Given path 'orders/composite-orders'
    * copy order =  minimalOrderTemplate
    * set order.orderType = 'One-Time'
    And request order
    When method POST
    Then status 201
    * def orderId = $.id
    * def poNumber = $.poNumber

    # ============= create order line ===================
    Given path 'orders/order-lines'
    * copy orderLine =  minimalOrderLineTemplate
    * set orderLine.purchaseOrderId = orderId
    And request orderLine
    When method POST
    Then status 201
    * def poLineId = $.id
    * def poLineNumber = $.poLineNumber
    * def poLineQty = $.cost.quantityPhysical
    * def poLineEstimatedPrice = $.cost.poLineEstimatedPrice

    # ============= create invoice ===================
    Given path 'invoice/invoices'
    * copy newInvoice =  invoiceTemplate
    And request newInvoice
    When method POST
    Then status 201
    * def invoice = $
    * def invoiceId = $.id
    * def folioInvoiceNo = $.folioInvoiceNo

    # ============= create invoice line ===================
    Given path 'invoice/invoice-lines'
    * copy invoiceLine = polPercentageInvoiceLineTemplate
    * set invoiceLine.poLineId = poLineId
    * set invoiceLine.invoiceId = invoiceId
    * set invoiceLine.releaseEncumbrance = true
    * set invoiceLine.quantity = poLineQty
    * set invoiceLine.subTotal = poLineEstimatedPrice
    * set invoiceLine.total = poLineEstimatedPrice
    And request invoiceLine
    When method POST
    Then status 201
    * def invoiceLineId = $.id

    # ============= open order ===================
    Given path 'orders/composite-orders', orderId
    When method GET
    Then status 200
    * def order = $
    * set order.workflowStatus = "Open"

    Given path 'orders/composite-orders', orderId
    And request order
    When method PUT
    Then status 204

    # ============= approve invoice ===================
#    Given path 'invoice/invoices', invoiceId
#    When method GET
#    Then status 200
#    * def invoicePayload = $
#    * set invoicePayload.status = "Approved"

#    Given path 'invoice/invoices', invoiceId
#    * set invoicePayload.status = "Approved"
#    And request invoice
#    When method PUT
#    Then status 204