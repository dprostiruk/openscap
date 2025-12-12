FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SSG_VERSION=0.1.78
ENV GOSS_VERSION=0.4.9
ENV SSG_ROOT=/opt/ssg
ENV SSG_CONTENT=/opt/ssg/ssg-ubuntu2204-ds.xml

RUN apt update && apt install -y \
    sudo auditd openssh-server \
    python3 python3-pip \
    ruby-full curl git unzip wget jq \
    libopenscap8 xmlstarlet default-jre-headless \
    && rm -rf /var/lib/apt/lists/*

RUN gem install inspec --no-document \
    && pip3 install behave --no-cache-dir

RUN mkdir -p ${SSG_ROOT} && \
    wget -q https://github.com/ComplianceAsCode/content/releases/download/v${SSG_VERSION}/scap-security-guide-${SSG_VERSION}.zip \
        -O /tmp/ssg.zip && \
    unzip -q /tmp/ssg.zip -d ${SSG_ROOT}/tmp && \
    mv ${SSG_ROOT}/tmp/scap-security-guide-${SSG_VERSION}/* ${SSG_ROOT}/ && \
    rm -rf ${SSG_ROOT}/tmp /tmp/ssg.zip

RUN curl -fsSL https://github.com/goss-org/goss/releases/download/v${GOSS_VERSION}/goss-linux-amd64 \
        -o /usr/local/bin/goss \
    && chmod +x /usr/local/bin/goss \
    && curl -fsSL https://raw.githubusercontent.com/goss-org/goss/v${GOSS_VERSION}/extras/dgoss/dgoss \
        -o /usr/local/bin/dgoss \
    && chmod +x /usr/local/bin/dgoss

COPY goss.yaml /etc/goss/goss.yaml
COPY inspec-profile /inspec-profile
COPY run_checks.sh /usr/local/bin/run_checks.sh
COPY extract_stig_metrics.py /usr/local/bin/extract_stig_metrics.py

RUN chmod +x /usr/local/bin/run_checks.sh \
             /usr/local/bin/extract_stig_metrics.py

ENTRYPOINT ["/usr/local/bin/run_checks.sh"]
CMD []
