# Helm Chart Migration Script to Amazon ECR

## Overview

This script automates the process of migrating Helm charts from a local ChartMuseum to an Amazon Elastic Container Registry (ECR). It supports migrating multiple versions of a specified chart and ensures that existing versions in ECR are not uploaded again.

### Features

- **Migration of specific Helm charts** from ChartMuseum to Amazon ECR.
- **Optional limit** on the number of versions to migrate.
- **Version existence check** to avoid redundant uploads to ECR.

---

## Prerequisites

1. **AWS CLI**: Installed and configured with appropriate permissions to create and push to ECR.
2. **Helm CLI**: Installed with OCI support enabled.
3. **jq**: A command-line JSON processor (used to parse the ChartMuseum API response).
4. **ChartMuseum**: Running and accessible.
5. Login to your AWS ECR (if you do not use [ecr-helper](https://github.com/awslabs/amazon-ecr-credential-helper))

---

## Script Parameters

The script takes two arguments:

1. **Chart Name** (required): The name of the Helm chart to be migrated.
2. **Version Limit** (optional): The number of most recent versions to migrate. If not provided, all versions are migrated.

---

## How the Script Works

1. **Checks if ECR Repository Exists**:
   - If the specified ECR repository for the chart doesn't exist, it prompts you to create one.

2. **Authenticates with ECR**:
   - Logs into the ECR repository using AWS credentials.

3. **Fetches Chart Versions from ChartMuseum**:
   - Retrieves the available versions of the chart from ChartMuseum.

4. **Skips Existing Versions in ECR**:
   - Before migrating each version, the script checks if that version already exists in ECR. If found, the version is skipped.

5. **Pulls and Pushes Helm Chart Versions**:
   - For each version not already in ECR, it pulls the chart from ChartMuseum and pushes it to the ECR repository.

---

## Usage Instructions

### 1. Clone the Script

Copy the script into a file called `migrate_chart_versions.sh`.

### 2. Make the Script Executable

```bash
chmod +x migrate_chart_versions.sh
```

### 3. Run the Script

```bash
./migrate_chart_versions.sh <chart_name> [version_limit]
```

### 4. Expected Output

- The script will output messages as it migrates each version or skips versions that already exist in ECR.

---

## Environment Variables

Make sure the following environment variables are updated in the script:

- `CHART_REPO_URL`: The URL of your ChartMuseum instance.
- `ECR_REPO`: Your Amazon ECR registry URL.
- `AWS_REGION`: The AWS region where your ECR is located.

---

## Dependencies

Ensure that the following tools are installed on your system:

- **AWS CLI**: Used for interacting with ECR.
- **Helm**: Used for pulling and pushing charts.
- **jq**: For parsing JSON from ChartMuseum.

---

## Notes

- This script assumes that the Helm chart in ChartMuseum uses versioned tags (latest tags fetched via semver format X.Y.Z).
- Ensure your AWS CLI is configured with sufficient permissions to push images to ECR.

---

## License

This script is free to use and modify for your personal or professional use.
