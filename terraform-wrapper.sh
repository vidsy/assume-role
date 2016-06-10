#!/bin/bash

TIME_LEFT=$(ruby -e "require 'time'; puts ((Time.parse('$AWS_EXPIRATION') - Time.now) / 60).floor")
if [ "$TIME_LEFT" -lt "0" ]; then
  echo "Role has expired ($AWS_EXPIRATION), please exit this shell and start another"
  exit -1
fi

case $1 in
plan|apply|destroy)
  VAR_FILE="-var-file=$AWS_ENV.tfvars"

  if [ ! -f $AWS_ENV.tfvars ]; then
    VAR_FILE=""
  fi

  STATE_FILE=$DIRECTORY

  if [ -f .terraform_config ]; then
    STATE_FILE=$(cat .terraform_config | jq -r ".remote.key")
  fi

  rm -rf .terraform/terraform.tfstate*
  terraform.real remote config -backend=s3 -backend-config="bucket=$TERRAFORM_STATE_BUCKET" -backend-config="key=$STATE_FILE.tfstate" -backend-config="region=$AWS_REGION"
  terraform.real $@ $VAR_FILE
  ;;
*)
  terraform.real $@
  ;;
esac
