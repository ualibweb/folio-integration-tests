Feature: mod-codex-ekb integration tests

  Background:
    * url baseUrl
    * table modules
      | name                    |
      | 'mod-login'             |
      | 'mod-permissions'       |
      | 'mod-codex-ekb'         |
      | 'mod-codex-mux'         |
      | 'mod-codex-inventory'   |
      | 'mod-kb-ebsco-java'     |
      | 'mod-inventory-storage' |
      | 'mod-configuration'     |

    * table adminAdditionalPermissions
      | name |

    * table userPermissions
      | name                    |
      | 'codex-ekb.all'         |
      | 'codex-mux.all'         |
      | 'kb-ebsco.all'          |
      | 'configuration.all'     |
      | 'users.all'             |
      | 'inventory-storage.all' |


  Scenario: create tenant and users for testing
    Given call read('classpath:common/setup-users.feature')
