#!/usr/bin/env bash
kubectl apply -f ${HOME}/wlm-operator/deploy/crds/wlm_v1alpha1_slurmjob.yaml
kubectl apply -f ${HOME}/wlm-operator/deploy/crds/wlm_v1alpha1_wlmjob.yaml
kubectl apply -f ${HOME}/wlm-operator/deploy/operator-rbac.yaml
kubectl apply -f ${HOME}/wlm-operator/deploy/operator.yaml
kubectl apply -f ${HOME}/wlm-operator/deploy/configurator.yaml
