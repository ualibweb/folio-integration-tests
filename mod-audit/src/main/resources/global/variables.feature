Feature: global variables

  @GlobalVariables
  Scenario: use global variables
    * def locationId = '81209c20-0d52-44c8-b8d6-59d7b3a16b37'
    * def username = 'username8aec57e3-4f06-47af-9268-255b4020e6bf'
    * def userid = '2f253582-e18c-4442-a6f4-d125e4aad2a7'
    * def userBarcode = 'userBarcode01a9e59b-a615-4451-b318-013345171190'
    * def userGroup = 'userGroupb5895631-c5b0-4fc3-8c81-9ce9cbba848a'
    * def userGroupDesc = 'userGroupDesce79b15c2-c63f-4dbc-a16b-ed77ab0ddc4f'
    * def itemIdLoan = '5c907c4c-3f2e-445a-bcff-8ff7f960f0cb'
    * def itemIdRequest = '7a797001-0e64-4418-a231-3091391b27ea'
    * def itemIdCheckInCheckOut = '483ef9c6-f6ae-4cb8-8152-0229e63a13d0'
    * def itemBarcodeLoan = 'itemBarcoded9a520c9-25eb-430b-b355-60f34857e852'
    * def itemBarcodeRequest = 'itemBarcodea5c0459a-e4c5-48de-9c54-46cc2968ba6f'
    * def itemBarcodeCheckInCheckOut = 'itemBarcode1cb646f7-48a6-40f0-acdb-a180ad86f36a'
    * def servicePointId = '4cbd5e9c-0140-4c23-9e3c-e9c03c8a9173'
    * def servicePointNoPickupId = 'b3abc449-f4b5-4280-aa59-6647f67443b1'
    * def loanTypeId = 'a1f25beb-d986-4cf5-8a88-cae73d18d0d1'
    * def loanTypeName = 'loanTypeName49e2e438-b560-4a28-a49c-573fd981d338'
    * def loanPolicyName = 'loanPolicyNamedf83f583-e097-4e7b-b726-e4484299a3bf'
    * def materialTypeId = '7e6726a1-f3b0-44b5-9fd7-776ec4f17c45'
    * def materialTypeName = 'materialTypeName1fa34f0f-c339-47ab-9d49-e4bec3857882'
    * def instanceTypeId = '5e637ef3-5fe9-4968-a04e-e80fae8e3a9c'
    * def instanceId = '62ed73a4-f9ae-4eb2-b35c-01854b45286f'
    * def holdingsRecordId = '634832f2-7d13-4770-a054-3e96a66efd0e'
    * def checkInDate = call isoDate
    * def requestId = '4c9638b6-3444-4da9-af01-59b7d1a2bcc4'
    * def requestPolicyName = 'requestPolicyName2387d8c4-f55c-4eb7-bb56-80aeb5090f31'
    * def institutionId = '84e54c5b-096c-4230-abe1-bf3e1222cbca'
    * def institutionName = 'institutionNamef1c1ac0f-68c3-42c1-a2d6-a0b2622a2f4e'
    * def institutionCode = 'institutionCodefd0bd6f0-940f-4311-8ae2-818662c32034'
    * def libraryId = 'e04c9aae-21d6-443d-b03c-5b320b92c45e'
    * def libraryName = 'libraryName427b03a1-2555-4cf4-a207-8acb9c531b14'
    * def libraryCode = 'libraryCode78244a8a-05a9-4385-84fe-589adec229fc'
    * def campusId = 'b088d8f2-192d-43c9-86d0-165172d56193'
    * def campusName = 'campusNamecbd071dc-4ff1-4f05-94fe-57ad4bde63bb'
    * def campusCode = 'campusCode25776a62-f601-4328-9817-f2c828fdca94'
    * def userGroupId = 'e1f99d63-33ba-4d73-b90d-5685f23d50e7'
    * def circulationRuleId = '51b600a0-9ec8-48f1-9abf-74db5bd54bdc'
    * def instanceTypeName = 'instanceTypeName49643cd6-ad56-4106-a626-002d3f07af62'
    * def instanceTypeCode = 'instanceTypeCode020978e8-aa6d-48a2-8a61-d70cc354e5d1'
    * def instanceTypeSource = 'instanceTypeSource538b4131-0562-4704-acd3-6f7683158b6e'
    * def instanceSource = 'instanceSourcec5a38d8c-0321-4ef6-8172-60e678ab138f'
    * def instanceTitle = 'instanceTitle5bd9b7c8-7eae-43d3-b7eb-8a27d8bcaa85'
    * def servicePointNoPickupName = 'servicePointNoPickupName6b720740-8e9d-4de2-a975-30326ce7bb23'
    * def servicePointNoPickupCode = 'servicePointNoPickupCode6f6710ca-7597-4b35-ba5e-1cd0c35b3c9d'
    * def servicePointNoPickupDiscoveryDisplayName = 'servicePointNoPickupDiscoveryDisplayNameba5f4638-32bc-4ec1-946f-258aee839ab5'
    * def servicePointName = 'servicePointName35bcef3a-f3df-47a6-8186-a9e042fdeb42'
    * def servicePointCode = 'servicePointCodeba827938-b59a-4c24-a17f-4cfeb676a5d7'
    * def servicePointDiscoveryDisplayName = 'servicePointDiscoveryDisplayNamecd9470cc-7b34-442c-9f1f-3abae48980c9'
    * def locationName = 'locationName0bc1d7f7-67f7-4340-8cef-a1a2b9bd6bf8'
    * def locationCode = 'locationCode8d2a9d7a-dd3d-4f8d-81e1-c80523a28727'
    * def patronNoticePolicyName = 'patronNoticePolicyNamed20002b7-741b-496a-8415-51237fb83551'
    * def overdueFinePolicyName = 'overdueFinePolicyName964d23dc-d74a-49e1-9f3b-41c1736cb6fc'
    * def lostItemFeesPolicyName = 'lostItemFeesPolicyNamefdbab982-3198-4465-bb05-5fa0eaf4c34f'