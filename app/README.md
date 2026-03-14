# devops-stack-demo — Java App Setup (Windows)

## Prerequisites

Install these on your Windows machine before starting:

| Tool | Download |
|------|----------|
| JDK 17 | https://adoptium.net/ |
| Maven 3.9+ | https://maven.apache.org/download.cgi |
| Docker Desktop | https://www.docker.com/products/docker-desktop/ |
| Git | https://git-scm.com/download/win |

---

## Option A: Run with Maven directly (no Docker)

```cmd
cd app
mvn clean package
mvn spring-boot:run
```

App runs at: http://localhost:8080

---

## Option B: Run with Docker (recommended for seminar)

```cmd
cd app

REM Step 1 - Build the Docker image
docker build -t java-app:v1 .

REM Step 2 - Run the container
docker run -d -p 8080:8080 --name my-app java-app:v1

REM Step 3 - Check it is running
docker ps
```

App runs at: http://localhost:8080

---

## Test the endpoints

Open browser or use curl:

```cmd
curl http://localhost:8080/
curl http://localhost:8080/info
curl http://localhost:8080/actuator/health
```

Expected responses:
- `/`            → `{"message":"Hello from DevOps Stack Demo!","version":"v1.0","status":"running"}`
- `/info`        → `{"app":"devops-stack-demo","stack":"Java + Docker + Jenkins + Ansible + Azure",...}`
- `/actuator/health` → `{"status":"UP",...}`

---

## Run tests

```cmd
cd app
mvn test
```

---

## Useful Docker commands

```cmd
REM Stop the container
docker stop my-app

REM Remove the container
docker rm my-app

REM View logs
docker logs my-app

REM Rebuild after code change
docker build -t java-app:v2 .
docker stop my-app && docker rm my-app
docker run -d -p 8080:8080 --name my-app java-app:v2
```
