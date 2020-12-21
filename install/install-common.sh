#!/usr/bin/env bash

# install dependencies, libs and tools
sudo yum update -y && \
sudo yum update -y && \
     sudo yum groupinstall -y 'Development Tools' && \
     sudo yum install -y \
     openssl-devel \
     libuuid-devel \
     libseccomp-devel \
     wget \
     squashfs-tools \
     cryptsetup

# install go
export VERSION=1.13.1 OS=linux ARCH=amd64
wget -q -O /tmp/go${VERSION}.${OS}-${ARCH}.tar.gz https://dl.google.com/go/go${VERSION}.${OS}-${ARCH}.tar.gz
sudo tar -C /usr/local -xzf /tmp/go${VERSION}.${OS}-${ARCH}.tar.gz
rm /tmp/go${VERSION}.${OS}-${ARCH}.tar.gz

# configure environment
export GOPATH=${HOME}/go
export PATH=${PATH}:/usr/local/go/bin:${GOPATH}/bin
mkdir ${GOPATH}

cat >> ~/.bashrc <<EOF
export GOPATH=${GOPATH}
export PATH=${PATH}
alias k=kubectl
EOF

# install singularity
SINGULARITY_REPO="https://github.com/sylabs/singularity"
git clone ${SINGULARITY_REPO} ${HOME}/singularity
cd ${HOME}/singularity && ./mconfig && cd ./builddir &&  make && sudo make install

# install singularity-cri
SINGULARITY_CRI_REPO="https://github.com/sylabs/singularity-cri"
git clone ${SINGULARITY_CRI_REPO} ${HOME}/singularity-cri
cd ${HOME}/singularity-cri && make && sudo make install

# install wlm-operator
SINGULARITY_WLM_OPERATOR_REPO="https://github.com/sylabs/wlm-operator"
git clone ${SINGULARITY_WLM_OPERATOR_REPO} ${HOME}/wlm-operator

# set up CNI config
sudo mkdir -p /etc/cni/net.d

# set up sycri service
sudo sh -c 'cat > /etc/systemd/system/sycri.service <<EOF
[Unit]
Description=Singularity-CRI
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=30
User=root
Group=root
ExecStart=${HOME}/singularity-cri/bin/sycri -v 2
EOF'
sudo systemctl start sycri
sudo systemctl status sycri

# install k8s
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

# configure crictl
sudo touch /etc/crictl.yaml
sudo chown root:root /etc/crictl.yaml
cat > /etc/crictl.yaml << EOF
runtime-endpoint: unix:///var/run/singularity.sock
image-endpoint: unix:///var/run/singularity.sock
timeout: 10
debug: false
EOF

# configure system network config
sudo modprobe br_netfilter
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
sudo sysctl -w net.ipv4.ip_forward=1

# Mkdir for Calico, Singularity won't create automatically ***HOW TO DO THIS AUTOMATICALL AT STARTUP??
mkdir -p /var/run/calico