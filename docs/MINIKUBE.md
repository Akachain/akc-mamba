1. Install pip3
sudo apt install python3-pip
2. Install minikube, kubectl command
- Install minikube
```
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```
- Install kubectl
```
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt-get install kubeadm kubelet kubectl
sudo apt-mark hold kubeadm kubelet kubectl
```
- Install nfs-commmon
```
sudo apt-get install nfs-common
```
2. Install dependency
```
pip3 install -r requirements.txt
```
3. Start minikube
```
sudo minikube start --driver=none
sudo mv /home/hainq6/.kube /home/hainq6/.minikube $HOME
sudo chown -R $USER $HOME/.kube $HOME/.minikube
```
4. Setup environment
```
mamba environment
```
5. Start network
```
mamba environment
```
#### Note
```
k edit cm -n kube-system coredns
```