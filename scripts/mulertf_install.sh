#!/bin/bash

if [ $# -lt 10 ]; then
    echo "I need a minimum of 10 arguments to proceed. REGION, QSS3BucketName, QSS3KeyPrefix, QSS3BucketRegion, EKSCLUSTERNAME, RTFFabricName, OrgID, UserName, Password, MuleLicenseKeyinbase64" && exit 1
fi

REGION=$1
QSS3BucketName=$2
QSS3KeyPrefix=$3
QSS3BucketRegion=$4
EKSCLUSTERNAME=$5
RTFFabricName=$6
OrgID=$7
UserName=$8
Password=$9
MuleLicenseKeyinbase64=$10
KeyPrefix=${QSS3KeyPrefix%?}

echo 'REGION'=$REGION
echo 'QSS3BucketName'=$QSS3BucketName
echo 'QSS3KeyPrefix' =$QSS3KeyPrefix
echo 'QSS3BucketRegion' = $QSS3BucketRegion
echo 'EKSCLUSTERNAME' =$EKSCLUSTERNAME
echo 'RTFFabricName' =$RTFFabricName
echo 'OrgID' =$OrgID
echo 'UserName'=$UserName
echo 'Password'=$Password
echo 'MuleLicenseKeyinbase64'=$MuleLicenseKeyinbase64
echo 'KeyPrefix'=$KeyPrefix

# Update following variables with anypoint account creadentials.
#--------user inputs ---------------------
RTFCTL_PATH=./rtfctl
BASE_URL=https://anypoint.mulesoft.com

#Install jq for easier JSON object parsing
sudo yum -y install jq

# Step-1) Acquire bearer token:
#TOKEN=$(curl -d "username=$USER_NAME&password=$PASSWORD" $BASE_URL/accounts/login | jq -r .access_token)
TOKEN=$(curl -d "username=$UserName&password=$Password" $BASE_URL/accounts/login | jq -r .access_token)
echo 'TOKEN' = $TOKEN
# Step-2) Get organization ID: (this will get only root org UUID, this step is not needed if OrgID is provided by customer.)
#OrgID=$(curl -H "Authorization: Bearer $TOKEN" $BASE_URL/accounts/api/profile | jq -r .organizationId)

#Update kube config to point to the cluster of our choice
aws eks update-kubeconfig --name ${EKSCLUSTERNAME} --region $REGION

#Install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.19.0/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client
kubectl get svc

# Install helm
#curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Create Runtime Fabric
PAYLOAD=$(echo \{\"name\":\"$RTFFabricName\"\,\"vendor\":\"eks\"\,\"region\":\"us-east-1\"\})

ActivationData=$(curl -X POST -H "Authorization: Bearer $TOKEN" -H 'Accept: application/json, text/plain, */*' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/json;charset=UTF-8' -d $PAYLOAD $BASE_URL/runtimefabric/api/organizations/$OrgID/fabrics | jq -r .activationData)


# Install rtfctl
curl -L https://anypoint.mulesoft.com/runtimefabric/api/download/rtfctl/latest -o rtfctl
chmod +x ./rtfctl

# Validate Runtime Fabric
##Placeholder to generate activation Code from API
##ActivationCode=${curl someAPI}
./rtfctl validate ${ActivationData}

# Install Runtime Fabric
./rtfctl install ${ActivationData}

# Verify Status of Runtime Fabric
./rtfctl status

#Associate environments to Runtime fabric
## Placeholder for code ##

# Update Runtime Fabric with valid MuleSoft license key
./rtfctl apply mule-license ${MuleLicenseKeyinbase64}


# Start by creating the mandatory resources for ALB Ingress Controller in your cluster:

# if [ $QSS3BucketName == 'aws-quickstart' ]
# then
#   kubectl apply -f https://$QSS3BucketName-$REGION.s3.$REGION.amazonaws.com/$KeyPrefix/scripts/deploy.yaml
# else
#   kubectl apply -f https://$QSS3BucketName.s3.$QSS3BucketRegion.amazonaws.com/$KeyPrefix/scripts/deploy.yaml
# fi

## Start by creating the mandatory resources for ALB Ingress Controller in your cluster: ##
kubectl apply -f deploy.yaml
