FROM rockylinux/rockylinux:9-ubi-init
ARG CMKEY
ARG CMPASS
RUN dnf install -y git ansible-core mariadb-server
RUN ansible-galaxy collection install brightcomputing.installer100 community.general community.mysql community.crypto ansible.posix
RUN mkdir -p /ansible/group_vars
WORKDIR /ansible
RUN echo -e "product_key: $CMKEY\ninstall_medium: network" >group_vars/all
RUN echo -e "[cm-rhel9-10.0-updates]\nname=Cluster Manager 10.0 for Red Hat Enterprise Linux 9 - Updates\n# baseurl=http://updates.brightcomputing.com/yum/cm/10.0/$basearch/rhel/9/updates/\nmirrorlist=http://updates.brightcomputing.com/yum/cm/10.0/$basearch/rhel/9/updates/mirrorlist\nusername=cm100user\npassword=$CMPASS\nenabled=1\npriority=11\ngpgcheck=1\ngpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-cm\nexclude = parted" >/etc/yum.repos.d/cm.repo
RUN echo -e "---\n- name: Install BCM admin node\n  hosts: all,localhost\n  gather_facts: true\n  pre_tasks:\n    - service_facts\n  roles:\n    - role: brightcomputing.installer100.head_node" >site.yml
CMD ansible-playbook -i $(hostname), -c local site.yml
