#!/bin/bash

USAGE="assume-role <account_id> <role_name> <staging|live> <profile>"

# ---
# Check for correct arguments
# ---

if [ "$#" -lt 3 ]; then
  echo "Illegal number of parameters"
  echo "Usage: $USAGE"
  exit 1
fi

# ---
# Final variables
# ---

export ACCOUNT_ID=$1
export ROLE_NAME=$2
export AWS_ENV="$3"
export PROFILE="--profile default"

# ---
# Set profile if exists
# ---
#

if [ "$4" != "" ]; then
  export PROFILE="--profile $4"
fi

# ---
# Create variables for temporary credentials
# ---

ASSUME_ROLE="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
ROLE_SESSION_NAME="temp-${AWS_ENV}-${ROLE_NAME}-session"
TMP_FILE=".temp_credentials"

# ---
# Run assume-role CLI command
# ---

ASSUMED_ROLE_OUTPUT=$((aws sts assume-role --output json --role-arn ${ASSUME_ROLE} --role-session-name ${ROLE_SESSION_NAME} $PROFILE > ${TMP_FILE}) 2>&1)

if [ $? -eq 0 ]
then
  # ---
  # Export env vars that are used in new shell 
  # ---

  export AWS_ACCESS_KEY_ID=$(cat ${TMP_FILE} | jq -r ".Credentials.AccessKeyId")
  export TF_VAR_access_key=$AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$(cat ${TMP_FILE} | jq -r ".Credentials.SecretAccessKey")
  export TF_VAR_secret_key=$AWS_SECRET_ACCESS_KEY
  export AWS_SESSION_TOKEN=$(cat ${TMP_FILE} | jq -r ".Credentials.SessionToken")
  export TF_VAR_session_token=$AWS_SESSION_TOKEN
  export AWS_REGION=eu-west-1
  export TF_VAR_region=$AWS_REGION

  EXPIRATION=$(cat ${TMP_FILE} | jq -r ".Credentials.Expiration")
  export AWS_EXPIRATION=$(ruby -e "require 'time'; puts Time.parse('$EXPIRATION').localtime")
  export TERRAFORM_STATE_BUCKET="terraform-state.$AWS_ENV.vidsy.co"

  export ROLE_NAME=$ROLE_NAME
  export DIRECTORY=$DIRECTORY

  # ---
  # Delete .temp_credentials file
  # ---

  rm -rf .temp_credentials

  # ---
  # Change prompt colour based on environment
  # ---

  if [ "$AWS_ENV" == "staging" ]
  then
    export ENV_COLOUR="\[\e[1;32m\]"
  else
    export ENV_COLOUR="\[\e[1;31m\]"
  fi

  # ---
  # Create new shell with env vars exported
  # ---

  echo "export PS1=\"\n\$ENV_COLOUR\$AWS_ENV (\$ROLE_NAME) \[\e[0m\]\$DIRECTORY\n> \"" >> ~/.profile.assume
  echo ". ~/.profile" >> ~/.profile.assume
  echo "alias t=\"terraform\"" >> ~/.profile.assume
  /bin/bash --rcfile ~/.profile.assume
else
  echo "There was a problem assuming the role: $ASSUMED_ROLE_OUTPUT"
  exit 1
fi
