# Prometheus and Grafana

This Repo is used to store script and configuration for Prometheus and Grafana that I am working on.

## Task Lists

- [ ] Configure the reverse Proxy Nginx
- [ ] Configure the docker-compose for client only
- [ ] Review the security
- [ ] Configure TLS to connect to new clients
- [ ] Make sure the internal services are not expose
- [ ] Review the Dashboards

## Dashboard List
- https://grafana.com/grafana/dashboards/1860
- https://grafana.com/grafana/dashboards/179
- https://grafana.com/grafana/dashboards/10694

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

## The Docker Way

Installing the Docker
```bash
wget -c https://raw.githubusercontent.com/douglasqsantos/DevOps/master/Docker/install-docker.sh
```

Running the script
```bash
bash install-docker.sh
```

Accessing the docker directory
```bash
cd docker
```

Now we need to configure the env file, I will keep the default, but if you need to change the version feel at home :D
```bash
mv env.vars .env
```

Now we need to run the docker-compose
```bash
docker-compose up -d
Creating docker_node-exporter_1 ... done
Creating docker_cadvisor_1      ... done
Creating docker_alertmanager_1  ... done
Creating docker_prometheus_1    ... done
Creating docker_grafana_1       ... done
```

Now we can list the images
```bash
docker ps
CONTAINER ID        IMAGE                                       COMMAND                  CREATED             STATUS                    PORTS                    NAMES
3cc943137678        grafana/grafana:6.7.2                       "/run.sh"                34 seconds ago      Up 32 seconds             0.0.0.0:3000->3000/tcp   docker_grafana_1
f170d9e5ae9e        prom/prometheus:v2.17.1                     "/bin/prometheus --c…"   35 seconds ago      Up 33 seconds             0.0.0.0:9090->9090/tcp   docker_prometheus_1
d91fba426b59        prom/node-exporter:v0.18.1                  "/bin/node_exporter …"   38 seconds ago      Up 35 seconds             0.0.0.0:9100->9100/tcp   docker_node-exporter_1
fd506b754d9a        gcr.io/google-containers/cadvisor:v0.35.0   "/usr/bin/cadvisor -…"   38 seconds ago      Up 36 seconds (healthy)   0.0.0.0:8080->8080/tcp   docker_cadvisor_1
c25148efc405        prom/alertmanager                           "/bin/alertmanager -…"   38 seconds ago      Up 34 seconds             0.0.0.0:9093->9093/tcp   docker_alertmanager_1
```

We can access:
- Prometheus at: http://<Host IP Address>:9090
- Grafana at: http://<Host IP Address>:3000
  - User: admin
  - Password: foobar
- cAdvisor at: http://<Host IP Address>:8080
- Node Exporter: http://<Host IP Address>:9100
- Alertmanager: http://<Host IP Address>:9093

## Sping up with Swarm

Starting the Docker Swarm
```bash
docker swarm init
Swarm initialized: current node (ux6th4kqdjdlvrz2ufrtufjmt) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-3ezs5iw5dz02apftgwf48f7iw6uqxofeah208n4n1zgupifj9z-4vok8r64wf3xqvaehp4qbjoeb 192.168.0.31:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

Accessing the docker directory
```bash
cd docker
```

Now we need to configure the env file, I will keep the default, but if you need to change the version feel at home :D
```bash
mv env.vars .env
```

If you would like to change which targets should be monitored or make configuration changes edit the /prometheus/prometheus.yml file. The targets section is where you define what should be monitored by Prometheus. The names defined in this file are actually sourced from the service name in the docker-compose file. If you wish to change names of the services you can add the "container_name" parameter in the docker-compose.yml file.

Once configurations are done let's start it up. From the /prometheus project directory run the following command:

Now we can start the service
```bash 
docker stack deploy -c docker-stack.yml prom
Creating network prom_monitor-net
Creating service prom_node-exporter
Creating service prom_alertmanager
Creating service prom_cadvisor
Creating service prom_grafana
Creating service prom_prometheus
```

That's it the `docker stack deploy' command deploys the entire Grafana and Prometheus stack automatically to the Docker Swarm. By default cAdvisor and node-exporter are set to Global deployment which means they will propogate to every docker host attached to the Swarm.

We can access:
- Prometheus at: http://<Host IP Address>:9090
- Grafana at: http://<Host IP Address>:3000
  - User: admin
  - Password: foobar
- cAdvisor at: http://<Host IP Address>:8080
- Node Exporter: http://<Host IP Address>:9100
- Alertmanager: http://<Host IP Address>:9093

In order to check the status of the newly created stack:
```bash
docker stack ps prom
ID                  NAME                                           IMAGE                       NODE                DESIRED STATE       CURRENT STATE                ERROR               PORTS
cxerfdo7oj25        prom_cadvisor.ux6th4kqdjdlvrz2ufrtufjmt        google/cadvisor:latest      kube-master         Running             Running about a minute ago
ypt4o9jhfytl        prom_node-exporter.ux6th4kqdjdlvrz2ufrtufjmt   prom/node-exporter:latest   kube-master         Running             Running about a minute ago
4jdii34a87bt        prom_prometheus.1                              prom/prometheus:latest      kube-master         Running             Running about a minute ago
s4n1gzy0kdds        prom_grafana.1                                 grafana/grafana:latest      kube-master         Running             Running about a minute ago
wkp1y2x47gat        prom_alertmanager.1                            prom/alertmanager:latest    kube-master         Running             Running about a minute ago
```

View running services:
```bash
docker service ls
ID                  NAME                 MODE                REPLICAS            IMAGE                       PORTS
oibe819q0k1y        prom_alertmanager    replicated          1/1                 prom/alertmanager:latest    *:9093->9093/tcp
ms2tdmfdx5ea        prom_cadvisor        global              1/1                 google/cadvisor:latest      *:8080->8080/tcp
vof0da0pv0fl        prom_grafana         replicated          1/1                 grafana/grafana:latest      *:3000->3000/tcp
uy8tw6kv6vt0        prom_node-exporter   global              1/1                 prom/node-exporter:latest   *:9100->9100/tcp
hpn6s0wabbs0        prom_prometheus      replicated          1/1                 prom/prometheus:latest      *:9090->9090/tcp
````

View logs for a specific service
```bash
docker service logs prom_<service_name>
```

View logs for prometheus
```bash
docker service logs prom_prometheus
prom_prometheus.1.4jdii34a87bt@kube-master    | level=info ts=2020-04-19T13:49:17.731Z caller=main.go:298 msg="no time or size retention was set so using the default time retention" duration=15d
prom_prometheus.1.4jdii34a87bt@kube-master    | level=info ts=2020-04-19T13:49:17.731Z caller=main.go:333 msg="Starting Prometheus" version="(version=2.17.1, branch=HEAD, revision=ae041f97cfc6f43494bed65ec4ea4e3a0cf2ac69)"
prom_prometheus.1.4jdii34a87bt@kube-master    | level=info ts=2020-04-19T13:49:17.732Z caller=main.go:334 build_context="(go=go1.13.9, user=root@806b02dfe114, date=20200326-16:18:19)"
prom_prometheus.1.4jdii34a87bt@kube-master    | level=info ts=2020-04-19T13:49:17.732Z caller=main.go:335 host_details="(Linux 4.15.0-20-generic #21-Ubuntu SMP Tue Apr 24 06:16:15 UTC 2018 x86_64 ebcfdaff3a30 (none))"
prom_prometheus.1.4jdii34a87bt@kube-master    | level=info ts=2020-04-19T13:49:17.732Z caller=main.go:336 fd_limits="(soft=1048576, hard=1048576)"
prom_prometheus.1.4jdii34a87bt@kube-master    | level=info ts=2020-04-19T13:49:17.732Z caller=main.go:337 vm_limits="(soft=unlimited, hard=unlimited)"
prom_prometheus.1.4jdii34a87bt@kube-master    | level=info ts=2020-04-19T13:49:17.736Z caller=main.go:667 msg="Starting TSDB ..."
prom_prometheus.1.4jdii34a87bt@kube-master    | level=info ts=2020-04-19T13:49:17.736Z caller=web.go:514 component=web msg="Start listening for connections" address=0.0.0.0:9090
prom_prometheus.1.4jdii34a87bt@kube-master    | level=info ts=2020-04-19T13:49:17.738Z caller=head.go:575 component=tsdb msg="replaying WAL, this may take awhile"
prom_prometheus.1.4jdii34a87bt@kube-master    | level=info ts=2020-04-19T13:49:17.739Z caller=head.go:624 component=tsdb msg="WAL segment loaded" segment=0 maxSegment=0
prom_prometheus.1.4jdii34a87bt@kube-master    | level=info ts=2020-04-19T13:49:17.739Z caller=head.go:627 component=tsdb msg="WAL replay completed" duration=127.295µs
prom_prometheus.1.4jdii34a87bt@kube-master    | level=info ts=2020-04-19T13:49:17.740Z caller=main.go:683 fs_type=EXT4_SUPER_MAGIC
prom_prometheus.1.4jdii34a87bt@kube-master    | level=info ts=2020-04-19T13:49:17.740Z caller=main.go:684 msg="TSDB started"
prom_prometheus.1.4jdii34a87bt@kube-master    | level=info ts=2020-04-19T13:49:17.740Z caller=main.go:788 msg="Loading configuration file" filename=/etc/prometheus/prometheus.yml
prom_prometheus.1.4jdii34a87bt@kube-master    | level=info ts=2020-04-19T13:49:17.742Z caller=main.go:816 msg="Completed loading of configuration file" filename=/etc/prometheus/prometheus.yml
prom_prometheus.1.4jdii34a87bt@kube-master    | level=info ts=2020-04-19T13:49:17.742Z caller=main.go:635 msg="Server is ready to receive web requests."
```

## Add Datasources and Dashboards

Grafana version 5.0.0 has introduced the concept of provisioning. This allows us to automate the process of adding Datasources & Dashboards. The `/grafana/provisioning/` directory contains the `datasources` and `dashboards` directories. These directories contain YAML files which allow us to specify which datasource or dashboards should be installed.

If you would like to automate the installation of additional dashboards just copy the Dashboard `JSON` file to `/grafana/provisioning/dashboards` and it will be provisioned next time you stop and start Grafana.

## Alerting

Alerting has been added to the stack with Slack integration. 2 Alerts have been added and are managed

Alerts              - `prometheus/alert.rules`
Slack configuration - `alertmanager/config.yml`

The Slack configuration requires to build a custom integration.
* Open your slack team in your browser `https://<your-slack-team>.slack.com/apps`
* Click build in the upper right corner
* Choose Incoming Web Hooks link under Send Messages
* Click on the "incoming webhook integration" link
* Select which channel
* Click on Add Incoming WebHooks integration
* Copy the Webhook URL into the `alertmanager/config.yml` URL section
* Fill in Slack username and channel

View Prometheus alerts `http://<Host IP Address>:9090/alerts`
View Alert Manager `http://<Host IP Address>:9093`


### Test Alerts
A quick test for your alerts is to stop a service. Stop the node_exporter container and you should notice shortly the alert arrive in Slack. Also check the alerts in both the Alert Manager and Prometheus Alerts just to understand how they flow through the system.

High load test alert - `docker run --rm -it busybox sh -c "while true; do :; done"`

Let this run for a few minutes and you will notice the load alert appear. Then Ctrl+C to stop this container.

### Add Additional Datasources
Now we need to create the Prometheus Datasource in order to connect Grafana to Prometheus
* Click the `Grafana` Menu at the top left corner (looks like a fireball)
* Click `Data Sources`
* Click the green button `Add Data Source`.

**Ensure the Datasource name `Prometheus`is using uppercase `P`**

# Security Considerations
This project is intended to be a quick-start to get up and running with Docker and Prometheus. Security has not been implemented in this project. It is the users responsability to implement Firewall/IpTables and SSL.

Since this is a template to get started Prometheus and Alerting services are exposing their ports to allow for easy troubleshooting and understanding of how the stack works.

## Deploy Prometheus stack with Traefik

Same requirements as above. Swarm should be enabled and the Repo should be cloned to your Docker host.

In the `docker-traefik-prometheus`directory run the following:

    docker stack deploy -c docker-traefik-stack.yml traefik

Verify all the services have been provisioned. The Replica count for each service should be 1/1
**Note this can take a couple minutes**

    docker service ls

## Prometheus & Grafana now have hostnames

* Grafana - http://grafana.localhost
* Prometheus - http://prometheus.localhost

## Check the Metrics
Once all the services are up we can open the Traefik Dashboard. The dashboard should show us our frontend and backends configured for both Grafana and Prometheus.

    http://localhost:8080


Take a look at the metrics which Traefik is now producing in Prometheus metrics format

    http://localhost:8080/metrics


## Login to Grafana and Visualize Metrics

Grafana is an Open Source visualization tool for the metrics collected with Prometheus. Next, open Grafana to view the Traefik Dashboards.
**Note: Firefox doesn't properly work with the below URLS please use Chrome**

    http://grafana.localhost

Username: admin
Password: foobar

Open the Traefik Dashboard and select the different backends available

**Note: Upper right-hand corner of Grafana switch the default 1 hour time range down to 5 minutes. Refresh a couple times and you should see data start flowing**

# Production Security:

Here are just a couple security considerations for this stack to help you get started.
* Remove the published ports from Prometheus and Alerting servicesi and only allow Grafana to be accessed
* Enable SSL for Grafana with a Proxy such as [jwilder/nginx-proxy](https://hub.docker.com/r/jwilder/nginx-proxy/) or [Traefik](https://traefik.io/) with Let's Encrypt
* Add user authentication via a Reverse Proxy [jwilder/nginx-proxy](https://hub.docker.com/r/jwilder/nginx-proxy/) or [Traefik](https://traefik.io/) for services cAdvisor, Prometheus, & Alerting as they don't support user authenticaiton
* Terminate all services/containers via HTTPS/SSL/TLS

# Troubleshooting

It appears some people have reported no data appearing in Grafana. If this is happening to you be sure to check the time range being queried within Grafana to ensure it is using Today's date with current time.

# Interesting Projects that use this Repo
Several projects utilize this Prometheus stack. Here's the list of projects:

* [Docker Pulls](https://github.com/vegasbrianc/docker-pulls) - Visualize Docker-Hub pull statistics with Prometheus
* [GitHub Monitoring](https://github.com/vegasbrianc/github-monitoring) - Monitor your GitHub projects with Prometheus
* [Traefik Reverse Proxy/Load Balancer Monitoring](https://github.com/vegasbrianc/docker-traefik-prometheus) - Monitor the popular Reverse Proxy/Load Balancer Traefik with Prometheus
* [internet monitoring](https://github.com/maxandersen/internet-monitoring) - Monitor your local network, internet connection and speed with Prometheus.
* [Dockerize Your Dev](https://github.com/RiFi2k/dockerize-your-dev) - Docker compose a VM to get LetsEncrypt / NGINX proxy auto provisioning, ELK logging, Prometheus / Grafana monitoring, Portainer GUI, and more...

## Reference Repo
- https://github.com/vegasbrianc/prometheus
- https://github.com/in4it/prometheus-course
- https://help.github.com/en/github/writing-on-github/basic-writing-and-formatting-syntax