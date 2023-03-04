targetScope = 'subscription'

param region string = 'eastus'

var tags = {
  Contact: 'JamesK@foo.com'
  Product: 'DevOps'
  Environment: 'Dev'
  Region: region
  NewerTag: 'DevOps'
  Taggy: 'TagStuff'
}

resource rg1 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: toLower('devops-extension-testing1')
  location: region
  tags:tags
}

resource rg2 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: toLower('devops-extension-testing2')
  location: region
  tags:tags
}

