FROM python:slim
MAINTAINER Steven Jack <smaj@vidsy.co>

ENV AWS_CLI_VERSION 1.10.19
RUN pip install awscli==$AWS_CLI_VERSION

RUN apt-get update
RUN apt-get install -y jq
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD assume-role.sh /usr/local/bin/assume-role
RUN chmod u+x /usr/local/bin/assume-role

ENTRYPOINT ["assume-role"]
