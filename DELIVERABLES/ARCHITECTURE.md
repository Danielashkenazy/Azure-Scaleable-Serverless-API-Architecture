# Architecture Overview

**Project**: Weather Application - Azure Serverless  
**Author**: Daniel Ashkenazy  
**Date**: December 23, 2025

---

## Architecture Diagram

```
┌─────────────┐
│   Users     │
└──────┬──────┘
       │ HTTPS
       ▼
┌──────────────────────┐
│  Azure Front Door    │  Global CDN, edge caching
└─────────┬────────────┘
          │
          ├────────────────────────────────┐
          │                                │
          ▼                                ▼
┌─────────────────────┐      ┌──────────────────────┐
│  Static Website     │      │  API Management      │
│  (Storage Account)  │      │  (Consumption tier)  │
│  • HTML/CSS/JS      │      └──────────┬───────────┘
└─────────────────────┘                 │
                                        ▼
                              ┌─────────────────────┐
                              │  Azure Functions    │
                              │  (Python 3.10)      │
                              └──────┬──────┬───────┘
                                     │      │
                    ┌────────────────┘      └──────────────┐
                    ▼                                      ▼
          ┌──────────────────┐                   ┌─────────────────┐
          │  PostgreSQL      │                   │  OpenWeather    │
          │  (Flexible)      │                   │  API            │
          └──────────────────┘                   └─────────────────┘
                    ▲
                    │
          ┌─────────┴─────────┐
          │                   │
   ┌──────┴────────┐   ┌──────┴────────────┐
   │  Key Vault    │   │  App Insights     │
   │  (secrets)    │   │  + Log Analytics  │
   └───────────────┘   └───────────────────┘
```

---

## Design Decisions Summary

### 1. **Serverless Architecture**

**Decision**: Azure Functions (Consumption plan)

**Why**:
- **Cost**: $0.20 per million executions vs ~$100/month for dedicated compute
- **Scale**: Auto-scales from 0 to 200 instances based on demand
- **Maintenance**: Zero server management

**Trade-off**: Cold start latency (1-2 seconds) acceptable for this use case

---

### 2. **API Management - Consumption Tier**

**Decision**: Consumption tier instead of Standard

**Why**:
- **Cost Savings**: ~$870/month saved (Standard $900/month → Consumption $3.50 per million calls)
- **Suitable for Variable Traffic**: Pay-per-use model matches weather app usage pattern
- **All Required Features**: CORS, rate limiting, API versioning included

**Trade-off**: Cold start on first request, no VNet integration (not needed for this app)

---

### 3. **PostgreSQL - Burstable Tier**

**Decision**: B_Standard_B1ms (1 vCore, 2GB RAM)

**Why**:
- **Cost**: $13/month vs $100+/month for General Purpose
- **Sufficient Performance**: Weather queries are simple, low-latency
- **Burstable**: Can handle occasional spikes up to 100% CPU

**Trade-off**: Not suitable for sustained high CPU workloads (not a concern here)

---

### 4. **Front Door CDN for Global Distribution**

**Decision**: Azure Front Door Standard tier

**Why**:
- **Global Edge Network**: ~100 PoPs worldwide, low latency for all users
- **Multiple Origins**: Routes static content to Storage, API calls to APIM
- **Security**: Built-in DDoS protection, WAF capabilities
- **Cost**: $35/month base + $0.06 per GB egress (reasonable for demo)

**Alternative Considered**: Azure CDN (cheaper)  
**Why Not**: Wanted latest features (health probes, advanced routing)

---

### 5. **Key Vault for Secrets**

**Decision**: Azure Key Vault Standard tier

**Why**:
- **Security Best Practice**: No hardcoded credentials in code/config
- **Audit Trail**: Tracks who accessed which secret and when
- **Secret Rotation**: Versioning support for zero-downtime updates

**Trade-off**: Extra service dependency (acceptable for production-grade security)

---

### 6. **Application Insights + Log Analytics**

**Decision**: Workspace-based Application Insights

**Why**:
- **Full APM**: Request tracing, dependency tracking, exception logging
- **Cost-Effective**: Pay-per-GB ingested (~$2/GB, typically $5-10/month)
- **Integrated**: Single pane of glass for logs and metrics

**Not Included** (for demo simplicity): Action Groups and Metric Alerts  
**Production Addition**: Would add alerts for errors, high CPU, connection failures

---

### 7. **Terraform Modular Structure**

**Decision**: 7 modules instead of monolithic main.tf

**Why**:
- **Reusability**: Modules can be reused across environments (dev/staging/prod)
- **Maintainability**: Easier to understand and modify individual components
- **Separation of Concerns**: Database team can work on DB module independently
- **Testing**: Can test modules in isolation

**Modules Created**:
1. `monitoring` - Log Analytics + App Insights
2. `database` - PostgreSQL + firewall rules
3. `security` - Key Vault + secrets
4. `storage` - Static website + Function storage
5. `compute` - Service Plan + Function App
6. `api-gateway` - API Management + API + operations
7. `cdn` - Front Door + origins + routes

---

### 8. **Circular Dependency Resolution**

**Challenge**: CDN needs APIM URL, APIM needs Function hostname, Compute needs APIM IPs, Storage needs CDN URL

**Solution**: 
- Made all cross-module IPs/URLs **optional with defaults**
- APIM CORS set to wildcard `*` (remove CDN hostname dependency)
- Storage uses placeholder API_URL for initial deployment
- Manual update script.js with actual URLs post-deployment

**Trade-off**: Two-stage deployment (initial with placeholders, then update)

---

## Cost Breakdown

| Service | Tier/SKU | Monthly Cost |
|---------|----------|--------------|
| **Azure Functions** | Consumption (Y1) | $0-5 (first 1M executions free) |
| **API Management** | Consumption_0 | $3.50 per million calls (~$3-4) |
| **PostgreSQL** | B_Standard_B1ms | $13 |
| **Front Door** | Standard | $35 + $0.06/GB egress (~$40) |
| **Storage Account** | Standard LRS (×2) | $2 |
| **Key Vault** | Standard | $0.03 per 10K ops (~$1) |
| **Application Insights** | Pay-per-GB | $5-10 |
| **Log Analytics** | Pay-per-GB | $2-5 |

**Total Estimated Cost**: 
- **Low Traffic** (10K API calls/month): ~$53/month
- **High Traffic** (1M API calls/month): ~$130/month

---

## Security Highlights

- ✅ **HTTPS Enforced**: All traffic encrypted in transit (TLS 1.2+)
- ✅ **No Hardcoded Secrets**: All credentials in Key Vault
- ✅ **Managed Identities**: Function App uses System-Assigned Identity (not implemented in demo, but recommended for production)
- ✅ **Network Isolation**: PostgreSQL allows only Azure services + developer IP
- ✅ **Service Principal Auth**: GitHub Actions uses least-privilege SP (Contributor on RG only)

---

## Known Limitations & Future Work

**Current Limitations**:
1. **CORS Wildcard**: APIM allows `*` origin (should restrict to CDN hostname in production)
2. **No VNet Integration**: Public endpoints for all services (acceptable for demo)
3. **No Geo-Redundancy**: Single region (North Europe) deployment
4. **No Auto-Scaling Limits**: Functions can scale unbounded (risk of high costs on attack)

**Production Enhancements** (documented, not implemented):
- Add Action Groups + Metric Alerts for proactive monitoring
- Restrict APIM CORS to specific CDN origin
- Add Rate Limiting policies (e.g., 100 requests/minute per IP)
- Enable Azure DDoS Protection Standard (~$3,000/month)
- Multi-region deployment with Traffic Manager
- Add integration tests to GitHub Actions pipeline

---

## Terraform Architecture

**State Management**: Local state file (terraform.tfstate)  
**Production Recommendation**: Azure Storage Account backend with state locking

**Module Structure**:
- Each module: `main.tf`, `variables.tf`, `outputs.tf`
- Root `main.tf` orchestrates module calls
- Explicit `depends_on` for deployment order

**CI/CD**: GitHub Actions workflow with:
- Terraform init, format, validate, plan, apply
- Triggered on push to main branch
- Service Principal authentication
- Plan-only mode for pull requests

---

## Image Generation Prompt

For AI tools like DALL-E, Midjourney, or Stable Diffusion:

```
Create a professional cloud architecture diagram showing:

1. Top: Multiple users/browsers represented by person icons
2. Globe icon representing "Azure Front Door CDN" with edge locations worldwide
3. Two parallel paths from CDN:
   - Left path: "Static Website" box (blue) with HTML/CSS/JS files icon
   - Right path: "API Management" box (orange) with gateway icon
4. Center: "Azure Functions" box (purple) with lambda/function icon
5. Bottom left: "PostgreSQL Database" cylinder (green)
6. Bottom center: "Key Vault" box (yellow) with lock/key icon  
7. Bottom right: "Application Insights" box (cyan) with chart/graph icon
8. External: "OpenWeather API" cloud icon on the right

Connections:
- Solid arrows: User → Front Door → Static/APIM → Functions → Database
- Dashed arrows: Functions → Key Vault (secrets), Functions → OpenWeather API
- Dotted arrows: All services → App Insights (telemetry)

Style: Modern, clean, professional. Use Microsoft Azure brand colors. 
Include small icons for each service (matching Azure portal icons if possible).
Add layer labels on left: "Edge Layer", "Presentation", "API Gateway", "Compute", "Data & Security"
```

---

## Conclusion

This architecture demonstrates a **cost-optimized, production-ready serverless solution** that balances:
- **Affordability**: ~$53-130/month depending on traffic
- **Scalability**: Auto-scales from 0 to millions of requests
- **Security**: Enterprise-grade secrets management and encryption
- **Observability**: Full APM with Application Insights
- **Maintainability**: Modular Terraform, automated CI/CD

**Key Achievement**: Saved ~$870/month by choosing Consumption tier API Management while maintaining all required functionality.

---

**Document Version**: 2.0 (Concise)  
**Original Version**: 600+ lines → **Current**: ~150 lines
