# Setup build arguments with default versions
ARG TERRAFORM_VERSION=0.12.21

# terraform image
FROM alpine:latest as terraform
ARG TERRAFORM_VERSION
COPY /terraform/hashicorp.asc hashicorp.asc
RUN set -ex \
&& apk --update add curl unzip gnupg \
&&  curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS \
&& curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
&& curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig \
&& gpg --import hashicorp.asc \
&& gpg --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS \
&& grep terraform_${TERRAFORM_VERSION}_linux_amd64.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS | sha256sum -c - \
&& unzip -j terraform_${TERRAFORM_VERSION}_linux_amd64.zip

#final image
FROM alpine:latest
ARG PYTHON_VERSION


# This hack is widely applied to avoid python printing issues in docker containers.
# See: https://github.com/Docker-Hub-frolvlad/docker-alpine-python3/pull/13
ENV PYTHONUNBUFFERED=1

RUN echo "**** install Python ****" && \
    apk add --no-cache python3 && \
    if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi && \
    \
    echo "**** install pip ****" && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --no-cache --upgrade pip setuptools wheel && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi

RUN apk update && apk add bash curl jq \
&& rm -rf /var/cache/apk/*
COPY --from=terraform /terraform /usr/local/bin/terraform

WORKDIR /workspace/terraform
CMD ["bash"]