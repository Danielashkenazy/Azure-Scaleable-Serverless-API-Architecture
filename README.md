# Weather App - Azure Serverless Architecture

## Overview
Serverless weather forecast application built with Azure Functions, API Management, PostgreSQL, and Front Door CDN.

## Architecture
- **Frontend**: Static website (HTML/CSS/JS) on Azure Storage + Front Door CDN
- **Backend**: Azure Functions (Python) with HTTP triggers
- **API Gateway**: Azure API Management with CORS and routing
- **Database**: Azure PostgreSQL Flexible Server
- **Security**: Azure Key Vault for secrets management

## Prerequisites
- Azure subscription
- Terraform >= 1.3.0
- Azure CLI
- OpenWeather API key

## Local Development Setup

### 1. Clone the repository
```bash
git clone <your-repo-url>
cd HomeExerciseAztc
```

### 2. Configure Terraform variables
```bash
cd Terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your actual values
```

### 3. Deploy infrastructure
```bash
terraform init
terraform plan
terraform apply
```

## GitHub Actions CI/CD

### Required GitHub Secrets
Configure these secrets in your GitHub repository (Settings → Secrets and variables → Actions):

#### Azure Authentication:
- `AZURE_CLIENT_ID` - Service Principal App ID
- `AZURE_CLIENT_SECRET` - Service Principal Password
- `AZURE_SUBSCRIPTION_ID` - Azure Subscription ID
- `AZURE_TENANT_ID` - Azure AD Tenant ID

#### Application Secrets:
- `DB_ADMIN_USERNAME` - PostgreSQL admin username
- `DB_ADMIN_PASSWORD` - PostgreSQL admin password
- `OPENWEATHER_API_KEY` - OpenWeather API key

### Setup Options:

#### Option A: Using Your Current User (No Admin Rights Required)
If you don't have permissions to create Service Principals, use your current Azure user credentials:

```bash
# Get your current subscription ID
az account show --query id -o tsv

# Get your tenant ID
az account show --query tenantId -o tsv
```

Then create a Service Principal using Azure Portal:
1. Go to Azure Portal → Azure Active Directory → App registrations → New registration
2. Name: `github-actions-app`
3. After creation, go to Certificates & secrets → New client secret
4. Copy the secret value immediately
5. Go to your Subscription → IAM → Add role assignment → Contributor → Assign to the new app

Add these to GitHub Secrets:
- `AZURE_CLIENT_ID` = Application (client) ID from app registration
- `AZURE_CLIENT_SECRET` = The secret value you copied
- `AZURE_SUBSCRIPTION_ID` = Your subscription ID
- `AZURE_TENANT_ID` = Your tenant ID

#### Option B: Using Azure CLI (Requires Contributor Role)
```bash
az ad sp create-for-rbac --name "github-actions-sp" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID> \
  --sdk-auth
```

Copy the JSON output values to GitHub Secrets.

## Deployment Workflow
1. Push to `main` branch triggers automatic deployment
2. Terraform validates and plans changes
3. On success, applies infrastructure changes
4. Frontend assets are uploaded to Storage Account
5. Front Door propagates changes (5-15 minutes)

## Application URL
After deployment, access your app at:
```
https://weather-fd-endpoint-<unique-id>.z03.azurefd.net
```

## Project Structure
```
.
├── .github/
│   └── workflows/
│       └── deploy.yml          # CI/CD pipeline
├── Terraform/
│   ├── main.tf                 # Infrastructure as Code
│   ├── variables.tf            # Variable definitions
│   ├── outputs.tf              # Output values
│   └── terraform.tfvars.example # Template for variables
├── weather-app/
│   ├── app/                    # Azure Functions code
│   │   ├── weather/           # Get weather function
│   │   ├── save/              # Save forecast function
│   │   └── shared/            # Shared libraries
│   └── static/                # Frontend files
│       ├── index.html
│       ├── style.css
│       └── js/
│           └── script.js
└── README.md
```

## Features
- ✅ Global CDN with low latency
- ✅ Serverless architecture (cost-efficient)
- ✅ Automatic scaling
- ✅ Secure secrets management
- ✅ CORS-enabled API
- ✅ PostgreSQL database with backups
- ✅ CI/CD with GitHub Actions

## Cost Estimation
- **Development/Testing**: ~$50-100/month
- **Production**: ~$150-300/month

## Security Best Practices
- ✅ Secrets stored in Azure Key Vault
- ✅ Function App with IP restrictions (APIM only)
- ✅ PostgreSQL with firewall rules
- ✅ No hardcoded credentials in code
- ✅ HTTPS-only communication

## Troubleshooting

### Front Door 404 errors
Wait 5-15 minutes for deployment to propagate across all edge locations.

### Function App cold start (504 timeout)
First request may take 20-60 seconds. Subsequent requests are fast.

### Database connection issues
Check Key Vault secrets and PostgreSQL firewall rules.

## License


## Author
Daniel - DevOps Engineer
