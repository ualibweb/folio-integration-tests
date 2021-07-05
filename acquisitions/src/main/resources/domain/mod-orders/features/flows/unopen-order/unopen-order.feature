Feature: Unopen order flows
  Scenario: unopen-order--and-manual-piece-false-and-create-inventory-instance
    Given call read('features/flows/unopen-order/unopen-order--and-manual-piece-false-and-create-inventory-instance.feature')

  Scenario: unopen-order--and-manual-piece-false-and-create-inventory-instance-holding
    Given call read('features/flows/unopen-order/unopen-order--and-manual-piece-false-and-create-inventory-instance-holding.feature')

  Scenario: unopen-order--and-manual-piece-false-and-create-inventory-instance-holdings-items
    Given call read('features/flows/unopen-order/unopen-order--and-manual-piece-false-and-create-inventory-instance-holdings-items.feature')

  Scenario: unopen-order-one-loc-physics-and-manual-piece-false-and-some-piece-recieve-and-create-inventory-inst-hold-items
    Given call read('features/flows/unopen-order/unopen-order-one-loc-physics-and-manual-piece-false-and-some-piece-recieve-and-create-inventory-inst-hold-items.feature')
