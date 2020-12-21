#!/usr/bin/env bash

sudo chmod +x ${HOME}/wlm-operator/install/etc/join.sh 
sudo ${HOME}/wlm-operator/install/etc/join.sh
mkdir .kube && cp ${HOME}/wlm-operator/install/etc/config ${HOME}/.kube/config

export IPADDR=$(ifconfig VLAN1816 | grep inet | awk '{print $2}'| cut -f2 -d:)
sudo -E sh -c 'cat >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf <<EOF
Environment="KUBELET_EXTRA_ARGS=--node-ip=${IPADDR}"
EOF'

sudo systemctl daemon-reload
sudo systemctl restart kubelet