FROM rockylinux:9
RUN dnf install -y git ansible-core
RUN ansible-galaxy collection install brightcomputing.installer100
RUN mkdir -p /ansible/group_vars
WORKDIR /ansible
RUN cat >group_vars/all <<EOF
product_key: $CMKEY
install_medium: network
EOF
RUN cat >/etc/yum.repos.d/cm.repo <<EOF
[cm-rhel9-10.0-updates]
name=Cluster Manager 10.0 for Red Hat Enterprise Linux 9 - Updates
# baseurl=http://updates.brightcomputing.com/yum/cm/10.0/$basearch/rhel/9/updates/
mirrorlist=http://updates.brightcomputing.com/yum/cm/10.0/$basearch/rhel/9/updates/mirrorlist
username=cm100user
password=$CMPASS
enabled=1
priority=11
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-cm
exclude = parted
EOF
