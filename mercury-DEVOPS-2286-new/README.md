# _Mercury_Deployment:development

#### Prerequisites
- gcloud SDK >= 319.0.0
- terraform cli >= v0.14.3
#### 1. Infrastructure Provisioning
- Terraform provisions the VM and the external IP
(Instance Name, Instance Location, Machine Type, AZ_DATABASE and Disk Size (GB) configurable through terraform/terraform.tfvars file)
- Terraform files have scripts in place which installs docker swarm,creates deployment user and git folder and some prerequisites for Traefik after instance provisioning
- GCP Project Name : mercury-development-311316
- Project Name, Credention file name is configured in the provider block in terraform/main.tf
- Credential File is a GCP service account json key. The service account requires the following permissions
    - Compute Instance Admin (v1)
    - Compute Network Admin
- We have also added/created user deployment in the VM through terraform instance.tf file inside module.
- Commands :
     ```
     cd terraform/
     terraform init
     terraform plan
     terraform apply
     # Post the provisioning, external IP is returned as output (result of the apply command). Save this for later.
     ```
- Here we have added firewalls http and https tags in tf file, but morever while creating VM for the first time on the project in that case, this needs to be manually checked into after the VM is created.
  click on instance -----> click on edit option-------> under details section -----> Firewalls----> Check the http and https option. 

     # To clone github repository and do docker login inside VM using keys for deployment user(transfer keys)

- Now after that we want that we should be able to clone github repository and docker login inside the VM with user deployment@aditazz so, for that we have encrypted keys for gihub and docker respectively
- Since the keys stored are in encrypted form, which can decrypted using git-crypt having gpg key.Firstly we need to install git-crypt and initialize it using commands

    ``` sudo apt install git-crypt ```
    ``` git-crypt init ```
    ``` git-crypt status ```

- Run the following command to decrypt keys which is later to be transferred into VM
    ``` git-crypt unlock <user.gpg>```
   
- We need to transfer decrypted github keys and docker keys using scp command inside the VM in order to clone the existing repo and to perform docker login and store github id_rsa private and public key in .ssh directory
    gcloud beta compute scp --recurse --zone $INSTANCE_ZONE --project $PROJECT_ID ./mercury/accounts/deployment@aditazz.com/ deployment@$INSTANCE_NAME:~/home/deployment/

- Now clone the repository using git clone command  --------use keys of user deployment@aditazz
    ``` git clone -b <branch-name> git@github.com:<repo-name> ```

- To docker login 
   ``` docker login -u <username> -p <passsword> ```  ---------- use credentials of user deployment@aditazz 
 

#### 2. DNS Mapping : Out Of Scope for automation

- Map dev.mercury.aditazz.com and www.dev.mercury.aditazz.com to the external IP
    1. Get external IP of VM from
        https://console.cloud.google.com/compute/instances?project=mercury-development-311316&authuser=1&cloudshell=false&orgonly=true&folder=&supportedpurview=project
    2. Add record in aditazz-com zone at
        https://console.cloud.google.com/net-services/dns/zones?authuser=1&organizationId=594755159168&project=aditazz-production
        

#### 3. Docker Swarm Deployment - Traefik and Mercury 
- Traefik (HTTP reverse proxy and load balancer) is used for reverse proxying the application and automating the SSL renewal
- SSH/SCP command is made up of the following template
    ``` gcloud beta compute ssh --zone <zone> <instance-name> --project <project-id> ```

- Pre Requisite
    - Variables to be configured in **.env** file
        - PROJECT_ID [Same as in terraform/main.tf - provider block]
        - INSTANCE_NAME [Same as in terraform/terraform.tfvars - instance_name]
        - INSTANCE_ZONE [Same as in terraform/terraform.tfvars - location]
        - GCP_USER_ID [User id when you ssh into a VM]- we will doing everything in deployment user
            - Run the following commands to ssh into into VM with  user deployment.
            ```
            export $(cat .env)
            gcloud beta compute ssh --zone $INSTANCE_ZONE --project $PROJECT_ID deployment@$INSTANCE_NAME
            ```
            
    - Run the following command in shell to set the above variables
    ``` export $(cat .env)```
    
- Copy all the files in git folder inside VM
    ```
    1. cd mercury/
    2. gcloud beta compute scp --recurse --zone $INSTANCE_ZONE --project $PROJECT_ID ./mercury deployment@$INSTANCE_NAME:~/git
    ```
- Deploy the compose files as docker swarm services
    ```
    # SSH into VM as a deployment user
    1. gcloud beta compute ssh --zone $INSTANCE_ZONE --project $PROJECT_ID deployment@$INSTANCE_NAME
    ```
    ```
    # Docker login
    2. sudo docker login -u <username> -p <password> ----------- credentials of deployment user
    ```
    ```
    # Deploy all services
    # docker stack deploy -c <compose-file-name> <stack-name>
    # STACK_NAME, HOSTNAME, IMAGE_TAG, ENDPOINT configurable through .env file in each subdirectory 
    
    3. sudo docker stack deploy -c traefik.yml traefik
    4. cd mercury-business
    5. bash deploy.sh
    4. cd ../mercury-visualizer
    5. bash deploy.sh
    4. cd ../mercury-homepage
    5. bash deploy.sh
    ```

#### 4. Basic Continuous Deployment

- Pre Requisite
    - Variables to be configured in **.env** file
        - PROJECT_ID [Same as in terraform/main.tf - provider block]
        - INSTANCE_NAME [Same as in terraform/terraform.tfvars - instance_name]
        - INSTANCE_ZONE [Same as in terraform/terraform.tfvars - location]
        
    - Run the following command in shell to set the above variables
    ``` export $(cat .env)```

- Docker service name is as follows
    ``` <stack-name - From the stack deploy command>_<service-name (inside the yml files)> ```
- Docker service update command template
    ``` docker service update <service_name> --image <dockerhub-image:tag> --with-registry-auth  ```
- To update a service, use the following single line command (ssh + update)
    - mercury_mercury-visualizer 
        ```
        gcloud beta compute ssh --zone $INSTANCE_ZONE $INSTANCE_NAME --project $PROJECT_ID -- "sudo docker service update mercury-visualizer_mercury-visualizer --image aditazz/mercury-visualizer:development --with-registry-auth"
        ```
    - mercury-business_mercury-business
        ```
        gcloud beta compute ssh --zone $INSTANCE_ZONE $INSTANCE_NAME --project $PROJECT_ID -- "sudo docker service update mercury-business_mercury-business --image aditazz/mercury-business:development --with-registry-auth"
        ```
    - mercury-homepage_mercury-homepage
        ```
        gcloud beta compute ssh --zone $INSTANCE_ZONE $INSTANCE_NAME --project $PROJECT_ID -- "sudo docker service update mercury-homepage_mercury-homepage --image aditazz/mercury-landing:latest --with-registry-auth"
        ```

#### 5. Cron Jobs
- Pre Requisite
    - Docker login (This saves the credentials)
- Pulling latest docker images
    - SSH into VM
    - The following command is used to add deployment user in syslog group which is added in inline block of instance.tf file under modules(Required for cronjob to write logs in /var/log/) 
    [Sample command for user : deployment]
        - ```sudo usermod -aG syslog deployment ``` - This command is already added in inline block of instance.tf file under modules(terraform)
    - Transfer / Copy the contents of file cronjobs/dockerpull.sh inside the VM
    - Edit Crontab
        - Run the following command to edit crontab    
            - ``` crontab -e``` 
        - Append the following line to schedule a cronjob for every 5 mins and save the script output in a file
            - ``` */5 * * * * (/bin/date && bash /home/deployment/git/mercury/crontab/dockerpull.sh) >> /var/log/crontab.log 2>&1 ```
            - /bin/date adds the date-time in the log
            - Change shell script and log file location as needed in the above command
