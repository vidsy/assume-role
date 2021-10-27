#!/bin/bash

TIME_LEFT=$(ruby -e "require 'time'; puts ((Time.parse('$AWS_EXPIRATION') - Time.now) / 60).floor")
if [ "$TIME_LEFT" -lt "0" ]; then
  echo "Role has expired ($AWS_EXPIRATION), please exit this shell and start another"
  exit -1
fi

function var_file_path() {
  if [ -z "$VAR_FILE" ]; then
    echo "-var-file=$AWS_ENV.tfvars"

    if [ ! -f $AWS_ENV.tfvars ]; then
      echo ""
    fi
  fi
}

VAR_FILE="$(var_file_path)"

case $1 in
plan|apply|destroy|refresh)
  terraform.real $@ $VAR_FILE
  ;;
import)
  terraform.real import $VAR_FILE ${@:2}
  ;;
init)
  rm -rf .terraform/terraform.tfstate*
  terraform.real init -backend=true -backend-config="bucket=$TERRAFORM_STATE_BUCKET" -backend-config="region=$AWS_REGION"
  ;;
*)
  terraform.real $@
  ;;
esac
