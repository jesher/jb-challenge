
FROM alpine:3

# install terraform version
ENV TERRAFORM_VERSION=0.14.4

# helmfile version
ARG HELMFILE_VERSION="v0.139.7"

RUN apk add --update --no-cache \
        curl=7.79.1-r0 \
        git=2.32.0-r0 \
        make=4.3-r0 \
        musl-dev=1.2.2-r3 \
        go=1.16.10-r0 \
        python3=3.9.5-r1 \
        py3-pip=20.3.4-r1 \
        jq=1.6-r1 \
    && pip3 install --no-cache-dir --upgrade pip==21.2.4 \
    && pip3 install --no-cache-dir \
        awscli==1.20.54 \
    && rm -rf /var/cache/apk/*

RUN curl -LOs https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator

RUN unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    chmod +x terraform && \
    mv terraform /usr/local/bin && \
    chmod +x aws-iam-authenticator && \
    mv aws-iam-authenticator /usr/local/bin

# kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin

# install helm3
RUN curl -LOs https://get.helm.sh/helm-v3.6.0-linux-amd64.tar.gz && \
    tar -zxvf helm-v3.6.0-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm

# install sops & helmfile
RUN curl -o /usr/local/bin/helmfile -L https://github.com/roboll/helmfile/releases/download/$HELMFILE_VERSION/helmfile_linux_386 && \
    chmod +x /usr/local/bin/helmfile

WORKDIR /usr/src
