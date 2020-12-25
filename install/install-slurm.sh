#!/usr/bin/env bash

#THIS IS DONE ON THE SLURM NODES, NOT THE K8S MASTER. 
yum install -y epel-release && \
yum install -y munge munge-libs munge-devel

export MUNGEUSER=1001
groupadd -g $MUNGEUSER munge
useradd  -m -c "MUNGE Uid 'N' Gid Emporium" -d /var/lib/munge -u $MUNGEUSER -g munge  -s /sbin/nologin munge
export SlurmUSER=1002
groupadd -g $SlurmUSER slurm
useradd  -m -c "Slurm workload manager" -d /var/lib/slurm -u $SlurmUSER -g slurm  -s /bin/bash slurm

# On node1: 
# /usr/sbin/create-munge-key -r
# scp -p /etc/munge/munge.key hostXXX:/etc/munge/munge.key
# scp -p /etc/munge/munge.key 10.108.16.222:/etc/munge/munge.key

chown -R munge: /etc/munge/ /var/log/munge/
chmod 0700 /etc/munge/ /var/log/munge/

systemctl enable munge
systemctl start  munge

yum install -y rpm-build gcc openssl openssl-devel libssh2-devel pam-devel numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel rrdtool-devel ncurses-devel gtk2-devel libssh2-devel libibmad libibumad perl-Switch perl-ExtUtils-MakeMaker man2html python3 mariadb-server mariadb-devel

mkdir -p ${HOME}/slurm
wget -O ${HOME}/slurm/slurm-20.11.1.tar.bz2 https://download.schedmd.com/slurm/slurm-20.11.1.tar.bz2

export VER=20.11.1
cd ${HOME}/slurm/ && rpmbuild -ta slurm-$VER.tar.bz2
cd ${HOME}/rpmbuild/RPMS/x86_64 && \
  yum install -y slurm-$VER*rpm slurm-devel-$VER*rpm slurm-perlapi-$VER*rpm slurm-torque-$VER*rpm slurm-example-configs-$VER*rpm slurm-slurmctld-$VER*rpm slurm-slurmd-$VER*rpm


HOST_NAME=$(hostname)
export HOST_NAME

sudo -E sh -c 'cat > /etc/slurm/slurm.conf <<EOF
ControlMachine=wlm-op-node-1
AuthType=auth/munge
CacheGroups=0
CryptoType=crypto/munge
MpiDefault=none
ProctrackType=proctrack/pgid
ReturnToService=1
SlurmctldPidFile=/var/run/slurm/slurmctld.pid
SlurmctldPort=6817
SlurmdPidFile=/var/run/slurm/slurmd.pid
SlurmdPort=6818
SlurmdSpoolDir=/var/lib/slurm/slurmd
SlurmUser=slurm
StateSaveLocation=/var/lib/slurm/slurmctld
SwitchType=switch/none
TaskPlugin=task/none
InactiveLimit=0
KillWait=30
MinJobAge=300
SlurmctldTimeout=120
SlurmdTimeout=300
Waittime=0
SchedulerType=sched/backfill
SchedulerPort=7321
SelectType=select/linear
#AccountingStorageType=accounting_storage/filetxt
AccountingStoreJobComment=YES
ClusterName=cluster
JobCompType=jobcomp/filetxt
JobAcctGatherFrequency=30
JobAcctGatherType=jobacct_gather/none
JobCompLoc=/var/log/slurm/job_completions
SlurmctldDebug=3
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdDebug=3
SlurmdLogFile=/var/log/slurm/slurmd.log
NodeName=wlm-op-node-1,wlm-op-node-2,wlm-op-node-3 CPUs=2 State=UNKNOWN
PartitionName=debug Nodes=wlm-op-node-1,wlm-op-node-2,wlm-op-node-3 Default=YES MaxTime=30 State=UP MaxMemPerNode=512 MaxCPUsPerNode=2 MaxNodes=1
EOF'

mkdir -p /var/log/slurm
sudo touch /var/log/slurm/accounting
mkdir -p /var/run/slurm
mkdir -p /var/lib/slurm/slurmctld

sudo chown -R slurm /var/log/slurm
sudo chown -R slurm /var/run/slurm
sudo chown -R slurm /var/lib/slurm


sudo systemctl enable --now slurmctld
sudo systemctl enable --now slurmd
