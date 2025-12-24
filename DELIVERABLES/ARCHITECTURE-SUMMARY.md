# Architecture & Design Decisions

**Project**: Weather Application - Azure Serverless  
**Author**: Daniel Ashkenazy  
**Date**: December 23, 2025

---

## Architecture Overview

The weather application is built on a **fully serverless architecture** leveraging Azure's Platform-as-a-Service (PaaS) offerings. The solution follows a modern cloud-native design pattern where users access a globally-distributed static frontend through Azure Front Door CDN, which serves HTML, CSS, and JavaScript files from an Azure Storage Account. API requests are routed through Azure API Management acting as a secure gateway, which forwards them to Python-based Azure Functions running on a Consumption plan. The Functions retrieve weather data from the OpenWeather API and store historical queries in a PostgreSQL Flexible Server database. All sensitive credentials are securely managed in Azure Key Vault, while Application Insights and Log Analytics provide comprehensive monitoring and observability across the entire stack.

---

## Cost-Driven Decision Making

The primary architectural constraint was **cost optimization** without sacrificing reliability or security. The most significant decision was switching from API Management Standard tier (~$900/month) to Consumption tier (~$3.50 per million API calls), resulting in approximately **$870/month savings** - a 96% cost reduction. Similarly, choosing PostgreSQL's Burstable tier (B_Standard_B1ms at $13/month) over General Purpose tiers ($100+/month) provided sufficient performance for the application's simple query patterns while keeping database costs minimal. The serverless compute model (Azure Functions Consumption plan) further reduces costs by charging only for actual execution time, with the first 1 million executions per month being free. The entire infrastructure runs at an estimated **$53-130/month** depending on traffic volume, making it sustainable for both demo and production scenarios with variable usage patterns.

---

## Serverless vs. Traditional Compute

The decision to adopt a serverless architecture was driven by three key factors: operational simplicity, cost efficiency, and automatic scalability. Traditional alternatives like Azure Kubernetes Service (AKS) or Azure App Service would require dedicated compute resources running 24/7, resulting in baseline costs of $100-300/month even during idle periods. More importantly, these options would require ongoing maintenance (OS patching, cluster management, capacity planning) that adds operational overhead. Serverless architectures eliminate this burden entirely - Azure Functions automatically scale from zero to hundreds of instances based on demand, without any configuration. The trade-off is cold start latency (1-2 seconds on first request), which is acceptable for a weather application where users don't expect sub-second responses. For applications requiring consistent sub-100ms latency or long-running background processes, traditional compute would be more appropriate.

---

## Security Architecture

Security was implemented following a **defense-in-depth** strategy with multiple layers of protection. All credentials (database passwords, OpenWeather API keys) are stored in Azure Key Vault rather than hardcoded in application code or configuration files, ensuring they're encrypted at rest and access-audited. The Function App authenticates to Key Vault using its managed identity (planned for production; demo uses connection strings for simplicity). Network security is enforced through PostgreSQL firewall rules that allow connections only from Azure services and specific developer IPs, preventing unauthorized database access. All traffic is encrypted in transit using TLS 1.2+, enforced at the Front Door and API Management layers. For production deployments, additional hardening would include restricting API Management CORS from wildcard (`*`) to specific CDN origins, implementing rate limiting policies to prevent abuse, and enabling VNet integration to isolate backend services from the public internet entirely.

---

## Infrastructure as Code Philosophy

The entire infrastructure is defined as **Terraform modules** following industry best practices for reusability and maintainability. Rather than a monolithic main.tf file, the codebase is organized into seven specialized modules (monitoring, database, security, storage, compute, api-gateway, cdn), each encapsulating a specific architectural layer. This modular approach enables independent development and testing of components, facilitates code reuse across multiple environments (dev/staging/prod), and improves readability by separating concerns. A significant challenge was resolving circular dependencies between modules - for example, the CDN module needs the API Management URL, but APIM needs the Function hostname, which needs APIM IP restrictions. This was solved by making cross-module parameters optional with sensible defaults (e.g., CORS set to wildcard initially, APIM IPs defaulting to empty list), allowing initial deployment followed by targeted updates.

---

## Observability Strategy

Comprehensive monitoring was integrated from the start using **Application Insights** connected to a Log Analytics workspace. This provides end-to-end request tracing across the entire stack - from the moment a request hits Front Door, through API Management, into the Function execution, and down to database queries. Application Insights automatically captures exceptions, dependency call durations, and custom telemetry without requiring code instrumentation beyond initial configuration. For a production deployment, this foundation would be extended with Action Groups triggering email/SMS alerts on critical conditions (function errors exceeding threshold, database CPU above 80%, connection failures), metric dashboards for business KPIs (API calls per hour, average response time by city), and integration with external monitoring tools like PagerDuty or OpsGenie for 24/7 incident response.

---

## CI/CD Automation

Deployment automation was implemented using **GitHub Actions** to eliminate manual deployment errors and enable rapid iteration. The workflow performs a complete Terraform lifecycle on every push to the main branch: initializing providers, validating syntax, generating an execution plan, and applying changes to Azure. Authentication uses an Azure Service Principal with Contributor permissions scoped to a single resource group, following the principle of least privilege. The pipeline outputs deployment URLs (frontend, API gateway) directly in the GitHub Actions summary, making it easy to access the deployed application. For pull requests, the workflow runs in plan-only mode to preview changes without applying them, enabling code review of infrastructure modifications. This automated approach reduces deployment time from 30+ minutes of manual steps to under 10 minutes of hands-off execution.

---

## Trade-offs and Lessons Learned

Every architectural decision involved trade-offs between competing priorities. Choosing serverless compute meant accepting cold start latency in exchange for cost savings and zero operational overhead - a worthwhile trade-off for an application with intermittent traffic. Using API Management Consumption tier saved substantial costs but introduced ~1-2 second cold starts on the first API call after idle periods; however, for weather queries, users expect results in seconds rather than milliseconds, making this latency imperceptible. The PostgreSQL Burstable tier provides cost-effective storage but isn't suitable for sustained high-CPU workloads; since weather queries are simple lookups, this limitation doesn't impact the application. The most challenging aspect was resolving circular dependencies between Terraform modules, which required making parameters optional and accepting a two-stage deployment process (initial deployment with placeholders, followed by updates with actual values). In retrospect, using Terraform workspaces or remote state with data sources could have simplified this, though the current approach works reliably for this project scope.

---

**Summary**: This architecture demonstrates that production-grade applications can be built cost-effectively (~$53/month) using serverless technologies, modern IaC practices, and thoughtful decision-making that balances cost, performance, security, and maintainability.
