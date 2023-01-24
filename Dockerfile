FROM registry.gitlab.com/gitlab-org/terraform-images/stable:latest

# install dependencies
RUN \
apk update && \
apk add openssh-client

# install ansible
RUN \
apk add py3-pip && \
pip3 install --upgrade pip && \
python3 -m pip install --user ansible && \
export PATH="$PATH:/root/.local/bin"
ENV PATH="$PATH:/root/.local/bin"

# verify install
RUN \
gitlab-terraform -version && \
ansible --version && \
ansible-playbook --version
