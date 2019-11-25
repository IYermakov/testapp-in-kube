# ibmcloud-alb-metrics-exporter

This chart installs IBM Cloud ALB Metrics Exporter in an IKS (IBM Cloud Kubernetes Service) cluster.
In this readme, `IKS` stands for `IBM Cloud Kubernetes Service` and
`ALB` stands for `Application Load Balancer` (aka, Ingress Controller based on Nginx).

## Introduction

The ibmcloud-alb-metrics-exporter chart will install IBM Cloud ALB Metrics Exporter as a deployment, based off of Alpine Linux, in an IKS cluster.
ALB uses `vts` status module to report Ngnix metrics. The ibmcloud-alb-metrics-exporter will collect such metrics from each ALB pod by scraping the ALB pod's `/status/format/json` metric endpoint. Then it formats collected JSON document, containing metrics, in a way that is understood by Prometheus agent.
There is also a subchart provided to install Prometheus, so that ALB metrics are visible on the Prometheus dashboard.

## Chart Details

This chart will do the following:

* Creates ServiceAccounts, ClusterRoles and ClusterRoleBindings.
* Deploys IBM Cloud ALB Metrics Exporter pods to `kube-system` namespace.
* Optional- The helm chart under subcharts/prometheus will create prometheus pods and service exposed as an ingress resource.

## Prerequisites

* This chart must be used in IBM Cloud Kubernetes Service (IKS) only.
* This chart will work with any Kubernetes cluster version 1.10 and up.
* For IKS Cluster, connect to target [`kubectl` CLI](https://cloud.ibm.com/docs/containers?topic=containers-cs_cli_reference#cs_cluster_config) to the cluster.

## Resources Required

* This chart will work in any paid IKS cluster that has ALB deployment enabled.

## Installing the Chart
1. For IKS Cluster, follow the [instructions](https://cloud.ibm.com/docs/containers?topic=containers-integrations#helm) to install the Helm client on your local machine, install the Helm server (tiller) in your cluster, and add the IBM Cloud Helm chart repository to the cluster where you want to deploy the IBM Cloud ALB Metrics Exporter.

   **Important:** If you use Helm version 2.9 or higher, make sure that you installed tiller with a [service account](https://cloud.ibm.com/docs/containers?topic=containers-integrations#helm).

1. Add the IBM Cloud Helm repository `ibm` to your cluster.
   ```
   helm repo add iks-charts https://icr.io/helm/iks-charts
   ```

1. Update the Helm repo to retrieve the latest version of all Helm charts in this repo.
   ```
   helm repo update
   ```

1. Install the IBM Cloud ALB Metrics Exporter

  **Note** The container image registry requires secrets in order to pull the image into your cluster.  The only namespaces that have these secrets are default.
  In order to create the ALB Metrics Exporter deployment is non-default namespace, like, `kube-system`, make sure to copy the secret to this namespace.

   ```
   $ kubectl get secret default-icr-io -o yaml | sed 's/default/kube-system/g' |  kubectl -n kube-system create -f -
   secret/kube-system-icr-io created
   $ kubectl get secret -n kube-system | grep icr
   kube-system-icr-io                                   kubernetes.io/dockerconfigjson         1         11s
   ```

   Start with installation using `helm install`
   ```
   helm install iks-charts/ibmcloud-alb-metrics-exporter --name ibmcloud-alb-metrics-exporter --set albId=<alb-ID> --set metricsNameSpace=kube-system
   ```
   Replace with the ID of the ALB that you want to collect metrics for. To view the IDs for the ALBs in your cluster, run `ibmcloud ks albs --cluster <cluster_name>`.

   Example output:
   ```
   NAME:   ibmcloud-alb-metrics-exporter
   LAST DEPLOYED: Fri Jan 11 17:59:49 2019
   NAMESPACE: default
   STATUS: DEPLOYED

   RESOURCES:
   ==> v1/ServiceAccount
   NAME                         SECRETS  AGE
   alb-metrics-service-account  1        2s

   ==> v1beta1/ClusterRole
   NAME                              AGE
   alb-metrics-service-cluster-role  2s

   ==> v1alpha1/ClusterRoleBinding
   NAME                                      AGE
   alb-metrics-service-cluster-role-binding  1s

   ==> v1beta1/Deployment
   NAME                           DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
   ibmcloud-alb-metrics-exporter  2        2        2           0          1s

   ==> v1/Pod(related)
   NAME                                            READY  STATUS             RESTARTS  AGE
   ibmcloud-alb-metrics-exporter-596b4fbb7b-hpj6c  0/1    ContainerCreating  0         1s
   ibmcloud-alb-metrics-exporter-596b4fbb7b-p5c7g  0/1    ContainerCreating  0         1s

   NOTES:
   Thank you for installing: ibmcloud-alb-metrics-exporter. Your release is named: ibmcloud-alb-metrics-exporter
   Please refer Chart README.md file for additional instructions on how to use the IBM Cloud ALB Metrics Exporter.
   ```

## PodSecurityPolicy Requirements
A service account is created with the name `alb-metrics-service-account` in the namespace in which the chart is installed.  This service account provides access to all the necessary privileges needed by this chart.

## Verifying the Chart
Verify that the IBM Cloud ALB Metrics Exporter is installed correctly.
```
kubectl get pod -n kube-system -o wide | grep alb
```
Example output:
```
$ kubectl get pod -n kube-system -o wide | grep alb
ibmcloud-alb-metrics-exporter-596b4fbb7b-hpj6c                    1/1       Running   0          1h        172.30.180.76    10.93.34.44
ibmcloud-alb-metrics-exporter-596b4fbb7b-p5c7g                    1/1       Running   0          1h        172.30.193.139   10.93.34.27
public-crd47f533ee11947de9129b91d131ddf20-alb1-7dd7f5ddbd-jgtrw   4/4       Running   0          17h       172.30.180.74    10.93.34.44
public-crd47f533ee11947de9129b91d131ddf20-alb1-7dd7f5ddbd-n9cvl   4/4       Running   0          17h       172.30.193.135   10.93.34.27
```
The installation is successful when you see `ibmcloud-alb-metrics-exporter` pods in `Running` state. The number of `ibmcloud-alb-metrics-exporter` pods equals the number of `<ALB-ID>` pods in your cluster. The `ibmcloud-alb-metrics-exporter` pods must be scheduled on the same worker nodes where the ALB pods are deployed. If the pods fail, run `kubectl describe pod -n kube-system <pod_name>` to find the root cause for the failure.

## Uninstalling the Chart
If you done using the IBM Cloud ALB Metrics Exporter in your cluster, you can uninstall the Helm charts.

To remove the chart:

1. Find the installation name of your Helm chart.
   ```
   helm ls | grep ibmcloud-alb-metrics-exporter
   ```
   Example output:
   ```
     NAME                         	REVISION	UPDATED                 	STATUS  	CHART                              	APP VERSION	NAMESPACE
     ibmcloud-alb-metrics-exporter	1       	Sun Feb 17 23:51:43 2019	DEPLOYED	ibmcloud-alb-metrics-exporter-1.0.5	5.0        	default    
   ```

1. Delete the IBM Cloud ALB Metrics Exporter by removing the Helm chart.
   ```
   helm delete --purge ibmcloud-alb-metrics-exporter
   ```

1. Verify that the IBM Cloud ALB Metrics Exporter pods are removed.
   ```
   kubectl get pod -n kube-system | grep ibmcloud-alb-metrics-exporter
   ```
   The removal of the pods is successful if no pods are displayed in your CLI output.

## Configuration
n/a

## Limitations
* You must run this chart as the cluster admin, as it needs authority to access ALB resources.

## **_Optional:_** Install prometheus dashboard using helm chart

1. The install files are under subcharts/prometheus.
   ```
   helm install --name prometheus . --set nameSpace=kube-system --set hostName=prom-dash.<Ingress-Subdomain>
   ```
   Replace with `<Ingress-Subdomain>` with the Ingress subdomain of your IKS cluster.
   To view the subdomain for your cluster, run `ibmcloud ks cluster-get <cluster_name> | grep "Ingress Subdomain"`.

   Example output:
   ```
   NAME:   prometheus
   LAST DEPLOYED: Fri Jan 11 20:15:20 2019
   NAMESPACE: default
   STATUS: DEPLOYED

   RESOURCES:
   ==> v1/Pod(related)
   NAME                         READY  STATUS             RESTARTS  AGE
   prometheus-68c686d9bc-c5m8j  0/1    ContainerCreating  0         1s

   ==> v1/ConfigMap
   NAME                    DATA  AGE
   prometheus-server-conf  1     1s

   ==> v1/ServiceAccount
   NAME                         SECRETS  AGE
   kube-system-service-account  1        1s

   ==> v1beta1/ClusterRole
   NAME                    AGE
   prom-test-cluster-role  1s

   ==> v1alpha1/ClusterRoleBinding
   NAME                            AGE
   prom-test-cluster-role-binding  1s

   ==> v1/Service
   NAME      TYPE       CLUSTER-IP    EXTERNAL-IP  PORT(S)   AGE
   prom-svc  ClusterIP  172.21.172.5  <none>       9090/TCP  1s

   ==> v1beta1/Deployment
   NAME        DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
   prometheus  1        1        1           0          1s

   ==> v1beta1/Ingress
   NAME          HOSTS                                                              ADDRESS         PORTS  AGE
   prom-ingress  prom-dash.kgprod-mtrtest-9jan.us-south.containers.appdomain.cloud  169.61.193.110  80     1s
   ```

1. Verify the installation
   ```
   $ kubectl get pod,svc,ing -n kube-system | grep prom
   pod/prometheus-68c686d9bc-c5m8j                                       1/1       Running   0          1m

   service/prom-svc                                         ClusterIP      172.21.172.5     <none>           9090/TCP                     1m

   ingress.extensions/prom-ingress         prom-dash.kgprod-mtrtest-9jan.us-south.containers.appdomain.cloud   169.61.193.110   80        1m
   ```
   The installation is successful when the `prometheus` pod is in `Running` state and ingress resource `prom-ingress` has been created. Access the Prometheus dashboard from your browser, to view ALB metrics. The URL is the ingress host for `prom-ingress` resource. Example dashboard URL `http://prom-dash.kgprod-mtrtest-9jan.us-south.containers.appdomain.cloud/graph`

1. To uninstall the prometheus dashboard from your cluster using helm
   ```
   helm delete --purge prometheus
   ```
   Verify that the prometheus pods are removed using the command `kubectl get pod -n kube-system | grep prom`.

## Further reading

https://cloud.ibm.com/docs/containers/cs_ingress_health.html#ingress_monitoring

https://github.com/vozlt/nginx-module-vts#synopsis

https://cloud.ibm.com/docs/containers/cs_ingress.html#planning
