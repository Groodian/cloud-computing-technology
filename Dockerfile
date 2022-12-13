FROM ubuntu:latest

# install dependencies
RUN \
apt-get update -y && \
apt-get install -y wget gpg gnupg software-properties-common jq openssh-client

# install terraform
RUN \
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
apt-get update -y && \
apt-get install -y terraform

# install ansible
RUN \
apt-get install -y python3-pip && \
pip3 install --upgrade pip && \
python3 -m pip install --user ansible
ENV PATH="$PATH:/root/.local/bin"

# verify install
RUN \
terraform -version && \
ansible --version && \
ansible-playbook --version
