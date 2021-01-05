# Install required plugins
[ $(vagrant plugin list | grep vagrant-hostmanager | wc -l) != 1 ] && vagrant plugin install vagrant-hostmanager 
[ $(vagrant plugin list | grep vagrant-vbguest | wc -l) != 1 ] && vagrant plugin install vagrant-vbguest


# Install cluster
vagrant up --provider=virtualbox


# Copy kubeconfig
cp ../data/cluster-ubuntu/config ~/.kube/


# Label nodes
kubectl label node machine-m1  node-role.kubernetes.io/master=true --overwrite
kubectl label node machine-m1  dedicated=infra

kubectl label node machine-w2  node-role.kubernetes.io/worker=true
kubectl label node machine-w3  node-role.kubernetes.io/worker=true


# kubectl taint node machine-m1 dedicated=infra:NoSchedule

kubectl get nodes
