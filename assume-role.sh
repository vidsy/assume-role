#!/bin/bash

USAGE="assume-role <staging_account_id> <prod_account_id> <role_prefix> <staging|live>"

# ---
# Check for correct arguments
# ---

if [ "$#" -ne 4 ]; then
  echo "Illegal number of parameters"
  echo "Usage: $USAGE"
  exit 1
fi

# ---
# Input variables
# ---

AWS_ENV="$4"

# ---
# Final variables
# ---

STAGING_ACCOUNT=$1
LIVE_ACCOUNT=$2
RAND_STRING=$3

# ---
# Set account ID depending on environment
# ---

if [ "${AWS_ENV}" = "staging" ]; then
  ACCOUNT_ID="${STAGING_ACCOUNT}"
fi

if [ "${AWS_ENV}" = "live" ]; then
  ACCOUNT_ID="${LIVE_ACCOUNT}"
fi

# ---
# Create role ID
# ---

ROLE_ID="${AWS_ENV}_admin_${RAND_STRING}"

# ---
# Create variables for temporary credentials
# ---

ASSUME_ROLE="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_ID}"
ROLE_SESSION_NAME="temp-${ACCOUNT}-${ROLE}-session"
TMP_FILE=".temp_credentials"

# ---
# Run assume-role CLI command
# ---

ASSUMED_ROLE_OUTPUT=$((aws sts assume-role --output json --role-arn ${ASSUME_ROLE} --role-session-name ${ROLE_SESSION_NAME} > ${TMP_FILE}) 2>&1)

if [ $? -eq 0 ]
then
  # ---
  # Get variables from .temp_credentials file
  # ---

  ACCESS_KEY=$(cat ${TMP_FILE} | jq -r ".Credentials.AccessKeyId")
  SECRET_KEY=$(cat ${TMP_FILE} | jq -r ".Credentials.SecretAccessKey")
  SESSION_TOKEN=$(cat ${TMP_FILE} | jq -r ".Credentials.SessionToken")
  EXPIRATION=$(cat ${TMP_FILE} | jq -r ".Credentials.Expiration")

  # ---
  # Delete .temp_credentials file
  # ---

  rm .temp_credentials

  # ---
  # Print summary
  # ---

  cat <<Output
  export TF_VAR_access_key="$ACCESS_KEY"
  export TF_VAR_secret_key="$SECRET_KEY"
  export TF_VAR_session_token="$SESSION_TOKEN"
Output
else
  echo "There was a problem assuming the role: $ASSUMED_ROLE_OUTPUT"
  exit 1
fi
