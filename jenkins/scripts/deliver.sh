#!/usr/bin/env bash

echo 'The following Maven command installs your Maven-built Java application'
echo 'into the local Maven repository, which will ultimately be stored in'
echo 'Jenkins''s local Maven repository (and the "maven-repository" Docker data'
echo 'volume).'
set -x
mvn -f app/pom.xml jar:jar install:install help:evaluate -Dexpression=project.artifactId
set +x

echo 'The following command extracts the value of the <name/> element'
echo 'within <project/> of your Java/Maven project''s "pom.xml" file.'
set -x
NAME=`mvn -f app/pom.xml -q -DforceStdout help:evaluate -Dexpression=project.artifactId`
set +x

echo 'The following command behaves similarly to the previous one but'
echo 'extracts the value of the <version/> element within <project/> instead.'
set -x
VERSION=`mvn -f app/pom.xml -q -DforceStdout help:evaluate -Dexpression=project.version`
set +x

echo 'The following command runs and outputs the execution of your Java'
echo 'application (which Jenkins built using Maven) to the Jenkins UI.'
set -x
JAR=app/target/${NAME}-${VERSION}.jar

# Kill existing app if running
kill $(cat /tmp/app.pid) 2>/dev/null || true
sleep 2

# Run in background
nohup java -jar $JAR --server.port=8082 > /tmp/app.log 2>&1 &
echo $! > /tmp/app.pid

# Wait and confirm
sleep 15
curl http://localhost:8082/actuator/health
