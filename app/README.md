# devops-stack-demo — Java App Setup (Windows)

## Prerequisites

Install these on your Windows machine before starting:

| Tool | Download |
|------|----------|
| JDK 21 | https://www.oracle.com/java/technologies/javase/jdk21-archive-downloads.html |
| apache-maven-3.9.14-bin.zip | https://maven.apache.org/download.cgi |
| Docker Desktop | https://www.docker.com/products/docker-desktop/ |
| Git | https://git-scm.com/download/win |

---

## Option A: Run with Maven directly (no Docker)
```cmd
cd app
mvn clean package
mvn spring-boot:run
```

App runs at: http://localhost:8082

---

## Option B: Manual deployment inside Docker (seminar demo)

This simulates deploying to a fresh Linux server — nothing is pre-installed.

**Step 1 — Build and enter the container**
```cmd
cd app
docker build -t my-server-img .
docker run -it --name my-server -p 8081:8082 my-server-img
```

You are now inside a bare Ubuntu machine. Port `8082` inside the container maps to `8081` on your Windows machine.

**Step 2 — Inside the container, install everything manually**
```bash
# Prove nothing is installed
java -version       # command not found
git --version       # command not found
mvn -version        # command not found

# Update package list
apt update -y

# Install Git
apt install -y git

# Install Java 21
apt-cache search openjdk-21
apt install -y openjdk-21-jdk
java -version

# Install Maven
apt install -y maven
mvn -version

#Install curl
apt install -y curl
curl -version
```

**Step 3 — Clone the repo and build**
```bash
git clone https://github.com/krishnakumarag/devops-stack-demo.git
cd devops-stack-demo/app
mvn clean package -DskipTests
```

**Step 4 — Update the port and run in background**
```bash
# App is configured for 8080 by default, change it to 8082
export SERVER_PORT=8082

# Run in background
nohup mvn spring-boot:run > app.log 2>&1 &

# Wait for startup
sleep 15

# Confirm it is up (inside container)
curl http://localhost:8082/actuator/health
```

**Step 5 — Test from Windows browser**

Open `http://localhost:8081` — traffic comes in on 8081 (Windows) and hits 8082 (container).

**Step 6 — Watch logs live**
```bash
tail -f app.log
```

---

## Port mapping explained

| Where | Port | URL |
|---|---|---|
| Your Windows machine | 8081 | http://localhost:8081 |
| Inside the container | 8082 | http://localhost:8082 |

`-p 8081:8082` means → forward Windows port 8081 to container port 8082.

---

## Useful Docker commands (run from Windows cmd)
```cmd
REM Stop the container
docker stop my-server

REM Remove the container
docker rm my-server

REM Re-enter a running container
docker exec -it my-server bash

REM View container logs from outside
docker logs my-server
```