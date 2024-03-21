# upgrade awx instance on k3s
# from https://computingforgeeks.com/how-to-upgrade-ansible-awx-running-in-kubernetes/?expand_article=1

# change to home dir and remove old repo
rm ~/awx-operator -r -f
# clone actual awx-operator
git clone https://github.com/ansible/awx-operator.git ~/awx-operator
#source ~/awx-operator

# set namespace to awx
/usr/local/bin/kubectl config set-context --current --namespace=awx

# install curl and jq
sudo yum install epel-release -y
sudo yum install curl jq -y

# if problems with authorize k3s for kubectl use certificate rotate:
# Stop K3s:
##systemctl stop k3s
# Rotate certificates:
##k3s certificate rotate
# see: https://docs.k3s.io/cli/certificate
# Start K3s
##systemctl start k3s
# delete old awx container
/usr/local/bin/kubectl delete deployment awx-operator-controller-manager -n awx
/usr/local/bin/kubectl delete serviceaccount awx-operator-controller-manager -n awx
/usr/local/bin/kubectl delete rolebinding awx-operator-awx-manager-rolebinding -n awx
/usr/local/bin/kubectl delete role awx-operator-awx-manager-role -n awx

# deploy new version of awx-operator
export NAMESPACE=awx
(cd ~/awx-operator && VERSION=latest make deploy)

# operator pod should be pulled and installed
/usr/local/bin/kubectl get pods -n awx

# awx and postgres pods should be provisioned in new version
# installation logs can be viewd in:
echo "to get logs call:"
echo "/usr/local/bin/kubectl logs -f deployments/awx-operator-controller-manager -c awx-manager -n awx"

