FROM rockylinux/rockylinux:8-ubi-init AS bcm-head-base
ARG CMKEY
ARG CMPASS

# Note below that the default python3-xmltodict is not usable by Ansible
RUN dnf install -y git ansible-core mariadb-server https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
RUN AnsVer=$(ansible --version | gawk '/python.version/{print $4}' | cut -d . -f 1-2); dnf install -y python$AnsVer-{xmltodict,jmespath,netaddr}
RUN systemctl enable mariadb
RUN ansible-galaxy collection install brightcomputing.installer100 community.general community.mysql community.crypto ansible.posix ansible.netcommon
RUN mkdir -p /ansible/group_vars
WORKDIR /ansible

#RUN echo excludepkgs=shorewall >>/etc/dnf/dnf.conf
RUN echo -e "product_key: $CMKEY\n\
install_medium: network\n\
install_medium_network_packages:\n\
  - /etc/yum.repos.d/cm.repo\n\
license:\n\
  country: US\n\
  state: Wisconsin\n\
  locality: Mount Pleasant\n\
  organization: RedLine Performance Solutions\n\
  organizational_unit: NACS\n\
  cluster_name: BCM install test container\n\
  mac: '{{ansible_default_ipv4.macaddress}}'\n\
exclude_bright_packages: [shorewall]\n\
db_cmd_password: secret" >group_vars/all

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

# NOTE: Stages from here on out are loosely named after BCM's Ansible tag names
# If you want to stop at a specific stage, use `buildah --target`

# Canonical order, not counting always, is assert_configuration, assert_system, setup_repos, prepare,
#  install, license, configure, start, post_install, clean_up, and validate.
# However, assert_configuration happens to invoke systemd so it can't run during the build.
# Moving it around a bit to see if it can safely be run later.

FROM bcm-head-base AS bcm-head-assert-configuration
RUN ansible-playbook -i $(hostname), -c local --tags assert_configuration --skip-tags assert_system site.yml

# Skip step for testing
# FROM bcm-head-assert-configuration AS bcm-head-assert-system
# RUN ansible-playbook -i $(hostname), -c local --tags assert_system site.yml

#FROM bcm-head-assert-system AS bcm-head-packages
FROM bcm-head-assert-configuration AS bcm-head-setup-repos
RUN ansible-playbook -i $(hostname), -c local --tags setup_repos --skip-tags assert_system site.yml

FROM bcm-head-setup-repos AS bcm-head-prepare
RUN ansible-playbook -i $(hostname), -c local --tags prepare --skip-tags assert_system site.yml

FROM bcm-head-prepare AS bcm-head-install
RUN ansible-playbook -i $(hostname), -c local --tags install --skip-tags assert_system site.yml

FROM bcm-head-install AS bcm-head-license
RUN ansible-playbook -i $(hostname), -c local --tags license --skip-tags assert_system site.yml

FROM bcm-head-license AS bcm-head-configure
RUN ansible-playbook -i $(hostname), -c local --tags configure --skip-tags assert_system site.yml

# Stop here for now; "start" task probably needs extra attention.
# After that comes post_install, clean_up, and validate.
