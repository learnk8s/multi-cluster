#! /bin/bash

LB_AP=$(kubectl --kubeconfig=../kubeconfig-ap get service -n istio-system -l app=istio-ingressgateway -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
LB_US=$(kubectl --kubeconfig=../kubeconfig-us get service -n istio-system -l app=istio-ingressgateway -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
LB_EU=$(kubectl --kubeconfig=../kubeconfig-eu get service -n istio-system -l app=istio-ingressgateway -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
echo "ready on localhost:8082"
node ../world-map/index.js "{\"ap\":\"http://$LB_AP/env\",\"us\":\"http://$LB_US/env\",\"eu\":\"http://$LB_EU/env\"}"