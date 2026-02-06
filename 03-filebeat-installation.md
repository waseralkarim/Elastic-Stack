# Filebeat Installations

# [**APT**](https://www.elastic.co/docs/reference/beats/filebeat/setup-repositories#_apt)

To add the Beats repository for APT:

1. Download and install the Public Signing Key:
    
    ```bash
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
    ```
    
2. You may need to install the `apt-transport-https` package on Debian before proceeding:
    
    ```bash
    sudo apt-get install apt-transport-https
    ```
    
3. Save the repository definition to */etc/apt/sources.list.d/elastic-9.x.list*:
    
    ```bash
    echo "deb https://artifacts.elastic.co/packages/9.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-9.x.list
    ```
    
4. Run `apt-get update`, and the repository is ready for use. For example, you can install Filebeat by running:
    
    ```bash
    sudo apt-get update && sudo apt-get install filebeat
    ```
    
5. To configure Filebeat to start automatically during boot, run:
    
    ```bash
    sudo systemctl enable filebeat
    ```
    

### Enable Module and check Filebeat modules list

```bash
filebeat modules enable nginx
filebeat modules list
```
<img width="1356" height="703" alt="image (3)" src="https://github.com/user-attachments/assets/7bdef7f7-0aaf-49ce-a737-8e9316923845" />

Check logs with:

```bash
filebeat setup -e
```

<img width="1611" height="720" alt="image (4)" src="https://github.com/user-attachments/assets/6874aa18-45e6-42b9-8c0a-27c92993ccdc" />

Edit nginx module config: 

```bash
sudo vim /etc/filebeat/modules.d/nginx.yml
```
<img width="1412" height="551" alt="image (5)" src="https://github.com/user-attachments/assets/8fac9c18-f35c-499d-bb9d-0485ae3ffc80" />

Check the logs in elastic:

<img width="1918" height="908" alt="image (6)" src="https://github.com/user-attachments/assets/cca28c04-48b9-45bf-9a16-8e638e6d4411" />


