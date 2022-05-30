param nameseed string = 'eshop'
param location string =  resourceGroup().location

//---------Kubernetes Construction---------
module aksconst 'aks-construction/bicep/main.bicep' = {
  name: 'aksconstruction'
  params: {
    location : location
    resourceName: nameseed
    enable_aad: true
    enableAzureRBAC : true
    registries_sku: 'Standard'
    omsagent: true
    retentionInDays: 30
    agentCount: 3
    agentVMSize: 'Standard_DS2_v2' //'Standard_D2_v4'
  }
}

//RBAC for deployment-scripts
var contributor='b24988ac-6180-42a0-ab88-20f7382dd24c'
var rbacClusterAdmin='b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'
var rbacWriter='a7ffa36f-339b-4b5c-8bdf-e2c188b2c0eb'

module ingress 'br/public:deployment-scripts/aks-run-command:1.0.1' = {
  name: 'CreateNamespace'
  params: {
    aksName: aksconst.outputs.aksClusterName
    location: location
    managedIdentityName: 'id-AksRunCommandProxy-Admin'
    rbacRolesNeeded:[
      contributor
      rbacClusterAdmin
    ]
    commands: [
      '''
      kubectl create namespace ingress-basic
      helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
      helm upgrade --install  nginx-ingress ingress-nginx/ingress-nginx \
        --set controller.publishService.enabled=true \
        --set controller.kind=DaemonSet \
        --set controller.service.externalTrafficPolicy=Local \
        --namespace ingress-basic
      '''
      'kubectl apply -f https://raw.githubusercontent.com/dotnet-architecture/eShopOnContainers/dev/deploy/k8s/nginx-ingress/local-cm.yaml'
    ]
  }
}
