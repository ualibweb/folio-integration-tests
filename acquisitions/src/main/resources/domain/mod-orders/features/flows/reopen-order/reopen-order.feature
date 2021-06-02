Feature: Reopen order flows
  Scenario: reopen-order-one-location-physics-and-manual-piece-false-and-create-inventory-instance
    Given call read('features/flows/reopen-order/reopen-order-one-location-physics-and-manual-piece-false-and-create-inventory-instance.feature')

  Scenario: reopen-order-one-location-physics-and-manual-piece-false-and-create-inventory-instance-holdings
    Given call read('features/flows/reopen-order/reopen-order-one-location-physics-and-manual-piece-false-and-create-inventory-instance-holdings.feature')

  Scenario: reopen-order-one-location-physics-and-manual-piece-false-and-create-inventory-instance-holdings-items
    Given call read('features/flows/reopen-order/reopen-order-one-location-physics-and-manual-piece-false-and-create-inventory-instance-holdings-items.feature')

  Scenario: reopen-order-one-loc-physics-and-manual-piece-false-and-some-piece-recieve-and-create-inventory-inst-hold-items
    Given call read('features/flows/reopen-order/reopen-order-one-loc-physics-and-manual-piece-false-and-some-piece-recieve-and-create-inventory-inst-hold-items.feature')

#  Scenario: reopen-order-change-qty-one-loc-phys-and-manual-piece-false-and-create-inventory-instance-holdings-items
#    Given call read('features/flows/reopen-order/reopen-order-change-qty-one-loc-phys-and-manual-piece-false-and-create-inventory-instance-holdings-items.feature')

  Scenario: reopen-order-one-location-physics-and-manual-piece-true-and-create-inventory-instance-holdings
    Given call read('features/flows/reopen-order/reopen-order-one-location-physics-and-manual-piece-true-and-create-inventory-instance-holdings.feature')

  Scenario: reopen-order-one-location-physics-and-manual-piece-true-and-create-inventory-instance-holdings-items
    Given call read('features/flows/reopen-order/reopen-order-one-location-physics-and-manual-piece-true-and-create-inventory-instance-holdings-items.feature')
