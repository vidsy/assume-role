FROM python:slim
MAINTAINER Steven Jack <smaj@vidsy.co>

ENV AWS_CLI_VERSION 1.10.19
ENV TF_VERSION 0.7.9
ENV AWS_SDK_VERSION 2

RUN pip install awscli==${AWS_CLI_VERSION}

RUN apt-get update
RUN apt-get install -y jq zip curl ruby
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -L -o /terraform.zip https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip
RUN unzip -d /usr/local/bin /terraform.zip
RUN chmod u+x /usr/local/bin/terraform*
RUN mv /usr/local/bin/terraform /usr/local/bin/terraform.real

RUN gem install aws-sdk -v "~> ${AWS_SDK_VERSION}"

ADD assume-role.sh /usr/local/bin/assume-role
RUN chmod u+x /usr/local/bin/assume-role
ADD terraform-wrapper.sh /usr/local/bin/terraform
RUN chmod u+x /usr/local/bin/terraform

RUN mkdir /cwd
WORKDIR /cwd

ENTRYPOINT ["assume-role"]
