FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y \
    python3 \
    python3-pip \
    openssh-client \
    openssh-server \
    sshpass && \
    apt-get clean

# Install latest Ansible via pip instead of apt
RUN pip3 install --upgrade ansible

# Setup SSH server
RUN mkdir /var/run/sshd && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]