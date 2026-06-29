FROM ubuntu:22.04
LABEL Description="CORE 9.2.1 Docker Ubuntu Image"


ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM" > /log
ARG PREFIX=/usr/local
ARG BRANCH=release-9.2.1
ARG PROTOC_VERSION=3.19.6
ARG VENV_PATH=/opt/core/venv
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="$PATH:${VENV_PATH}/bin"
WORKDIR /opt

# install system dependencies
RUN apt-get update -y 
RUN apt-get install -y --no-install-recommends \
    bind9 \
    dnsutils \
    ca-certificates \
    git \
    sudo \
    wget \
    tzdata \
    libpcap-dev \
    libpcre3-dev \
    libprotobuf-dev \
    libxml2-dev \
    protobuf-compiler \
    unzip \
    uuid-dev \
    iproute2 \
    iputils-ping \
    tcpdump \
    ethtool \
    apache2 \
    vsftpd \
    ftp \
    net-tools \
    wireshark \
    iperf \
    iperf3 \
    links \
    openssh-client \
    openssh-server \
    isc-dhcp-client \
    isc-dhcp-server \
    netcat \
    vim \
    nano \
    arping \
    frr \
    atftpd \
    atftp \
    mini-httpd \
    iptables \
    nmap \
    telnet \
    traceroute \
    curl \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    openbox \
    xterm

RUN apt-get autoremove -y

# install core
RUN git clone https://github.com/coreemu/core && \
    cd core && \
    git checkout ${BRANCH} && \
    ./setup.sh && \
    PATH=/root/.local/bin:$PATH inv install -v -p ${PREFIX} && \
    cd /opt && \
    rm -rf ospf-mdr

# install emane
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        PROTOC_ARCH="aarch_64"; \
    elif [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        PROTOC_ARCH="x86_64"; \
    fi && \
    wget https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-${PROTOC_ARCH}.zip && \
    mkdir protoc && \
    unzip protoc-${PROTOC_VERSION}-linux-${PROTOC_ARCH}.zip -d protoc && \
    git clone https://github.com/adjacentlink/emane.git && \
    cd emane && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    make -j$(nproc)  && \
    make install && \
    cd src/python && \
    make clean && \
    PATH=/opt/protoc/bin:$PATH make && \
    ${VENV_PATH}/bin/python -m pip install . && \
    cd /opt && \
    rm -rf protoc && \
    rm -rf emane && \
    rm -f protoc-${PROTOC_VERSION}-linux-x86_64.zip

COPY ./start-up.sh /opt/core/
RUN chmod +x /opt/core/start-up.sh
RUN mkdir /var/run/sshd &&  sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config &&     sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config &&     sed -i 's/#X11UseLocalhost yes/X11UseLocalhost no/' /etc/ssh/sshd_config &&     sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd # buildkit
ENV ENABLE_SSH=0
ENV DISPLAY=:1
EXPOSE 22 50051 6080 5900
WORKDIR /root
ENTRYPOINT ["/opt/core/start-up.sh"]
