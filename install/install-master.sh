#!/usr/bin/env bash
export IPADDR=$(ifconfig VLAN1816 | grep inet | awk '{print $2}'| cut -f2 -d:)
sudo kubeadm init --cri-socket="unix:///var/run/singularity.sock" \
          --ignore-preflight-errors=all \
          --apiserver-advertise-address="${IPADDR}" \
          --apiserver-cert-extra-sans="${IPADDR}"  \
          --node-name ${HOSTNAME} --pod-network-cidr=10.244.0.0/16

mkdir -p ${HOME}/.kube
sudo cp -i /etc/kubernetes/admin.conf ${HOME}/.kube/config
sudo chown root:root ${HOME}/.kube/config
cp ${HOME}/.kube/config /root/wlm-operator/install/etc/config

sudo -E sh -c 'cat >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf <<EOF
Environment="KUBELET_EXTRA_ARGS=--node-ip=${IPADDR}"
EOF'

kubectl apply -f ${HOME}/wlm-operator/install/etc/calico.yaml

sudo systemctl daemon-reload
sudo systemctl restart kubelet

JOIN_COMMAND=$(kubeadm token create --print-join-command)
cat > ${HOME}/wlm-operator/install/etc/join.sh <<EOF
${JOIN_COMMAND} --ignore-preflight-errors=all --cri-socket='unix:///var/run/singularity.sock'
EOF