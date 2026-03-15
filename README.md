# Ansible Setup Guide

## Overview

Three containers work together:
```
Jenkins → (SSH) → Ansible Controller → (SSH) → App Server
```

- **Jenkins** builds and tests the code
- **Ansible Controller** runs playbooks
- **App Server** plain Ubuntu where the app is deployed

---

## Prerequisites

All three containers must be running and on the same network before starting this guide.

---

## Step 1 — Build and Start App Server
```cmd
docker build -t app-server ./app
docker run -d --name app-server -p 8081:8082 app-server:latest
```

Connect to jenkins network:
```cmd
docker network connect jenkins_default app-server
```

Get IP:
```cmd
docker exec app-server bash -c "hostname -i"
```
Note it down → example: `172.18.0.4`

---

## Step 2 — Build and Start Ansible Controller
```cmd
docker build -t ansible-controller ./ansible
docker run -d --name ansible-controller -v C:\YOUR_PATH\devops-stack-demo\ansible:/ansible ansible-controller:latest
```

Connect to jenkins network:
```cmd
docker network connect jenkins_default ansible-controller
```

Get IP:
```cmd
docker exec ansible-controller bash -c "hostname -i"
```
Note it down → example: `172.18.0.3`

---

## Step 3 — Generate SSH Key on Ansible Controller

This key is used by Ansible Controller to SSH into App Server.
```cmd
docker exec ansible-controller bash -c "ssh-keygen -t ed25519 -C 'ansible' -f /root/.ssh/ansible-key -N ''"
```

Get the public key:
```cmd
docker exec ansible-controller bash -c "cat /root/.ssh/ansible-key.pub"
```
Copy the output.

---

## Step 4 — Add Ansible Public Key to App Server
```cmd
docker exec app-server bash -c "echo 'PASTE_PUBLIC_KEY_HERE' >> /home/devops/.ssh/authorized_keys && chmod 600 /home/devops/.ssh/authorized_keys"
```

Test connection from Ansible Controller to App Server:
```cmd
docker exec ansible-controller bash -c "ssh -i /root/.ssh/ansible-key -o StrictHostKeyChecking=no devops@APP_SERVER_IP 'echo Ansible to App-Server works!'"
```

Expected output:
```
Ansible to App-Server works!
```

---

## Step 5 — Test Ansible Ping
```cmd
docker exec ansible-controller bash -c "ansible -i /ansible/hosts.ini appservers -m ping"
```

Expected output:
```
APP_SERVER_IP | SUCCESS => {
    "ping": "pong"
}
```

---

## Step 6 — Update hosts.ini with App Server IP

Open `ansible/hosts.ini` and update the IP:
```ini
[appservers]
172.18.0.4 ansible_user=devops ansible_ssh_private_key_file=/root/.ssh/ansible-key ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

---

## Step 7 — Generate SSH Key on Jenkins

This key is used by Jenkins to SSH into Ansible Controller.

Go inside Jenkins container:
```cmd
docker exec -it jenkins bash
```

Inside Jenkins:
```bash
ssh-keygen -t ed25519 -C "jenkins" -f /var/jenkins_home/.ssh/ansible-controller-key -N ""
cat /var/jenkins_home/.ssh/ansible-controller-key.pub
exit
```

Copy the public key output.

---

## Step 8 — Add Jenkins Public Key to Ansible Controller
```cmd
docker exec ansible-controller bash -c "echo 'PASTE_PUBLIC_KEY_HERE' >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys"
```

Fix permissions on Ansible Controller SSH keys:
```cmd
docker exec ansible-controller bash -c "chmod 700 /root/.ssh && chmod 600 /root/.ssh/ansible-key && chmod 644 /root/.ssh/ansible-key.pub"
```

Test connection from Jenkins to Ansible Controller:
```cmd
docker exec jenkins bash -c "ssh -i /var/jenkins_home/.ssh/ansible-controller-key -o StrictHostKeyChecking=no root@ANSIBLE_CONTROLLER_IP 'echo Jenkins to Ansible-Controller works!'"
```

Expected output:
```
Jenkins to Ansible-Controller works!
```

---

## Step 9 — Add Jenkins Private Key as Credential in Jenkins UI

Get the private key:
```cmd
docker exec jenkins bash -c "cat /var/jenkins_home/.ssh/ansible-controller-key"
```

Add it in Jenkins UI:
```
Dashboard → Manage Jenkins → Credentials
→ System → Global credentials → Add Credentials
→ Kind: SSH Username with private key
→ ID: ansible-controller-ssh
→ Description: Ansible Controller SSH Key
→ Username: root
→ Private Key: Enter directly → paste private key
→ Save
```

---

## Step 10 — Update Jenkinsfile with IPs

Open `jenkins/Jenkinsfile` and update:
```groovy
environment {
    ANSIBLE_CONTROLLER_IP = '172.18.0.3'
    ANSIBLE_USER          = 'root'
}
```

Commit and push:
```cmd
git add jenkins/Jenkinsfile
git commit -m "update ansible controller IP"
git push
```

---

## Step 11 — Run Provision Playbook Manually (First Time Only)

Run this once to install Java and curl on the App Server:
```cmd
docker exec ansible-controller bash -c "ansible-playbook -i /ansible/hosts.ini /ansible/provision.yml"
```

Verify Java is installed on App Server:
```cmd
docker exec app-server bash -c "java -version"
```

Expected output:
```
openjdk version "21.x.x"
```

---

## Step 12 — Run the Pipeline
```
Dashboard → demo-app-pipeline → Build with Parameters → Build
```

Expected stage results:
```
Build     ✅ → Maven builds JAR
Test      ✅ → 10 unit tests pass
Provision ✅ → Ansible installs Java and curl on app-server
Deploy    ✅ → Ansible copies JAR and starts app
```

Open `http://localhost:8081` — app is live!

---

## Important — IP Addresses Change on Container Restart

Every time you stop and remove a container its IP changes. After recreating any container:
```cmd
REM Get all container IPs at once
docker inspect jenkins --format "{{json .NetworkSettings.Networks.jenkins_default.IPAddress}}"
docker inspect ansible-controller --format "{{json .NetworkSettings.Networks.jenkins_default.IPAddress}}"
docker inspect app-server --format "{{json .NetworkSettings.Networks.jenkins_default.IPAddress}}"
```

Update these files with new IPs:
- `ansible/hosts.ini` → app-server IP
- `jenkins/Jenkinsfile` → ansible-controller IP

---

## Useful Commands
```cmd
REM Check all running containers
docker ps

REM View logs
docker logs ansible-controller
docker logs app-server

REM Go inside any container
docker exec -it ansible-controller bash
docker exec -it app-server bash

REM Stop all containers
docker stop jenkins ansible-controller app-server

REM Start all containers
docker start jenkins ansible-controller app-server
```

---

## Troubleshooting

**SSH asking for password**
```cmd
REM Fix permissions on ansible-controller
docker exec ansible-controller bash -c "chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys && chmod 600 /root/.ssh/ansible-key"

REM Enable root login
docker exec ansible-controller bash -c "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && service ssh restart"
```

**Ansible ping fails**
```cmd
REM Check app-server authorized_keys
docker exec app-server bash -c "cat /home/devops/.ssh/authorized_keys"

REM Check ansible-controller can reach app-server
docker exec ansible-controller bash -c "ssh -i /root/.ssh/ansible-key -o StrictHostKeyChecking=no devops@APP_SERVER_IP 'echo works'"
```

**Container IP changed after restart**
```cmd
REM Get new IPs and update hosts.ini and Jenkinsfile
docker inspect ansible-controller --format "{{json .NetworkSettings.Networks.jenkins_default.IPAddress}}"
docker inspect app-server --format "{{json .NetworkSettings.Networks.jenkins_default.IPAddress}}"
```