FROM ubuntu:22.04

# Install JDK 21 and SSH server
RUN apt-get update && \
    apt-get install -y openjdk-21-jdk openssh-server curl && \
    apt-get clean

# Setup SSH
RUN mkdir /var/run/sshd && \
    useradd -m -s /bin/bash devops && \
    echo 'devops:devops123' | chpasswd && \
    mkdir -p /home/devops/.ssh && \
    chmod 700 /home/devops/.ssh && \
    chown -R devops:devops /home/devops/.ssh

# Create app directory
RUN mkdir -p /app && \
    chown -R devops:devops /app

EXPOSE 22
EXPOSE 8082

# Start SSH server
CMD ["/usr/sbin/sshd", "-D"]