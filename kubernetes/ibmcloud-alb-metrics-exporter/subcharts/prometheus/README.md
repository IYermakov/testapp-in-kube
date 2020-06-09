# To run helm install

cd subcharts/prometheus

(specify the namespace and hostname)

vi values.yaml

helm install --name prometheus .

# To delete prometheus
helm delete prometheus --purge
