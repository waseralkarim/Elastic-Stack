# Kibana Installation

[**Install from the APT repository**](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-kibana-with-debian-package#deb-repo)

1. You may need to install the `apt-transport-https` package on Debian before proceeding:
    
    ```bash
    sudo apt-get install apt-transport-https
    ```
    
2. Save the repository definition to `/etc/apt/sources.list.d/elastic-9.x.list`:
    
    ```bash
    echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/9.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-9.x.list
    ```
    
3. Install the Kibana Debian package:
    
    ```bash
    sudo apt-get update && sudo apt-get install kibana
    ```
    

## [**Run Kibana with `systemd`**](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-kibana-with-debian-package#deb-running-systemd)

To configure Kibana to start automatically when the system starts, run the following commands:

```bash
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable kibana.service
```

Kibana can be started and stopped as follows:

```bash
sudo systemctl start kibana.service
sudo systemctl stop kibana.service
```

These commands provide no feedback as to whether Kibana was started successfully or not. Log information can be accessed using `journalctl -u kibana.service`.

### Authenticate Kibana with Elasticsearch

```bash
cp /etc/elasticsearch/certs/http_ca.crt /etc/kibana/ # run on root user
```

## [**Configure Kibana using the config file**](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-kibana-with-debian-package#deb-configuring)

Kibana loads its configuration from the :

```bash
sudo vim /etc/kibana/kibana.yml
```

```bash
server.port: 5601

server.host: "0.0.0.0"

elasticsearch.hosts: ["https://192.168.120.125:9200"]

elasticsearch.username: "kibana_system"
elasticsearch.password: "password"

elasticsearch.ssl.certificateAuthorities: [ "/etc/kibana/http_ca.crt" ]
elasticsearch.ssl.verificationMode: certificate
```

## Generate proper keys for fleet (official way)

Run **once**:

```bash
/usr/share/kibana/bin/kibana-encryption-keys generate

```

You’ll get output like:

```yaml
xpack.encryptedSavedObjects.encryptionKey:"a-long-random-string"
xpack.reporting.encryptionKey:"another-long-random-string"
xpack.security.encryptionKey:"yet-another-long-random-string"
```

These must be **32+ characters** - do NOT invent them manually.

---

## Add them to Kibana config

```bash
nano /etc/kibana/kibana.yml
```

Add **all three** (no quotes missing, no tabs):

```yaml
xpack.encryptedSavedObjects.encryptionKey:"PASTE_FROM_COMMAND"
xpack.reporting.encryptionKey:"PASTE_FROM_COMMAND"
xpack.security.encryptionKey:"PASTE_FROM_COMMAND"
```

Now restart kibana:

```bash
sudo systemctl restart kibana.service
```
Now access the kibana: 

```jsx
http://<ip/domain>:5601
```
<img width="1905" height="902" alt="image (2)" src="https://github.com/user-attachments/assets/0d4354c6-06f4-4f81-9edf-73a9fcf4a4c7" />

