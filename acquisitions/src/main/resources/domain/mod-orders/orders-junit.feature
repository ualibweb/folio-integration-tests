Feature: mod-orders integration tests

  Background:
    * url baseUrl
    * table modules
      | name                 |
      | 'mod-configuration'  |
      | 'mod-login'          |
      | 'mod-finance'        |
      | 'mod-invoice'        |
      | 'mod-orders'         |
      | 'mod-orders-storage' |
      | 'mod-permissions'    |
      | 'mod-tags'           |

    * table adminAdditionalPermissions
      | name |

    * table userPermissions
      | name                                   |
      | 'orders.all'                           |
      | 'finance.all'        |
      | 'invoice.all'        |
      | 'orders-storage.pieces.collection.get' |
      | 'orders-storage.pieces.item.get'       |
      | 'orders.item.approve' |
      | 'orders.item.unopen'  |
      | 'orders.item.reopen'  |

    * table desiredPermissions
      | name                  |
      | 'orders.item.approve' |
      | 'orders.item.unopen'  |
      | 'orders.item.reopen'  |

  Scenario: create tenant and users for testing
    Given call read('classpath:common/setup-users.feature')

  Scenario: init global data
    * call login testAdmin

    * callonce read('classpath:global/inventory.feature')
    * callonce read('classpath:global/configuration.feature')
    * callonce read('classpath:global/finances.feature')
    * callonce read('classpath:global/organizations.feature')
