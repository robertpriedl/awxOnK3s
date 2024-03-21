# get awx hostname for ingress controller
printf 'whats the dns hostname for the awx server (not fqdn - only hostname)'
read awxHostname
echo "AWX will be installed with name: $awxHostname.pritec.solutions"
# Disable firewalld
sudo systemctl disable firewalld --now

# Disable nm-cloud-setup if exists and enabled
sudo systemctl disable nm-cloud-setup.service nm-cloud-setup.timer
# sudo reboot

# install centos or ubuntu
sudo dnf install -y git make curl
sudo apt install -y git make curl

curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

# clone awx-operator with verison 1.2
git clone https://github.com/ansible/awx-operator.git ~/awx-operator
(cd ~/awx-operator && git checkout devel)

export NAMESPACE=awx
(cd ~/awx-operator && make deploy)

kubectl -n awx get all

# clone awx on k3s repo in version 1.2.0
(cd ~ && git clone https://github.com/kurokobo/awx-on-k3s.git)
(cd ~/awx-on-k3s && git checkout main)

AWX_HOST="$awxHostname.pritec.solutions"
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -out ~/awx-on-k3s/base/tls.crt -keyout ~/awx-on-k3s/base/tls.key -subj "/CN=${AWX_HOST}/O=${AWX_HOST}" -addext "subjectAltName = DNS:${AWX_HOST}"

sudo mkdir -p /data/postgres-15
sudo mkdir -p /data/projects
sudo chmod 755 /data/postgres-15
sudo chown 1000:0 /data/projects

# Modify hostname in base/awx.yaml. to call awx via hostname in broser - else there is a 404!
sudo sed -e "s/.*hostname: awx.example.com.*/    - hostname: ${AWX_HOST}/" -i ~/awx-on-k3s/base/awx.yaml
# ...
#spec:
#  ...
#  ingress_type: ingress
#  ingress_tls_secret: awx-secret-tls
#  hostname: awx.pritec.solutions     👈👈👈
#...
#
# create AWX Installation on K3s:
(cd ~/awx-on-k3s && kubectl apply -k base)

# awx and postgres pods should be provisioned in new version
# installation logs can be viewd in:
echo "to get logs call:"
echo "kubectl logs -f deployments/awx-operator-controller-manager -c awx-manager -n awx"
echo "to get all pods call:"
echo "kubectl -n awx get awx,all,ingress,secrets"
# check install progress (should be end if:
# PLAY RECAP *********************************************************************
# localhost                  : ok=77   changed=0    unreachable=0    failed=0    skipped=71   rescued=0    ignored=1
# kubectl -n awx logs -f deployments/awx-operator-controller-manager

# check pod status:
# kubectl -n awx get awx,all,ingress,secrets
# should be:
# NAME                      AGE
# awx.awx.ansible.com/awx   13m

# NAME                                                   READY   STATUS    RESTARTS   AGE
# pod/awx-operator-controller-manager-77756d8b8f-5hlwk   2/2     Running   0          16m
# pod/awx-postgres-13-0                                  1/1     Running   0          13m
# pod/awx-7c589d6fd5-8qss4                               4/4     Running   0          12m

# NAME                                                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
# service/awx-operator-controller-manager-metrics-service   ClusterIP   10.43.229.158   <none>        8443/TCP   16m
# service/awx-postgres-13                                   ClusterIP   None            <none>        5432/TCP   13m
# service/awx-service                                       ClusterIP   10.43.100.9     <none>        80/TCP     12m

# NAME                                              READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/awx-operator-controller-manager   1/1     1            1           16m
# deployment.apps/awx                               1/1     1            1           12m

# NAME                                                         DESIRED   CURRENT   READY   AGE
# replicaset.apps/awx-operator-controller-manager-77756d8b8f   1         1         1       16m
# replicaset.apps/awx-7c589d6fd5                               1         1         1       12m

# NAME                               READY   AGE
# statefulset.apps/awx-postgres-13   1/1     13m

# NAME                                    CLASS     HOSTS                  ADDRESS        PORTS     AGE
# ingress.networking.k8s.io/awx-ingress   traefik   awx.pritec.solutions   10.10.11.161   80, 443   12m

# NAME                                  TYPE                DATA   AGE
# secret/awx-admin-password             Opaque              1      13m
# secret/awx-postgres-configuration     Opaque              6      13m
# secret/awx-secret-tls                 kubernetes.io/tls   2      13m
# secret/redhat-operators-pull-secret   Opaque              1      13m
# secret/awx-app-credentials            Opaque              3      12m
# secret/awx-secret-key                 Opaque              1      13m
# secret/awx-broadcast-websocket        Opaque              1      13m
# secret/awx-receptor-ca                kubernetes.io/tls   2      12m
# secret/awx-receptor-work-signing      Opaque              2      12m
