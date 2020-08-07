Feature: transaction

  Background:
    * url baseUrl
    * def poLineId = callonce uuid

  @CreateTransaction
  Scenario: Create transaction
    * def fiscalYearId = karate.get('fiscalYearId', globalFiscalYearId)

    Given path 'finance-storage/transactions'
    And request
    """
    {
      "amount": "#(amount)",
      "currency": "USD",
      "fromFundId": "#(fundId)",
      "toFundId": "#(fundId)",
      "fiscalYearId": "#(fiscalYearId)",
      "transactionType": #(transactionType),
      "source": "User",
      "sourceInvoiceId": "#(invoiceId)",
      "expenseClassId": "#(expenseClassId)",
      "encumbrance": {
        "initialAmountEncumbered": #(amount),
        "status": "Unreleased",
        "sourcePurchaseOrderId": "#(orderId)",
        "sourcePoLineId": "#(poLineId)",
        "orderType": "One-Time",
        "subscription": false,
        "reEncumber": false
       }
    }
    """
    When method POST
    Then status 201

  @CreateTransferTransaction
  Scenario: Create transfer transaction
    * def fiscalYearId = karate.get('fiscalYearId', globalFiscalYearId)

    Given path 'finance/transfers'
    And request
    """
      {
        "fromFundId": "#(fromFundId)",
        "toFundId": "#(toFundId)",
        "amount": "#(amount)",
        "fiscalYearId": "#(fiscalYearId)",
        "currency": "USD",
        "transactionType": "Transfer",
        "source": "User",
      }
    """
    When method POST
    Then status 201