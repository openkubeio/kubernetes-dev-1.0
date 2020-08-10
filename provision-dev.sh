  [ $(vagrant plugin list | grep vagrant-hostmanager | wc -l) != 1 ] && vagrant plugin install vagrant-hostmanager 
  [ $(vagrant plugin list | grep vagrant-vbguest | wc -l) != 1 ] && vagrant plugin install vagrant-vbguest
  
  vagrant up
  
  cp ../data/cluster-ubuntu/config ~/.kube/

  kubectl label node machine-w2  node-role.kubernetes.io/worker=worker
# kubectl label node machine-w3  node-role.kubernetes.io/worker=worker
# kubectl label node machine-p4  node-role.kubernetes.io/proxy=proxy

  kubectl get nodes