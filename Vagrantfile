# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# author : Pramode P
#
# Pospose : Vagrant script provisions a kubernetes cluster with 1 master node and 2 worker nodes
#
# Using yaml to load external configuration files

require 'yaml'
require 'fileutils'

$install_docker = <<-SCRIPT

echo "--- Executing script install_docker"

echo "--- Update the apt package index"
sudo apt update && sudo apt-get update

echo "--- Install packages to allow apt to use a repository over HTTPS"
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

echo "--- Add Docker’s official GPG key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

echo "--- Set up the stable repository for docker"
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$( . /etc/os-release ; echo "$ID") $(lsb_release -cs) stable"
sudo apt-get update

echo "--- Install docker ce version 17.x"
sudo apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep 17. | grep  ubuntu-xenial | head -1 | awk '{print $3}')

echo "--- Update docker cgroup driver"
sudo tee -a /etc/docker/daemon.json  << EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

echo "--- Restart docker"
sudo systemctl restart docker

SCRIPT

$install_kubeadm = <<-SCRIPT

echo "--- Executing script install_kubeadm" 

echo "--- Add Kubernetes official GPG key"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

echo "--- Update apt respository to stable kubernetes"
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt-get update

echo "--- Checking available version of kubeadm"
echo "Checking available version `curl -s https://packages.cloud.google.com/apt/dists/kubernetes-xenial/main/binary-amd64/Packages | grep Version | grep 1.17 | awk '{print $2}'`"

echo "--- Installing Kubeadm and kubelet - version 1.17.0"
sudo apt-get install kubeadm=1.17.0-00 kubelet=1.17.0-00  kubectl=1.17.0-00 -y

SCRIPT


$check_config = <<-SCRIPT

echo "--- Checking versions and IPs"
echo "HOME=$HOME"
echo "user=`whoami`"
echo "docker_version=`docker version`"
echo "kubelet_version=`kubelet --version`"
echo "kubeadm_version=`kubeadm version`"

IPADDR_ENP0S8=$(ifconfig enp0s8 | grep Mask | awk '{print $2}'| cut -f2 -d:)
IPADDR_ENP0S3=$(ifconfig enp0s3 | grep Mask | awk '{print $2}'| cut -f2 -d:)
HOSTNAME=$(hostname -f)

echo "IPADDR_ENP0S8 $IPADDR_ENP0S8"
echo "IPADDR_ENP0S3 $IPADDR_ENP0S3"
echo "HOSTNAME $HOSTNAME"

echo "--- Disable Swap "
sudo swapoff -a
#sudo sed -i '/ swap /s/^\(.*\)$/#\1/g' /etc/fstab
sudo sed -i  '/ swap / s~^~#~g' /etc/fstab


echo "--- Update Kube Config file for removing bootstrap file and cgroup driver"

#sudo sed -i 's/--bootstrap-kubeconfig=\/etc\/kubernetes\/bootstrap-kubelet.conf//' \/etc\/systemd\/system\/kubelet.service.d\/10-kubeadm.conf

echo "Environment=\"cgroup-driver=systemd\"" | sudo tee -a /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

echo "Environment=\"KUBELET_EXTRA_ARGS=--node-ip=$IPADDR_ENP0S8\"" | sudo tee -a /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

echo "--- etc/hosts file to comment ip6"
sudo sed -i '/ip6/s/^/#/' /etc/hosts

echo "--- update firewall to allow connection"
# You may require to rum below command to ufw to allow pos to pod inter communication
# sudo ufw allow in on cni0 && sudo ufw allow out on cni0
# sudo ufw default allow routed

echo "--- Install nfs common package for Storage"
sudo apt install nfs-common -y 

SCRIPT


$init_master = <<-SCRIPT

echo "--- Executing script init_master" 

echo "--- pull config images"
sudo kubeadm config images pull

echo "--- Create data directory for installation"
sudo mkdir -p /data/cluster-ubuntu/

echo "--- Export variables"
HOST_NAME=$(hostname -f)
IPADDR_ENP0S8=$(ifconfig enp0s8 | grep Mask | awk '{print $2}'| cut -f2 -d:)

echo "--- Initialise kubeadm"
sudo kubeadm init  --apiserver-advertise-address=$IPADDR_ENP0S8 --apiserver-cert-extra-sans=$IPADDR_ENP0S8  --node-name $(hostname -s)  --pod-network-cidr 10.10.0.0/16 --service-cidr  10.150.0.0/16  2>&1 | tee  /data/cluster-ubuntu/init_master.log

echo "--- Export token for Worker Node"
sudo kubeadm token create --print-join-command > /data/cluster-ubuntu/kubeadm_join_cmd.sh
sudo chmod +x /data/cluster-ubuntu/kubeadm_join_cmd.sh

echo "--- create dummy bootstart if not exist"
[ -f /etc/kubernetes/bootstrap-kubelet.conf ] || sudo touch /etc/kubernetes/bootstrap-kubelet.conf

SCRIPT


$post_master = <<-SCRIPT

echo "--- Executing script post_master" 

echo "--- Setup kubectl for vagrant user"
sudo mkdir /root/.kube/
sudo cp /etc/kubernetes/admin.conf /root/.kube/config

echo "--- Implement Calico for Kubernetes Networking"
echo "--- Projet calico : https://docs.projectcalico.org/v3.11/getting-started/kubernetes/ "
sudo kubectl apply -f https://docs.projectcalico.org/v3.11/manifests/calico.yaml

echo "--- Waiting for core dns pods to be up . . . "
while [ $(kubectl get pods --all-namespaces | grep dns | grep Running | wc -l) != 2 ] ; do sleep 20 ; echo "--- Waiting for core dns pods to be up . . . " ; done

while [ $(kubectl get nodes | grep master | grep Ready | wc -l) != 1 ] ; do sleep 20 ; echo "--- Waiting node to be ready . . . " ; done
echo "--- Matser node is Ready"
echo "`kubectl get nodes`"

echo "--- Copy kube config to shared kubeadm install path"
sudo cp /etc/kubernetes/admin.conf /data/cluster-ubuntu/config

SCRIPT


$init_node = <<-SCRIPT

echo "--- Executing script init_worker"

echo "--- Join as worker node "
sudo sh /data/cluster-ubuntu/kubeadm_join_cmd.sh

echo "--- create dummy bootstart if not exist"
[ -f /etc/kubernetes/bootstrap-kubelet.conf ] || sudo touch /etc/kubernetes/bootstrap-kubelet.conf

SCRIPT


$init_proxy = <<-SCRIPT
echo "--- Executing script init_proxy"

echo "--- Update apt and install haproxy"
sudo apt update && sudo apt-get update
sudo apt-get install -y haproxy
sudo systemctl enable haproxy

echo "--- Update haproxy config"
sudo tee -a /etc/haproxy/haproxy.cfg << EOF
#### Config of Ingress Traffic to Kubernetes

frontend localhost
    bind *:443
    option tcplog
    mode tcp
    default_backend nodes
backend nodes
   mode tcp
   balance roundrobin
   option ssl-hello-chk
   server node01 192.168.205.11:30001 check
   server node02 192.168.205.12:30001 check

####END of Config
EOF

echo "--- Check haproxy config status"
haproxy -f /etc/haproxy/haproxy.cfg -c -V

echo "--- Restarting haproxy service"
sudo systemctl stop haproxy
sleep 5
sudo systemctl start haproxy
SCRIPT


$init_nfs = <<-SCRIPT

echo "--- Executing script init_proxy"

echo "--- Login onto nfs node and install nfs server"
sudo apt-get update
sudo apt-get install nfs-server -y
sudo systemctl status nfs-server
sudo apt install nfs-common -y

echo "--- Create nfs shared directory"
sudo mkdir /nfs/kubedata -p

echo "--- Change owernship"
sudo chown nobody:nogroup /nfs/kubedata

echo "--- Update exports file"
sudo tee -a /etc/exports << EOF
/nfs/kubedata    *(rw,sync,no_subtree_check,no_root_squash,no_all_squash,insecure)
## /nfs/general  192.168.205.13(rw,sync,no_subtree_check)
EOF

sudo exportfs -a
sudo exportfs -rva

echo "--- Restar nfs server and check status"
sudo systemctl restart nfs-server
sudo systemctl status nfs-server

SCRIPT



Vagrant.configure("2") do |config|
  # Using the hostmanager vagrant plugin to update the host files
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  config.hostmanager.ignore_private_ip = false
  
  # Create a data dir to mount with in the VM information
  FileUtils.mkdir_p './../data/'

  
  # Loading in the VM configuration information
  servers = YAML.load_file('servers.yaml')
  
  servers.each do |servers| 
    config.vm.define servers["name"] do |srv|
      srv.vm.box = servers["box"] # Speciy the name of the Vagrant box file to use
      srv.vm.hostname = servers["name"] # Set the hostname of the VM
	# Add a second adapater with a specified IP
      srv.vm.network "private_network", ip: servers["ip"], :adapater=>2 
    # srv.vm.network :forwarded_port, guest: 22, host: servers["port"] # Add a port forwarding rule
      srv.vm.synced_folder ".", "/vagrant", type: "virtualbox"
	  srv.vm.synced_folder "./../data/" , "/data", type: "virtualbox", owner: "root", group: "root", mount_options: ["dmode=777,fmode=777"]

      srv.vm.provider "virtualbox" do |vb|
        vb.name = servers["name"] # Name of the VM in VirtualBox
        vb.cpus = servers["cpus"] # How many CPUs to allocate to the VM
        vb.memory = servers["memory"] # How much memory to allocate to the VM
    #   vb.customize ["modifyvm", :id, "--cpuexecutioncap", "10"]  # Limit to VM to 10% of available 
      end
	  
	  if servers["name"].include? "machine-m" then
		srv.vm.provision "shell", inline: $install_docker
        srv.vm.provision "shell", inline: $install_kubeadm
	    srv.vm.provision "shell", inline: $check_config
		srv.vm.provision "shell", inline: $init_master
		srv.vm.provision "shell", inline: $post_master	
        srv.vm.provision "shell", inline: $init_proxy
		srv.vm.provision "shell", inline: $init_nfs		
	  end
	  
	  if servers["name"].include? "machine-w" then
	    srv.vm.provision "shell", inline: $install_docker
        srv.vm.provision "shell", inline: $install_kubeadm
	    srv.vm.provision "shell", inline: $check_config
		srv.vm.provision "shell", inline: $init_node
     end
	 
	 if servers["name"].include? "machine-p" then
	   srv.vm.provision "shell", inline: $install_docker
       srv.vm.provision "shell", inline: $install_kubeadm
	   srv.vm.provision "shell", inline: $check_config
	   srv.vm.provision "shell", inline: $init_node
	   srv.vm.provision "shell", inline: $init_proxy
	   srv.vm.provision "shell", inline: $init_nfs
     end
	end
  end
end