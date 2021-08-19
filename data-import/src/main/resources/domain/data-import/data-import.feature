Feature: mod-data-import integration tests

  Background:
    * url baseUrl
    * table modules
      | name                          |
      | 'mod-login'                   |
      | 'mod-permissions'             |
      | 'mod-configuration'           |
      | 'mod-data-import'             |
      | 'mod-source-record-storage'   |
      | 'mod-source-record-manager'   |
      | 'mod-inventory-storage'       |

    * table adminAdditionalPermissions
      | name |

    * table adminAdditionalPermissions
      | name |

    * table userPermissions
      | name                    |
      | 'configuration.all'     |
      | 'inventory-storage.all' |
      | 'source-storage.all'    |
      | 'data-import.uploaddefinitions.post'    |
      | 'data-import.upload.file.post'    |
      | 'data-import.uploaddefinitions.get'    |


  Scenario: create tenant and users for testing
    Given call read('classpath:common/setup-users.feature')

  Scenario: init global data
    * call login testAdmin
