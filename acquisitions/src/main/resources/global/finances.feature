Feature: global finances

  Background:
    * url baseUrl
    * call login testAdmin

    * configure headers = { 'Content-Type': 'application/json', 'Accept': 'application/json', 'x-okapi-token': '#(okapitoken)' }

  Scenario: create fiscal year
    Given path 'finance/fiscal-years'
    And request
    """
    {
      "id": "ac2164c7-ba3d-1bc2-a12c-e35ceccbfaf2",
      "name": "TST-Fiscal Year 2022",
      "code": "FY2022",
      "description": "January 1 - December 30",
      "periodStart": "2022-01-01T00:00:00Z",
      "periodEnd": "2022-12-30T23:59:59Z",
      "series": "FY"
    }
    """
    When method POST
    Then status 201

  Scenario: create ledgers
    Given path 'finance-storage/ledgers'
    And request
    """
    {
        "id": "5e4fbdab-f1b1-4be8-9c33-d3c41ec9a695",
        "code": "TST-LDG",
        "ledgerStatus": "Active",
        "name": "Test ledger",
        "fiscalYearOneId": "ac2164c7-ba3d-1bc2-a12c-e35ceccbfaf2",
        "restrictEncumbrance": false
    }
    """
    When method POST
    Then status 201

  Scenario: create planned fiscal year
    Given path 'finance/fiscal-years'
    And request
    """
    {
      "id": "ac2164c7-ba3d-1bc2-a12c-e35ceccbfaf3",
      "name": "TST-Fiscal Year 2023",
      "code": "FY2023",
      "description": "January 1 - December 30",
      "periodStart": "2023-01-01T00:00:00Z",
      "periodEnd": "2023-12-30T23:59:59Z",
      "series": "FY"
    }
    """
    When method POST
    Then status 201

  Scenario: create ledgers with restrict encumbrance and expenditure
    Given path 'finance-storage/ledgers'
    And request
    """
    {
        "id": "5e4fbdab-f1b1-4be8-9c33-d3c41ec6a696",
        "code": "TST-LDG2",
        "ledgerStatus": "Active",
        "name": "Test ledger with restrictions",
        "fiscalYearOneId": "ac2164c7-ba3d-1bc2-a12c-e35ceccbfaf2",
        "restrictEncumbrance": true,
        "restrictExpenditures": true,
    }
    """
    When method POST
    Then status 201

  Scenario: create funds
    Given path 'finance-storage/funds'
    And request
    """
    {
      "id": "5e4fbdab-f1b1-4be8-9c33-d3c41ec9a696",
      "code": "TST-FND",
      "description": "Fund for API Tests",
      "externalAccountNo": "1111111111111111111111111",
      "fundStatus": "Active",
      "ledgerId": "5e4fbdab-f1b1-4be8-9c33-d3c41ec9a695",
      "name": "Fund for API Tests"
    }
    """
    When method POST
    Then status 201

  Scenario: create budget
    Given path 'finance/budgets'
    And request
    """
    {
      "id": "5e4fbdab-f1b1-4be8-9c33-d3c41ec9a697",
      "budgetStatus": "Active",
      "fundId": "5e4fbdab-f1b1-4be8-9c33-d3c41ec9a696",
      "name": "Budget for API Tests",
      "fiscalYearId":"ac2164c7-ba3d-1bc2-a12c-e35ceccbfaf2",
      "allocated": 9999999
    }
    """
    When method POST
    Then status 201

  Scenario: create funds 2
    Given path 'finance-storage/funds'
    And request
    """
    {
      "id": "5e4fbdab-f1b1-4be8-9c33-d3c41ec9a698",
      "code": "TST-FND-2",
      "description": "Fund 2 for orders API Tests",
      "externalAccountNo": "22222222222222222222",
      "fundStatus": "Active",
      "ledgerId": "5e4fbdab-f1b1-4be8-9c33-d3c41ec9a695",
      "name": "Fund 2 for orders API Tests"
    }
    """
    When method POST
    Then status 201

  Scenario: create budget 2
    Given path 'finance/budgets'
    And request
    """
    {
      "id": "5e4fbdab-f1b1-4be8-9c33-d3c41ec9a658",
      "budgetStatus": "Active",
      "fundId": "5e4fbdab-f1b1-4be8-9c33-d3c41ec9a698",
      "name": "Budget 2 for orders API Tests",
      "fiscalYearId":"ac2164c7-ba3d-1bc2-a12c-e35ceccbfaf2",
      "allocated": 9999999
    }
    """
    When method POST
    Then status 201

  Scenario: create funds 3
    Given path 'finance-storage/funds'
    And request
    """
    {
      "id": "5e4fbdab-f1b1-4be8-9c33-d3c41ec9a638",
      "code": "TST-FND-3",
      "description": "Fund 3 for orders API Tests",
      "externalAccountNo": "1111111111111111111111111-01",
      "fundStatus": "Active",
      "ledgerId": "5e4fbdab-f1b1-4be8-9c33-d3c41ec9a695",
      "name": "Fund 3 for orders API Tests"
    }
    """
    When method POST
    Then status 201

  Scenario: create budget 3
    Given path 'finance/budgets'
    And request
    """
    {
      "id": "5e4fbdab-f1b1-4be8-9c33-d3c41ec9a618",
      "budgetStatus": "Active",
      "fundId": "5e4fbdab-f1b1-4be8-9c33-d3c41ec9a638",
      "name": "Budget 3 for orders API Tests",
      "fiscalYearId":"ac2164c7-ba3d-1bc2-a12c-e35ceccbfaf2",
      "allocated": 9999999
    }
    """
    When method POST
    Then status 201

  Scenario: create funds without budget
    Given path 'finance-storage/funds'
    And request
    """
    {
      "id": "c9363394-c13a-4470-bce5-3fdfce5a14cc",
      "code": "TST-FND-WO-BUDGET",
      "description": "Fund without budget for finance API Tests",
      "externalAccountNo": "2111111111111111111111111",
      "fundStatus": "Active",
      "ledgerId": "5e4fbdab-f1b1-4be8-9c33-d3c41ec9a695",
      "name": "Fund without budget for finance API Tests"
    }
    """
    When method POST
    Then status 201

  Scenario Outline: create expense classes
    Given path 'finance/expense-classes'
    And request
    """
    {
      "id": <id>,
      "code": <code>,
      "externalAccountNumberExt": <externalAccountNumberExt>,
      "name": <name>,
    }
    """
    When method POST
    Then status 201
    Examples:
      | id                                     | code   | name         | externalAccountNumberExt |
      | "1bcc3247-99bf-4dca-9b0f-7bc51a2998c2" | "Elec" | "Electronic" | "01"                     |
      | "5b5ebe3a-cf8b-4f16-a880-46873ef21388" | "Prn"  | "Print"      | "02"                     |
      | "9abc4491-b2f0-413c-be51-51675b15f366" | "Othr" | "Other"      | "03"                     |
