Feature: destroy data for edge tenant

  Scenario: call destroy data with the edge tenant
    * def testTenant = 'test_edge_orders'
    * def testUser = { tenant: '#(testTenant)', name: 'test-user', password: 'test' }
    Given call read('classpath:common/destroy-data.feature') { testUser: #(testUser)}
