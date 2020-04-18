# Prometheus and Grafana

This Repo is used to store script and configuration for Prometheus and Grafana that I am working on.

## Installing the Prometheus

```bash
bash scripts/1-install-prometheus.sh
```

## Installing Node Exporter
```bash
bash scripts/2-install-node-exporter.sh
```


## Grafana DevOps Way

Let's install the grafana on the host
```bash
bash scripts/3-install-grafana.sh
```

Now we need to create the directory to store the dashboards
```bash
mkdir /var/lib/grafana/dashboards
```

We have some definition about the configuration of the datasource of Prometheus. The definition of the datasource, and some configuration about how it will work.
```yaml
apiVersion: 1
datasources:
 - name: Prometheus
   type: prometheus
   orgId: 1
   url: http://localhost:9090
   access: proxy
   version: 1
   editable: false
   isDefault: true
```

We have some definition about the dashboard configuration. The definition of the dashboard where will get the information about them, this is the whey the dashboards will be imported.
```yaml
apiVersion: 1
providers:
 - name: 'default'
   orgId: 1
   folder: ''
   type: file
   options:
     path: /var/lib/grafana/dashboards
```

Now we need to copy the files
```bash
cp grafana/provisioning/datasource-prometheus.yaml /etc/grafana/provisioning/datasources/datasource-prometheus.yaml
cp grafana/provisioning/dashboards.yaml /etc/grafana/provisioning/dashboards/dashboards.yaml
cp grafana/dashboards/node-dashboard.json /var/lib/grafana/dashboards/node-dashboard.json
```

Now we need to restart the grafana
```bash
systemctl restart grafana-server
```