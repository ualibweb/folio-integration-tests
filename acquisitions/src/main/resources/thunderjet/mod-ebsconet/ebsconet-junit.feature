@parallel=false
Feature: mod-ebsconet integration tests

  Background:
    * url baseUrl
    * table modules
      | name                |
      | 'mod-configuration' |
      | 'mod-ebsconet'      |
      | 'mod-login'         |
      | 'mod-orders'        |
      | 'mod-organizations' |
      | 'mod-permissions'   |

    * table userPermissions
      | name                |
      | 'ebsconet.all'      |
      | 'orders.all'        |


  Scenario: create tenant and users for testing
    Given call read('classpath:common/setup-users.feature')

  Scenario: init global data
    * call login testAdmin
    * callonce read('classpath:global/inventory.feature')
    * callonce read('classpath:global/configuration.feature')
    * callonce read('classpath:global/finances.feature')
    * callonce read('classpath:global/organizations.feature')
