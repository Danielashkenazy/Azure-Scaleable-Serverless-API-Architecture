######################################################################################
# Azure Storage Account Setup for Terraform State
# Purpose: Create infrastructure for storing Terraform remote state
# Usage: Run this ONCE before using remote backend
######################################################################################

# STEP 1: Create Resource Group
az group create \
  --name terraform-state-rg \
  --location northeurope

# STEP 2: Create Storage Account
# Note: Storage account name must be globally unique
# Replace 'tfstateweatherapp' with your unique name (lowercase, alphanumeric, 3-24 chars)
az storage account create \
  --name tfstateweatherapp \
  --resource-group terraform-state-rg \
  --location northeurope \
  --sku Standard_LRS \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2

# STEP 3: Create Blob Container
az storage container create \
  --name tfstate \
  --account-name tfstateweatherapp \
  --auth-mode login

# STEP 4: Enable Versioning (for state file history)
az storage account blob-service-properties update \
  --account-name tfstateweatherapp \
  --resource-group terraform-state-rg \
  --enable-versioning true

######################################################################################
# USAGE INSTRUCTIONS
######################################################################################

# 1. Update backend.tfvars with your storage account name
# 2. Initialize Terraform with backend configuration:
#    terraform init -backend-config=backend.tfvars

# 3. If migrating from local state, Terraform will prompt to copy existing state
#    Answer 'yes' to migrate local state to remote backend

# 4. Verify remote state:
#    az storage blob list --container-name tfstate --account-name tfstateweatherapp --auth-mode login

######################################################################################
# IMPORTANT NOTES
######################################################################################

# - State files contain sensitive data (passwords, keys) - never commit to git
# - Storage account access is controlled via Azure RBAC
# - State locking prevents concurrent modifications
# - Consider enabling soft delete for state recovery
# - Use separate containers for different environments (dev/staging/prod)
