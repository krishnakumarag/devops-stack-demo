FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y \
    ansible \
    openssh-client \
    openssh-server \
    sshpass && \
    apt-get clean

# Setup SSH server
RUN mkdir /var/run/sshd && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

EXPOSE 22

# Start SSH server
CMD ["/usr/sbin/sshd", "-D"]