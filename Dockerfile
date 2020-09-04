FROM python:slim
MAINTAINER Steven Jack <steve@vidsy.co>

ENV AWS_CLI_VERSION 1.18.132
ENV TF_VERSION 0.12.29
ENV AWS_SDK_VERSION 2
ENV DOCKER_VERSION 18.03.1-ce
ENV JQ_VERSION 1.6

RUN pip install awscli==${AWS_CLI_VERSION}

RUN apt-get update
RUN apt-get install -y zip curl ruby make
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -L -o /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64
RUN chmod u+x /usr/local/bin/jq

RUN curl -L -o /terraform.zip https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip
RUN unzip -d /usr/local/bin /terraform.zip
RUN chmod u+x /usr/local/bin/terraform*
RUN mv /usr/local/bin/terraform /usr/local/bin/terraform.real

RUN curl -L -o /tmp/docker-${DOCKER_VERSION}.tgz https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz
RUN tar -xz -C /tmp -f /tmp/docker-${DOCKER_VERSION}.tgz
RUN mv /tmp/docker/* /usr/bin

RUN gem install aws-sdk --no-ri --no-rdoc -v "~> ${AWS_SDK_VERSION}"

ADD assume-role.sh /usr/local/bin/assume-role
RUN chmod u+x /usr/local/bin/assume-role
ADD terraform-wrapper.sh /usr/local/bin/terraform
RUN chmod u+x /usr/local/bin/terraform

ENTRYPOINT ["assume-role"]
