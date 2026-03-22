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

Click **"x"** at the top right to skip and proceed without any plugins.

**Step 3 — Create admin user**

Fill in your username and password and click **Save and Finish**.

---

## Understanding What We Are Building

Before installing anything — try creating a Freestyle job first to feel the pain of missing plugins:
```
Dashboard → New Item → enter a name → Freestyle project → OK
```

Now look around:

- Click **Source Code Management** — Git option is missing → need Git plugin
- Click **Add build step** → **Invoke top-level Maven targets** — Maven version dropdown is empty → need to configure Maven tool
- Click **Add post-build action** — no JUnit option → need JUnit plugin

This is why we install plugins one by one — so you understand what each one adds.

---

## Install Required Plugins
```
Dashboard → Manage Jenkins → Plugins → Available plugins
```

Search and install these one by one:

| Plugin | Purpose |
|--------|---------|
| Git | Clone repositories from GitHub |
| JUnit | Display test results in Jenkins UI |
| Publish Over SSH | Copy files to remote server and run commands via SSH |
| SSH Agent | Use SSH credentials inside Pipeline scripts |

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

## Configure Global Shell
```
Dashboard → Manage Jenkins → System
→ Scroll to "Shell"
→ Shell executable: /bin/bash
→ Save
```
---

## Create Freestyle Job — Build and Test

**Step 1 — New Item**
```
Dashboard → New Item
→ Name: devops-freestyle-demo
→ Select: Freestyle project
→ OK
```

**Step 2 — Source Code Management**
```
→ Select: Git
→ Repository URL: git@github.com:YOUR_USERNAME/devops-stack-demo.git
→ Credentials: select github-ssh-key
→ Branch Specifier: */main
```

**Step 3 — Build Steps**

Click **Add build step** → **Invoke top-level Maven targets**:
```
Maven Version: Maven-3.9
Goals: -f app/pom.xml -DskipTests clean package
```

Click **Add build step** again → **Invoke top-level Maven targets**:
```
Maven Version: Maven-3.9
Goals: -f app/pom.xml test
```

**Step 4 — Post Build Actions**
```
→ Add post-build action → Publish JUnit test result report
→ Test report XMLs: app/target/surefire-reports/*.xml
→ Save
```

**Step 5 — Build**
```
Dashboard → devops-freestyle-demo → Build Now
```

Click the build number → Console Output to watch logs. A successful build ends with:
```
BUILD SUCCESS
Finished: SUCCESS
```

---

## Start App Server
```
cd server
docker stop app-server
docker rm app-server
docker build -t app-server .
docker run -d --name app-server -p 8081:8082 app-server
```

## Setup SSH Key for App Server

**Step 1 — Generate key inside Jenkins container**
```cmd
docker exec jenkins ssh-keygen -t ed25519 -C "jenkins" -f /var/jenkins_home/.ssh/app-server-key -N ""
```

**Step 2 — Get the public key**
```cmd
docker exec jenkins cat /var/jenkins_home/.ssh/app-server-key.pub
```

Copy the output.

**Step 3 — Add public key to app-server**
```cmd
docker exec -u devops app-server bash -c "echo 'PASTE_PUBLIC_KEY_HERE' > /home/devops/.ssh/authorized_keys && chmod 600 /home/devops/.ssh/authorized_keys"
```

Use `>` not `>>` to avoid ownership issues.

**Step 4 — Test SSH connection**
```cmd
docker exec jenkins ssh -i /var/jenkins_home/.ssh/app-server-key -o StrictHostKeyChecking=no devops@APP_SERVER_IP echo SSH works!
```

Should print:
```
SSH works!
```

---

## Configure Publish Over SSH Plugin
```
Dashboard → Manage Jenkins → System
→ Scroll to "Publish over SSH"
→ Click "Add"
→ Name: app-server
→ Hostname: APP_SERVER_IP
→ Username: devops
→ Path to key: /var/jenkins_home/.ssh/app-server-key
→ Click "Test Configuration" → should say: Success
→ Save
```

---

## Update Freestyle Job — Add Deployment

**Step 1 — Open job configuration**
```
Dashboard → devops-freestyle-demo → Configure
```

**Step 2 — Add post-build action**
```
→ Add post-build action → Send build artifacts over SSH
→ SSH Server Name: app-server
```

Fill in the Transfer Set:
```
Source files:     app/target/demo-0.0.1-SNAPSHOT.jar
Remove prefix:    app/target
Remote directory: /app
```

Exec command:
```bash
kill $(cat /tmp/app.pid) 2>/dev/null || true
sleep 2
nohup java -jar /home/devops/app/demo-0.0.1-SNAPSHOT.jar --server.port=8082 > /tmp/app.log 2>&1 &
echo $! > /tmp/app.pid
```

Click **Save**.

**Note — why `/home/devops/app` and not `/app`:**

Publish Over SSH always uses the SSH user's home directory as root. So `Remote directory: /app` copies to `/home/devops/app/` on the server. The exec command path must match this.

**Step 3 — Build**
```
Dashboard → devops-freestyle-demo → Build Now
```

**Step 4 — Verify app is running**
```cmd
docker exec app-server bash -c "cat /tmp/app.log"
```

You should see:
```
Tomcat started on port 8082
Started DemoApplication
```

Open browser at `http://localhost:8081` — app is live.

---

## Useful Commands
```cmd
REM Stop Jenkins
docker compose down

REM Start Jenkins (keeps all data)
docker compose up -d

REM Restart Jenkins
docker restart jenkins

REM View live logs
docker logs -f jenkins

REM Wipe Jenkins and start fresh
docker compose down -v
docker compose up -d --build
```

---

## Troubleshooting

**SSH connection fails — permission denied**
```cmd
REM Check authorized_keys ownership — must be owned by devops not root
docker exec app-server bash -c "ls -la /home/devops/.ssh/"

REM Fix ownership if wrong
docker exec app-server bash -c "chown devops:devops /home/devops/.ssh/authorized_keys && chmod 600 /home/devops/.ssh/authorized_keys"
```

**JAR not found on server**
```cmd
REM Find where the JAR actually landed
docker exec app-server bash -c "find / -name '*.jar' 2>/dev/null"
```

**App not starting**
```cmd
REM Check app logs
docker exec app-server bash -c "cat /tmp/app.log"

REM Check if Java is installed
docker exec app-server bash -c "java -version"
```

**Maven not found in Jenkins**
```
Manage Jenkins → Tools → Maven installations
→ Verify Maven-3.9 is configured with Install automatically ticked
```

**IP address changed after container restart**
```cmd
docker inspect app-server --format "{{json .NetworkSettings.Networks.jenkins_default.IPAddress}}"
```

Update the new IP in:
- Publish Over SSH server configuration
- Exec command paths if hardcoded