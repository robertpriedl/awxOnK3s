# upgrade awx instance on k3s
# from https://computingforgeeks.com/how-to-upgrade-ansible-awx-running-in-kubernetes/?expand_article=1

# change to home dir and remove old repo
rm ~/awx-operator -r -f
# clone actual awx-operator
git clone https://github.com/ansible/awx-operator.git ~/awx-operator
#source ~/awx-operator

# set namespace to awx
kubectl config set-context --current --namespace=awx

# install curl and jq
sudo yum install epel-release -y
sudo yum install curl jq -y

# delete old awx container
kubectl delete  deployment awx-operator-controller-manager -n awx
kubectl  delete serviceaccount awx-operator-controller-manager -n awx
kubectl delete rolebinding awx-operator-awx-manager-rolebinding -n awx
kubectl delete role awx-operator-awx-manager-role -n awx

# deploy new version of awx-operator
export NAMESPACE=awx
(cd ~/awx-operator && VERSION=latest make deploy)

# operator pod should be pulled and installed
kubectl get pods -n awx

# awx and postgres pods should be provisioned in new version
# installation logs can be viewd in:
kubectl logs -f deployments/awx-operator-controller-manager -c awx-manager -n awx

