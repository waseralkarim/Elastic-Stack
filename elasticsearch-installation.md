# Elasticsearch Installation

Download and install the public signing key:

```bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
```

[**Install from the APT repository**](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-with-debian-package#deb-repo)

1. You may need to install the `apt-transport-https` package on Debian before proceeding:
    
    ```bash
    sudo apt-get install apt-transport-https
    ```
    
2. Save the repository definition to `/etc/apt/sources.list.d/elastic-9.x.list`:
    
    ```bash
    echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/9.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-9.x.list
    ```
    
3. Install the Elasticsearch Debian package:
    
    ```bash
    sudo apt-get update && sudo apt-get install elasticsearch
    ```
    

![image.png](attachment:c2cd992b-0007-4b1f-a833-8821248e16fc:image.png)

### [**Set up a node as the first node in a cluster**](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-with-debian-package#first-node)

Update the Elasticsearch configuration on this first node so that other hosts are able to connect to it by editing the settings in [`elasticsearch.yml`](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/configure-elasticsearch):

Backup existing config: 

```bash
sudo cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.bak
```

1. Open `elasticsearch.yml` in a text editor. 

```bash
sudo vim /etc/elasticsearch/elasticsearch.yml
```

1. In a multi-node Elasticsearch cluster, all of the Elasticsearch instances need to have the same name.
    
    In the configuration file, uncomment the line `#cluster.name: my-application` and give the Elasticsearch instance any name that you’d like:
    
    ```bash
    cluster.name: elasticsearch-demo
    ```
    
2. By default, Elasticsearch runs on `localhost`. For Elasticsearch instances on other nodes to be able to join the cluster, you need to set up Elasticsearch to run on a routable, external IP address.
    
    Uncomment the line `#network.host: 192.168.0.1` and replace the default address with `0.0.0.0`. The `0.0.0.0` setting enables Elasticsearch to listen for connections on all available network interfaces. In a production environment, you might want to [use a different value](https://www.elastic.co/docs/reference/elasticsearch/configuration-reference/networking-settings#common-network-settings), such as a static IP address or a reference to a [network interface of the host](https://www.elastic.co/docs/reference/elasticsearch/configuration-reference/networking-settings#network-interface-values).
    
    ```bash
    cluster.name: your-desired-name
    
    network.host: 0.0.0.0 # Or provide instance ip
    
    http.port: 9200
    ```
    
3. Elasticsearch needs to be enabled to listen for connections from other, external hosts.
    
    Uncomment the line `#transport.host: 0.0.0.0`. The `0.0.0.0` setting enables Elasticsearch to listen for connections on all available network interfaces. In a production environment you might want to [use a different value](https://www.elastic.co/docs/reference/elasticsearch/configuration-reference/networking-settings#common-network-settings), such as a static IP address or a reference to a [network interface of the host](https://www.elastic.co/docs/reference/elasticsearch/configuration-reference/networking-settings#network-interface-values).
    
    ```bash
    transport.host: 0.0.0.0
    ```
    
    **Tip**
    
    You can find details about the `network.host` and `transport.host` settings in the Elasticsearch [networking settings reference](https://www.elastic.co/docs/reference/elasticsearch/configuration-reference/networking-settings).
    
4. Save your changes and close the editor.

![image.png](attachment:0cc2b675-12f8-4819-9196-d7fbe6cdb394:image.png)

## [**Run Elasticsearch with `systemd`**](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-with-debian-package#running-systemd)

To configure Elasticsearch to start automatically when the system boots up, run the following commands:

```bash
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service
```

Elasticsearch can be started and stopped as follows:

```bash
sudo systemctl start elasticsearch.service
sudo systemctl stop elasticsearch.service
```

## [**Check that Elasticsearch is running**](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-with-debian-package#deb-check-running)

You can test that your Elasticsearch node is running by sending an HTTPS request to port `9200` on `localhost`:

```bash
sudo curl --cacert /etc/elasticsearch/certs/http_ca.crt -u elastic:$ELASTIC_PASSWORD https://localhost:9200
```

1. `-cacert`: Path to the generated `http_ca.crt` certificate for the HTTP layer.
2. Replace `$ELASTIC_PASSWORD` with the `elastic` superuser password. Ensure that you use `https` in your call, or the request will fail.

The call returns a response like this:

```bash
{
  "name" : "Cp8oag6",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "AT69_T_DTp-1qgIJlatQqA",
  "version" : {
    "number" : "9.0.0-SNAPSHOT",
    "build_type" : "tar",
    "build_hash" : "f27399d",
    "build_flavor" : "default",
    "build_date" : "2016-03-30T09:51:41.449Z",
    "build_snapshot" : false,
    "lucene_version" : "10.0.0",
    "minimum_wire_compatibility_version" : "1.2.3",
    "minimum_index_compatibility_version" : "1.2.3"
  },
  "tagline" : "You Know, for Search"
}
```

## [**Reset the `elastic` superuser password**](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-with-debian-package#step-6-reset-the-elastic-superuser-password)

Because Elasticsearch runs with `systemd` and not in a terminal, the `elastic` superuser password is not output when Elasticsearch starts for the first time. Use the [`elasticsearch-reset-password`](https://www.elastic.co/docs/reference/elasticsearch/command-line-tools/reset-password) tool tool to set the password for the user. This only needs to be done once for the cluster, and can be done as soon as the first node is started.

```bash
cd /usr/share/elasticsearch/bin/

./elasticsearch-reset-password -i -u elastic
```

![image.png](attachment:a6e67c65-7187-4a94-b9c7-1b71337e1aee:image.png)

We recommend storing the `elastic` password as an environment variable in your shell. For example:

```bash
export  ELASTIC_PASSWORD="your_password"
```
