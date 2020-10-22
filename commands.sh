# feature flags
az feature register --namespace Microsoft.Kubernetes --name previewAccess
az feature register --namespace Microsoft.KubernetesConfiguration --name sourceControlConfiguration

# verify
az feature list -o table | grep Kubernetes

# register providers
az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.KubernetesConfiguration

# verify
az provider show -n Microsoft.Kubernetes -o table
az provider show -n Microsoft.KubernetesConfiguration -o table

# install CLI extensions
az extension add --name connectedk8s
az extension add --name k8sconfiguration

# or update them
az extension update --name connectedk8s
az extension update --name k8sconfiguration

# list extensions
az extension list -o table

# connect a cluster
# create RG
az group create --name rg-arc-demo -l eastus -o table

# connect
az connectedk8s connect --name arc-kind --resource-group rg-arc-demo

# verify connection
az connectedk8s list -o table
az connectedk8s show -g rg-arc-demo -n arc-kind

# gitops config
az k8sconfiguration create \
    --name realtime-config \
    --cluster-name arc-kind --resource-group rg-arc-demo \
    --operator-instance-name realtime-config --operator-namespace realtime \
    --repository-url git@github.com:DimensionDataResearch/azure-arc-kubernetes-poc.git \
    --scope namespace --cluster-type connectedClusters \
    --operator-params='--git-path=config --git-user="user name" --git-email=user@didata.com.au'

# gitops config2
az k8sconfiguration create \
    --name polling-config \
    --cluster-name arc-kind --resource-group rg-arc-demo \
    --operator-instance-name polling-config --operator-namespace voting \
    --repository-url git@github.com:samuelchong/azure_arc.git \
    --scope namespace --cluster-type connectedClusters \
    --operator-params='--git-path=config2 --git-user="Samuel Chong" --git-email="samuel.chong@global.ntt" --git-poll-interval=10s'


# list configs
az k8sconfiguration list -g rg-arc-demo -c arc-kind --cluster-type connectedClusters -o table

# delete config
az k8sconfiguration delete -g rg-arc-demo -c arc-kind --cluster-type connectedClusters -n realtime-config -o table


# deploy config with ARM template
az deployment group create -g rg-arc-demo --template-file arm/config-template.json --parameters arm/config-template.parameters.json 

# via policy - assign custom Arc policy to connected cluster object
# issue: not working - recreated policy based on new policy example 14/5/2020
# WORKS with new policy file (see repo in policy folder)

# monitoring with Bash onboarding script
curl -LO https://raw.githubusercontent.com/microsoft/OMS-docker/ci_feature/docs/haiku/onboarding_azuremonitor_for_containers.sh

# parameters: resource id of connected cluster, kube config context
bash onboarding_azuremonitor_for_containers.sh /subscriptions/11bef04e-7126-4b3e-8cb2-d89563fd9369/resourceGroups/rg-arc/providers/Microsoft.Kubernetes/connectedClusters/arc-kind kind-kind

# stop monitoring: remove helm chart
helm del azmon-containers-release-1

# spin up DO K8S; requires doctl and doctl auth init + api access token
doctl kubernetes cluster create dok8s --count 1 --region ams3 --size s-2vcpu-2gb

# delete cluster later
doctl kubernetes cluster delete dok8s

# create RG and connect
az group create --name rg-arc -l westeurope -o table
az connectedk8s connect --name arc-do --resource-group rg-arc

# configuration
az k8sconfiguration create \
    --name realtime-config \
    --cluster-name arc-do --resource-group rg-arc \
    --operator-instance-name realtime-config --operator-namespace realtime \
    --repository-url git@github.com:gbaeke/arc \
    --scope namespace --cluster-type connectedClusters \
    --operator-params='--git-path=config --git-user=user --git-email=user@example.com'

# monitoring with Bash onboarding script
curl -LO https://raw.githubusercontent.com/microsoft/OMS-docker/ci_feature/docs/haiku/onboarding_azuremonitor_for_containers.sh

# parameters: resource id of connected cluster, kube config context (check k8s context)
bash onboarding_azuremonitor_for_containers.sh /subscriptions/11bef04e-7126-4b3e-8cb2-d89563fd9369/resourceGroups/rg-arc/providers/Microsoft.Kubernetes/connectedClusters/arc-do do-ams3-dok8s

# stop monitoring: remove helm chart
helm del azmon-containers-release-1
