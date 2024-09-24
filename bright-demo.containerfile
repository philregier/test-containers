FROM rockylinux:9
ARG CMKEY
ARG CMPASS
RUN dnf install -y git ansible-core
RUN ansible-galaxy collection install brightcomputing.installer100
RUN mkdir -p /ansible/group_vars
WORKDIR /ansible
RUN echo -e "product_key: $CMKEY\ninstall_medium: network" >group_vars/all
RUN echo -e "[cm-rhel9-10.0-updates]\nname=Cluster Manager 10.0 for Red Hat Enterprise Linux 9 - Updates\n# baseurl=http://updates.brightcomputing.com/yum/cm/10.0/$basearch/rhel/9/updates/\nmirrorlist=http://updates.brightcomputing.com/yum/cm/10.0/$basearch/rhel/9/updates/mirrorlist\nusername=cm100user\npassword=$CMPASS\nenabled=1\npriority=11\ngpgcheck=1\ngpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-cm\nexclude = parted" >/etc/yum.repos.d/cm.repo
