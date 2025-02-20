#!/bin/bash

set -e  # Para parar o script em caso de erro

# Desativar swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Configurar módulos do kernel
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configurar parâmetros sysctl para Kubernetes
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Atualizar pacotes e instalar dependências
sudo apt-get update && sudo apt-get install -y apt-transport-https curl ca-certificates gnupg lsb-release

# Adicionar chave e repositório do Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo tee /etc/apt/trusted.gpg.d/kubernetes.asc

echo "deb https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

# Instalar kubelet, kubeadm e kubectl
sudo apt-get install -y kubelet kubeadm kubectl

# Adicionar chave e repositório do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

# Instalar containerd
sudo apt-get install -y containerd.io

# Configurar containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Reiniciar containerd
sudo systemctl restart containerd

# Exibir mensagem de conclusão
echo "Instalação concluída com sucesso!"
