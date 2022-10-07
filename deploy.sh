#!/bin/bash
kubectl apply -f https://download.elastic.co/downloads/eck/2.2.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.2.0/operator.yaml
kubectl apply -f ./k8s/elasticsearch.yml
kubectl delete secret elastic-es-elastic-user -n elastic
kubectl apply -f ./k8s/elastic-es-elastic-user.yml
kubectl apply -f ./k8s/eck-license.yml
sleep 1m
kubectl apply -f ./k8s/kibana.yml
#kubectl apply -f ./k8s/metricbeat.yml
# aws-load-balancer-controller CRDs:
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
