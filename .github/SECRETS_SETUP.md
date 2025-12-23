# GitHub Secrets Configuration

This document describes the secrets required for the CI/CD pipeline.

## Required Secrets

Navigate to: **Repository Settings → Secrets and variables → Actions → New repository secret**

### 1. Azure Service Principal Credentials

First, create a Service Principal in Azure:

```bash
az ad sp create-for-rbac \
  --name "github-actions-weather-app" \
  --role Contributor \
  --scopes /subscriptions/{SUBSCRIPTION_ID} \
  --sdk-auth
```

This command will output a JSON. Use it to create the following secrets:

#### `AZURE_CREDENTIALS` (JSON format)
```json
{
  "clientId": "<CLIENT_ID>",
  "clientSecret": "<CLIENT_SECRET>",
  "subscriptionId": "<SUBSCRIPTION_ID>",
  "tenantId": "<TENANT_ID>"
}
```

#### Individual secrets (extract from the JSON above):
- **`AZURE_CLIENT_ID`** - The `clientId` from the JSON
- **`AZURE_CLIENT_SECRET`** - The `clientSecret` from the JSON
- **`AZURE_SUBSCRIPTION_ID`** - The `subscriptionId` from the JSON
- **`AZURE_TENANT_ID`** - The `tenantId` from the JSON

### 2. Database Credentials

- **`DB_ADMIN_USERNAME`** - PostgreSQL admin username (e.g., `psqladmin`)
- **`DB_ADMIN_PASSWORD`** - PostgreSQL admin password (min 8 chars, include uppercase, lowercase, number)

### 3. OpenWeather API

- **`OPENWEATHER_API_KEY`** - Your OpenWeatherMap API key from https://openweathermap.org/api

## Complete Secret List

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AZURE_CREDENTIALS` | Azure Service Principal JSON | `{"clientId": "...", ...}` |
| `AZURE_CLIENT_ID` | Azure Client ID | `12345678-1234-1234-1234-123456789012` |
| `AZURE_CLIENT_SECRET` | Azure Client Secret | `abc123...` |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | `87654321-4321-4321-4321-210987654321` |
| `AZURE_TENANT_ID` | Azure Tenant ID | `11111111-2222-3333-4444-555555555555` |
| `DB_ADMIN_USERNAME` | PostgreSQL username | `psqladmin` |
| `DB_ADMIN_PASSWORD` | PostgreSQL password | `MySecureP@ss123` |
| `OPENWEATHER_API_KEY` | OpenWeather API key | `a1b2c3d4e5f6...` |

## Workflow Behavior

- **Pull Requests**: Run `terraform plan` only (validation)
- **Push to main**: Run `terraform plan` + `terraform apply` (deployment)
- **Manual trigger**: Available via GitHub Actions UI

## Service Principal Permissions

The Service Principal needs:
- **Contributor** role on the subscription (for resource creation)
- **User Access Administrator** (optional, if managing RBAC)

## Security Notes

✅ Never commit secrets to the repository  
✅ Use GitHub's encrypted secrets feature  
✅ Rotate Service Principal credentials periodically  
✅ Consider using Azure Key Vault for additional secret management  

## Testing the Setup

1. Add all secrets to GitHub
2. Push to a branch (not main) - should run plan only
3. Create a Pull Request - should run plan
4. Merge to main - should run plan + apply
