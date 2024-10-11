#!/bin/bash

# Variables
CHART_REPO_URL="" # for example "https://chartmuseum.mydomain.com"
ECR_REPO="" # for example "0123456789.dkr.ecr.eu-west-3.amazonaws.com"
AWS_REGION="" # for example eu-west-3
AWS_PROFILE="" # depending of your local .aws/config

# Input: Chart name and number of versions to download
CHART_NAME=$1
VERSION_LIMIT=$2

# Check if chart name is provided
if [ -z "$CHART_NAME" ]; then
  echo "Usage: $0 <chart_name> [version_limit]"
  exit 1
fi

# Enable OCI support
export HELM_EXPERIMENTAL_OCI=1
export AWS_PROFILE=$AWS_PROFILE

# Check if the ECR repository exists
if ! aws ecr describe-repositories --region $AWS_REGION --repository-names $CHART_NAME > /dev/null 2>&1; then
  echo "ECR repository $CHART_NAME does not exist. Please create it first."
else
  echo "ECR repository $CHART_NAME exists."
fi

RESPONSE=$(curl -s $CHART_REPO_URL/api/charts/$CHART_NAME)

# Check if the response is valid
if [ -z "$RESPONSE" ] || [[ "$RESPONSE" == *"not found"* ]]; then
  echo "Chart $CHART_NAME not found in ChartMuseum."
  exit 1
fi

# Extract versions using jq
ALL_VERSIONS=$(echo "$RESPONSE" | jq -r '.[] | select(.version != "") | .version')

# Sort versions by semver (optional)
SORTED_VERSIONS=$(echo "$ALL_VERSIONS" | sort -Vr)

# If a version limit is provided, get only the last X versions
if [ ! -z "$VERSION_LIMIT" ]; then
  SORTED_VERSIONS=$(echo "$SORTED_VERSIONS" | head -n $VERSION_LIMIT)
fi

# Loop through each version and migrate
for CHART_VERSION in $SORTED_VERSIONS; do
  echo "Checking if $CHART_NAME:$CHART_VERSION exists in ECR..."

  # Check if the chart version already exists in ECR
  EXISTS=$(aws ecr describe-images --region $AWS_REGION --repository-name $CHART_NAME --image-ids imageTag=$CHART_VERSION --query 'imageDetails[0].imageTags' --output text 2>/dev/null)

  if [ "$EXISTS" != "" ]; then
    echo "$CHART_NAME:$CHART_VERSION already exists in ECR. Skipping..."
    continue
  fi

  echo "Migrating $CHART_NAME:$CHART_VERSION"

  # Pull the specific chart from ChartMuseum
  helm pull $CHART_NAME --version $CHART_VERSION --repo $CHART_REPO_URL --untar

  rm -rf "$CHART_NAME-$CHART_VERSION.tgz"

  # Save and push the chart to ECR
  helm package $CHART_NAME
  helm push $CHART_NAME-$CHART_VERSION.tgz oci://$ECR_REPO/

  # Clean up
  rm -rf $CHART_NAME
  rm -rf "$CHART_NAME-$CHART_VERSION.tgz"

  echo "Migration of $CHART_NAME:$CHART_VERSION completed."
done
