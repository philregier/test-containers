FROM rockylinux/rockylinux:8-ubi-init
ARG CMKEY
ARG CMPASS

# Note below that the default python3-xmltodict is not usable by Ansible
RUN dnf install -y git ansible-core mariadb-server https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
RUN AnsVer=$(ansible --version | gawk '/python.version/{print $4}' | cut -d . -f 1-2); dnf install -y python$AnsVer-{xmltodict,jmespath}
RUN systemctl enable mariadb
RUN ansible-galaxy collection install brightcomputing.installer100 community.general community.mysql community.crypto ansible.posix
RUN mkdir -p /ansible/group_vars
WORKDIR /ansible

RUN echo -e "product_key: $CMKEY\n\
install_medium: network\n\
install_medium_network_packages:\n\
  - /etc/yum.repos.d/cm.repo\n\
license:\n\
  cluster_name: BCM install test container" >group_vars/all

RUN echo -e "[cm-rhel8-10.0-updates]\n\
name=Cluster Manager 10.0 for Red Hat Enterprise Linux 8 - Updates\n\
# baseurl=http://updates.brightcomputing.com/yum/cm/10.0/\$basearch/rhel/8/updates/\n\
mirrorlist=http://updates.brightcomputing.com/yum/cm/10.0/\$basearch/rhel/8/updates/mirrorlist\n\
username=cm100user\n\
password=$CMPASS\n\
enabled=1\n\
priority=11\n\
gpgcheck=1\n\
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-cm\n\
exclude = parted" >/etc/yum.repos.d/cm.repo

RUN echo -e "---\n\
- name: Install BCM admin node\n\
  hosts: all,localhost\n  gather_facts: true\n\
  pre_tasks:\n\
    - service_facts:\n\
  roles:\n\
    - role: brightcomputing.installer100.head_node" >site.yml

RUN sed -i 's/no_log: true/no_log: false/' /root/.ansible/collections/ansible_collections/brightcomputing/installer100/roles/head_node/tasks/install/install_distribution_packages.yml
#CMD ansible-playbook -i $(hostname), -c local site.yml
