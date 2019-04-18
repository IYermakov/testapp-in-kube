FROM jenkins/jenkins:lts

EXPOSE 8080 50000

USER root

#ENV DOCKER_VERSION=docker-ce_18.06.3~ce~3-0~ubuntu_amd64.deb
ENV KUBERNETES_VERSION=v1.12.7

# Install prerequisites for Docker
#RUN apt-get update && apt-get install -y sudo maven iptables libsystemd-journal0 init-system-helpers libapparmor1 libltdl7 libseccomp2 libdevmapper1.02.1 && rm -rf /var/lib/apt/lists/*
#RUN apt-get update && apt-get install -y sudo maven sysv-rc file-rc libsystemd-journal0 iptables init-system-helpers libapparmor1 libltdl7 libseccomp2 libdevmapper1.02.1 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN apt-get update && apt-get install -y apt-utils software-properties-common
RUN echo /etc/lsb-release
RUN echo /etc/os-release
#RUN grep VERSION_CODENAME /etc/os-release | cut -d'=' -f2
RUN add-apt-repository "deb https://download.docker.com/linux/ubuntu $(grep VERSION_CODENAME /etc/os-release | cut -d'=' -f2) stable"
RUN apt-get update && apt-get install -y sudo maven docker-ce
RUN usermod -aG docker jenkins
RUN systemctl enable docker
RUN service docker start

# Set up Docker
#RUN wget https://download.docker.com/linux/ubuntu/dists/trusty/pool/stable/amd64/$DOCKER_VERSION
#RUN mv $DOCKER_VERSION /var/cache/apt/archives/
#RUN apt-get install -y $( echo $DOCKER_VERSION | sed s/.deb// )
#RUN dpkg -i $DOCKER_VERSION

# Set up Kubernetes
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBERNETES_VERSION/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

#COPY plugins.txt /usr/share/jenkins/plugins.txt
#RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/plugins.txt

ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]