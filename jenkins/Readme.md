# Jenkins Setup Guide

## Prerequisites

Docker and Docker Compose must be installed on your Windows machine.

---

## Start Jenkins
```cmd
cd jenkins
docker compose up -d
```

Wait 30 seconds then check if Jenkins is running:
```cmd
docker logs jenkins
```

Wait until you see:
```
Jenkins is fully up and running
```

Open Jenkins UI at `http://localhost:8080`

---

## Initial Setup

**Step 1 — Unlock Jenkins**

Get the initial admin password:
```cmd
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Paste it in the browser and click **Continue**.

**Step 2 — Skip plugin installation**

- Click **"Select plugins to install"**
- Click **"None"** at the top to deselect everything
- Click **"Install"**

**Step 3 — Create admin user**

Fill in your username and password and click **"Save and Finish"**.

---

## Install Required Plugins
```
Dashboard → Manage Jenkins → Plugins → Available plugins
```

Search and install these one by one:

| Plugin | Purpose |
|--------|---------|
| Git | Clone repositories from GitHub |
| Maven Integration | Run Maven build commands |
| Pipeline | Enable Jenkinsfile-based pipelines |
| Git Parameter | Choose branch when triggering builds |
| JUnit | Display test results in Jenkins UI |

No restart needed after installing.

---

## Configure Maven
```
Dashboard → Manage Jenkins → Tools
→ Scroll to "Maven installations"
→ Click "Add Maven"
→ Name: Maven-3.9
→ Tick "Install automatically"
→ Pick version 3.9.9
→ Save
```

---

## Generate SSH Key for GitHub

Jenkins needs an SSH key to clone your private GitHub repository.

**Step 1 — Generate the key inside Jenkins container**
```cmd
docker exec -it jenkins bash
```

Inside the container:
```bash
ssh-keygen -t ed25519 -C "jenkins@devops-demo"
```

When prompted:
```
Enter file in which to save the key: /var/jenkins_home/.ssh/id_ed25519
Enter passphrase: (leave empty, just press Enter)
Enter same passphrase again: (press Enter again)
```

**Step 2 — Copy the public key**
```bash
cat /var/jenkins_home/.ssh/id_ed25519.pub
```

Copy the entire output — it starts with `ssh-ed25519`.

Exit the container:
```bash
exit
```

---

## Add SSH Key to GitHub

**Step 1 — Go to GitHub SSH settings**
```
GitHub → Settings → SSH and GPG keys → New SSH key
```

**Step 2 — Add the key**
```
Title: jenkins-devops-demo
Key type: Authentication Key
Key: (paste the public key you copied above)
```

Click **Add SSH key**.

**Step 3 — Verify connection from inside Jenkins container**
```cmd
docker exec -it jenkins bash
```
```bash
ssh -T git@github.com
```

You should see:
```
Hi YOUR_USERNAME! You've successfully authenticated, but GitHub does not provide shell access.
```

Exit the container:
```bash
exit
```

---

## Add SSH Credentials in Jenkins
```
Dashboard → Manage Jenkins → Credentials
→ System → Global credentials → Add Credentials
```

Fill in:
```
Kind: SSH Username with private key
Scope: Global
ID: github-ssh-key
Description: GitHub SSH Key
Username: git
Private Key: Enter directly → Add
```

Paste the private key:
```cmd
docker exec jenkins cat /var/jenkins_home/.ssh/id_ed25519
```

Copy the entire output including the `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----` lines and paste it in the key field.

Click **Create**.

---

## Configure Host Key Verification

This allows Jenkins to connect to GitHub without manual host key approval.
```
Dashboard → Manage Jenkins → Security
→ Scroll to "Git Host Key Verification Configuration"
→ Host Key Verification Strategy: Accept first connection
→ Save
```

---

## Create a Pipeline Job

**Step 1 — New Item**
```
Dashboard → New Item
→ Name: devops-stack-demo-pipeline
→ Select: Pipeline
→ Click: OK
```

**Step 2 — Configure parameters**
```
→ Tick "This project is parameterized"
→ Add Parameter → Git Parameter
→ Name: BRANCH
→ Parameter Type: Branch
→ Default Value: origin/main
```

**Step 3 — Configure Pipeline source**

Scroll down to the Pipeline section:
```
Definition: Pipeline script from SCM
SCM: Git
Repository URL: git@github.com:YOUR_USERNAME/devops-stack-demo.git
Credentials: github-ssh-key
Branch Specifier: ${BRANCH}
Script Path: jenkins/Jenkinsfile
```

Click **Save**.

---

## Run the Pipeline
```
Dashboard → devops-stack-demo-pipeline
→ Build with Parameters
→ Select branch from dropdown
→ Click Build
```

Watch the build progress:
```
Dashboard → devops-stack-demo-pipeline → #1 → Console Output
```

A successful build ends with:
```
Pipeline completed successfully!
Finished: SUCCESS
```

---

## Useful Docker Commands
```cmd
REM Stop Jenkins
docker compose down

REM Start Jenkins (keeps existing data)
docker compose up -d

REM Restart Jenkins
docker restart jenkins

REM View live logs
docker logs -f jenkins

REM Wipe Jenkins completely and start fresh
docker compose down -v
docker compose up -d
```