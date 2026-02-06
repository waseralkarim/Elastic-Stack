## [**Reset the `elastic` superuser password**](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-with-debian-package#step-6-reset-the-elastic-superuser-password)

Because Elasticsearch runs with `systemd` and not in a terminal, the `elastic` superuser password is not output when Elasticsearch starts for the first time. Use the [`elasticsearch-reset-password`](https://www.elastic.co/docs/reference/elasticsearch/command-line-tools/reset-password) tool tool to set the password for the user. This only needs to be done once for the cluster, and can be done as soon as the first node is started.

```bash
cd /usr/share/elasticsearch/bin/

./elasticsearch-reset-password -i -u elastic
```

<img width="1080" height="297" alt="image (7)" src="https://github.com/user-attachments/assets/c4c5187a-5ebb-46f8-a85d-f0954b83a6a3" />


We recommend storing the `elastic` password as an environment variable in your shell. For example:

```bash
export  ELASTIC_PASSWORD="your_password"
```
