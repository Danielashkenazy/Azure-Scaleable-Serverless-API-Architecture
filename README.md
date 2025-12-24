# Weather Application - Azure Serverless Architecture

A globally-distributed, serverless weather forecast application built on Azure PaaS services with production-grade infrastructure automation.

## 🏗️ Architecture Overview

This project demonstrates a modern, cloud-native architecture using:
- **Serverless Compute**: Azure Functions (Python 3.10)
- **API Gateway**: Azure API Management (Consumption tier)
- **Global CDN**: Azure Front Door for worldwide edge delivery
- **Database**: PostgreSQL Flexible Server
- **Monitoring**: Application Insights + Log Analytics
- **Security**: Azure Key Vault for secrets management
- **IaC**: Terraform with modular structure
- **CI/CD**: GitHub Actions with automated deployment

### Design Principles
✅ **Serverless-first**: Pay-per-use, automatic scaling  
✅ **Cost-optimized**: Consumption tier APIM (~$870/month savings)  
✅ **Globally distributed**: CDN for low-latency worldwide access  
✅ **Security by default**: No hardcoded credentials, Key Vault integration  
✅ **Observable**: Application Insights for full request tracing  
✅ **Infrastructure as Code**: 100% Terraform, no manual clicks  

---

## 📁 Project Structure

```
.
├── Terraform/                      # Infrastructure as Code
│   ├── main.tf                    # Root orchestration
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Deployment outputs
│   └── modules/                   # Modular Terraform components
│       ├── monitoring/            # Log Analytics + App Insights
│       ├── database/              # PostgreSQL Flexible Server
│       ├── security/              # Key Vault + Secrets
│       ├── storage/               # Static website + Function storage
│       ├── compute/               # Azure Functions
│       ├── api-gateway/           # API Management
│       └── cdn/                   # Azure Front Door
│
├── weather-app/
│   ├── app/                       # Python Azure Functions
│   │   ├── weather/              # GET /weather endpoint
│   │   ├── save/                 # POST /save endpoint
│   │   └── shared/               # Shared weather library
│   └── static/                    # Frontend assets
│       ├── index.html
│       ├── styles.css
│       └── js/script.js
│
├── .github/workflows/
│   ├── deploy.yml                # CI/CD pipeline
│   └── python-quality.yml        # Code quality checks
│
└── DELIVERABLES/                  # Project documentation
    ├── ARCHITECTURE.md           # Architecture decisions
    └── AI-PROMPTS.md             # AI-assisted development log
```

---

## 🚀 Deployment

### Prerequisites
- Azure CLI authenticated (`az login`)
- Terraform >= 1.6.0
- GitHub repository with secrets configured

### GitHub Secrets Required
Configure these in: **Repository Settings → Secrets and variables → Actions**

| Secret | Description |
|--------|-------------|
| `AZURE_CREDENTIALS` | Service Principal JSON (full JSON output) |
| `AZURE_CLIENT_ID` | Azure Client ID |
| `AZURE_CLIENT_SECRET` | Azure Client Secret |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID |
| `AZURE_TENANT_ID` | Azure Tenant ID |
| `DB_ADMIN_USERNAME` | PostgreSQL admin username |
| `DB_ADMIN_PASSWORD` | PostgreSQL admin password (8+ chars, mixed case, number) |
| `OPENWEATHER_API_KEY` | OpenWeatherMap API key |

**Create Service Principal:**
```bash
az ad sp create-for-rbac \
  --name "github-weather-app" \
  --role Contributor \
  --scopes /subscriptions/{SUBSCRIPTION_ID} \
  --sdk-auth
```

### Deployment Methods

#### Option 1: GitHub Actions (Recommended)
```bash
git push origin main
```
- Automatically runs `terraform plan` + `terraform apply`
- Full logs available in GitHub Actions UI
- Outputs displayed in workflow summary

#### Option 2: Manual Deployment
```bash
cd Terraform

# Initialize
terraform init

# Plan
terraform plan \
  -var="db_admin_username=weatheradmin" \
  -var="db_admin_password=YourSecurePassword123!" \
  -var="openweather_api_key=your_api_key_here" \
  -out=tfplan

# Apply
terraform apply tfplan

# Get outputs
terraform output
```

---

## 🌐 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                          Internet Users                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
            ┌────────────────────────┐
            │   Azure Front Door     │  ◄── Global CDN, SSL, WAF
            │   (Standard Tier)      │
            └───────────┬────────────┘
                        │
            ┌───────────┴───────────┐
            │                       │
            ▼                       ▼
    ┌──────────────┐      ┌─────────────────┐
    │   Storage    │      │  API Management │  ◄── Rate limiting, CORS
    │ Static Site  │      │  (Consumption)  │
    └──────────────┘      └────────┬────────┘
            │                      │
            │                      ▼
            │            ┌──────────────────┐
            │            │ Azure Functions  │  ◄── Python 3.10, ZIP deploy
            │            │  - /weather      │
            │            │  - /save         │
            │            └────────┬─────────┘
            │                     │
            │         ┌───────────┴──────────┐
            │         │                      │
            │         ▼                      ▼
            │  ┌─────────────┐     ┌────────────────┐
            │  │  Key Vault  │     │   PostgreSQL   │
            │  │   Secrets   │     │ Flexible Server│
            │  └─────────────┘     └────────────────┘
            │
            │         ┌─────────────────────────┐
            └────────►│  Application Insights   │  ◄── Monitoring
                      │  + Log Analytics        │
                      └─────────────────────────┘
```

---

## 📊 Resource Inventory

| Service | SKU/Tier | Purpose | Cost Impact |
|---------|----------|---------|-------------|
| **API Management** | Consumption_0 | API Gateway | ~$3.50 per million calls |
| **Azure Functions** | Consumption (Y1) | Serverless compute | ~$0.20 per million executions |
| **PostgreSQL** | B_Standard_B1ms | Database | ~$13/month |
| **Front Door** | Standard | Global CDN | ~$35/month + traffic |
| **Storage Account** | Standard LRS | Static site + Functions | ~$0.50/month |
| **Key Vault** | Standard | Secrets management | ~$0.03 per 10k operations |
| **Application Insights** | Log Analytics-based | APM | ~$2.30/GB after 5GB free |

**Estimated Total**: ~$50-100/month (depending on traffic)

---

## 🔐 Security Features

✅ **No hardcoded secrets** - All credentials in Key Vault  
✅ **IP restrictions** - Function App accepts only APIM traffic (optional)  
✅ **HTTPS only** - SSL/TLS enforced across all endpoints  
✅ **CORS policies** - Configurable per API operation  
✅ **Managed Identity ready** - Infrastructure prepared for MSI  
✅ **Secrets rotation** - Key Vault supports versioning  

---

## 🎯 Production Recommendations

This is a home assignment demonstrating IaC and DevOps skills. For production deployment, consider:

### High Availability
- [ ] Enable zone redundancy for PostgreSQL
- [ ] Add Azure Front Door Premium with WAF
- [ ] Configure Function App in multiple regions (active-passive)
- [ ] Implement Redis Cache for API responses

### Security Hardening
- [ ] Enable Private Endpoints for all PaaS services
- [ ] Implement VNet Integration for Functions
- [ ] Add Azure Monitor Action Groups for alerts (email, SMS, webhooks)
- [ ] Enable Microsoft Defender for Cloud
- [ ] Implement Key Vault access policies with least privilege
- [ ] Restrict APIM CORS to specific CDN origin (currently `*`)

### Monitoring & Alerting
- [ ] Create metric alerts (Function errors >10, DB CPU >80%, Connection failures)
- [ ] Set up availability tests in Application Insights
- [ ] Configure log retention policies (currently 30 days)
- [ ] Implement distributed tracing correlation

### Cost Optimization
- [ ] Enable Azure Advisor recommendations
- [ ] Set up budget alerts
- [ ] Consider Reserved Instances for long-term workloads
- [ ] Implement auto-scaling based on traffic patterns

### CI/CD Enhancements
- [ ] Add integration tests to pipeline
- [ ] Implement blue-green deployment strategy
- [ ] Add manual approval gates for production
- [ ] Store Terraform state in Azure Storage with state locking

---

## 🛠️ Development

### Local Testing
```bash
# Install Python dependencies
cd weather-app/app
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Run tests
pytest tests/ -v

# Code quality checks
black . --check
flake8 .
```

### Environment Variables
Create `.env` file in `weather-app/app/`:
```env
DB_HOST=your-db-server.postgres.database.azure.com
DB_NAME=weatherdb
DB_USER=weatheradmin
DB_PASSWORD=your_password
OPENWEATHER_API_KEY=your_api_key
```

---

## 🧪 API Endpoints

### GET /weather
Retrieve 5-day weather forecast for a city.

**Request:**
```bash
curl "https://your-cdn-endpoint.azurefd.net/weather?city=London"
```

**Response:**
```json
{
  "city": "London",
  "country": "GB",
  "forecast": [
    {
      "date": "2025-12-24",
      "temp": 8.5,
      "feels_like": 6.2,
      "humidity": 75,
      "description": "light rain"
    }
  ]
}
```

### POST /save
Save weather forecast to database.

**Request:**
```bash
curl -X POST "https://your-cdn-endpoint.azurefd.net/save" \
  -H "Content-Type: application/json" \
  -d '{"name": "Daniel", "city": "London"}'
```

**Response:**
```json
{
  "message": "saved",
  "id": 42
}
```

---

## 🐛 Troubleshooting

### Function returns 404
- **Cause**: Binding name error in `function.json`
- **Fix**: Ensure `"name": "req"` for httpTrigger and `"name": "res"` for output (not `"$return"`)

### CORS errors in browser
- **Cause**: APIM CORS policy not configured
- **Fix**: Update APIM policy to allow CDN origin (currently set to `*`)

### Database connection fails
- **Cause**: Firewall rules or incorrect connection string
- **Fix**: Check PostgreSQL firewall allows Azure services

### Terraform circular dependency
- **Cause**: Modules depending on each other's outputs
- **Fix**: Use optional variables with defaults or explicit `depends_on`

### GitHub Actions fails with "Resource already exists"
- **Cause**: Leftover resources from previous deployment
- **Fix**: Run `az group delete --name weather-app-rg --yes --no-wait` and re-run workflow

---

## 📚 Additional Resources

- [Azure Functions Python Developer Guide](https://docs.microsoft.com/azure/azure-functions/functions-reference-python)
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure API Management Best Practices](https://docs.microsoft.com/azure/api-management/api-management-howto-use-managed-service-identity)
- [GitHub Actions for Azure](https://docs.microsoft.com/azure/developer/github/github-actions)

---

## 👤 Author

**Daniel Ashkenazy**  
DevOps Engineer | Cloud Architect

---

## 📝 License

This project is created as a home assignment for demonstration purposes.

---

**Last Updated**: December 23, 2025  
**Terraform Version**: 1.6.0  
**Azure Provider**: 3.90.0
