# How to setup and use the terraform pipeline

## Intro

This document explains how to use the workflow located at `.github/workflows/terraform-pipeline.yml`. You might want to use this workflow to provision the [`kubecraft`](https://github.com/mischavandenburg/kubecraft) community project on your own infrastructure on Azure.

## Pre-requisites

To follow along, you will need:

- A fork of [`mischavandenburg/kubecraft`](https://github.com/mischavandenburg/kubecraft) on your Github account.
- An Azure account with an active subscription.

## Azure setup

Before executing the pipeline on your Github account, we need to configure the remote backend (`azurerm` provider on Azure Blob Storage) and obtain the details for OIDC authentication.

### Service Principal and Federated Identity

Follow these documents in order for a complete walk-through to setup a service principal with a federated identity for OIDC authentication from Github actions:

- [Create a service principal](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal)
- [Configure a federated identity](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp#github-actions)

**Note:** You will need to create credentials valid for a `push` to the `main` branch, and for the `staging` environment.

- Specify an Entity type of Branch and a GitHub branch name of "main".
- Specify an Entity type of Environment and a GitHub environment name of "staging" (this must correspond with the environment name you set in your repo fork)

When the service principal is created, assign it the "Contributor" role on the subscription that you will be deploying to.

### Remote backend configuration

For the remote backend configuration, we will need to configure a resource group, storage account, and container on Azure Blob Storage. You can use the following script to provision these resources:

```bash
#!/bin/bash

RESOURCE_GROUP_NAME=tfstate
STORAGE_ACCOUNT_NAME=tfstate$RANDOM
CONTAINER_NAME=tfstate

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location eastus

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME

ACCOUNT_KEY=$(az storage account keys list --resource-group tfstate --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)
```

Now, take note of your `$STORAGE_ACCOUNT_NAME`. You will need to specify its value under the `storage_account_name` property of the `backend` configuration on `terraform/providers`.

Also, copy your `ACCOUNT_KEY` and store it on Github Actions secrets under a secret named `ARM_ACCESS_KEY`.

### Github environment

The Terraform pipeline leverages environment protection rules to enable manual approvals for the `terraform apply` command. In order to use this workflow, you will need to create a `staging` environment from your repository settings page (on your own fork). You don't need to add any environment protection rules if you don't want to, but if you do, simply check the "require approvals" checkbox and add yourself as a required reviewer.

### Push and Test

Once you've created the secrets on Github Actions for OIDC authentication, adjusted the backend provider configuration to your own Azure storage account, and created the `staging` environment on your repository, commit your changes and push the code to your `main` branch. This will trigger the pipeline automatically. Alternatively, you can navigate to `https://github.com/your-username/kubecraft/actions`, select the Terraform pipeline workflow on the left hand side menu, and use the "Run workflow" button to manually trigger the workflow execution.
