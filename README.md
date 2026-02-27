# Azure AI Foundry Sample with Secure API Management

> **Disclaimer:** This repository is provided purely as a demonstration of these workflows. You are free to use, modify, and adapt the code as you see fit; however, it is offered as-is with no warranty or support of any kind. Use it at your own risk. This is not production-ready code — it should be reviewed, understood, and rewritten to suit your own environment before any real-world use.

This repository contains Terraform configuration to deploy a secure Azure OpenAI architecture. It demonstrates how to expose a GPT model through Azure API Management (APIM) while keeping the backend AI service completely isolated from the public internet.

## Architecture Overview

The solution deploys the following resources:

*   **Azure OpenAI Service:** Hosts the deployed GPT model.
*   **Azure API Management:** Acts as the secure gateway and entry point for all client requests.
*   **Virtual Network (VNet):** Provides a secure network boundary.
*   **Private Endpoint:** Connects the VNet securely to the Azure OpenAI service.
*   **Private DNS Zone:** Ensures proper DNS resolution for the private endpoint.
*   **Supporting Services:** Storage Account, Key Vault, Application Insights, and Log Analytics for observability.

## Security Posture

This architecture prioritizes security by minimizing public exposure and using identity-based authentication.

### Network Security
*   **Private Backend:** Public network access to the Azure OpenAI service is **disabled**. It can only be accessed via its Private Endpoint.
*   **VNet Integration:**
    *   **APIM:** Deployed in "External" mode within a dedicated subnet (`snet-apim`). This allows it to accept public traffic while having direct access to private resources in the VNet.
    *   **OpenAI:** Connected to the VNet via a Private Endpoint in a dedicated subnet (`snet-pe`).
*   **Traffic Flow:** All traffic between APIM and OpenAI travels over the Microsoft Azure backbone network, never traversing the public internet.

### Authentication & Authorization
*   **Identity-Based Access:** The solution is configured to use Azure Active Directory (Entra ID) tokens.
*   **Token Pass-through:** API Management is configured to pass the client's `Authorization` header (Bearer token) directly to the OpenAI backend.
*   **No Static Keys:** The APIM configuration does not store or inject static API keys for the backend connection, reducing the risk of credential leakage.

### API Policy
*   **CORS:** A Cross-Origin Resource Sharing (CORS) policy is applied to allow safe cross-origin requests from web clients.
*   **Token Limiting:** An `llm-token-limit` policy is configured to manage consumption, limiting usage to 5,000 tokens per minute and 50,000 tokens per hour per IP address.

## Data Path

1.  **Client Request:** A user or application sends an HTTPS request to the public API Management endpoint.
    *   URL: `https://apim-<workload>-<env>-<suffix>.azure-api.net/openai/...`
    *   Header: `Authorization: Bearer <valid-azure-ad-token>`
2.  **Gateway Entry:** The request hits the APIM Gateway.
3.  **DNS Resolution:** APIM, running inside the VNet, queries the `privatelink.cognitiveservices.azure.com` Private DNS Zone to resolve the OpenAI hostname.
4.  **Private Routing:** The DNS zone returns the **Private IP** address of the OpenAI service.
5.  **Backend Access:** APIM forwards the request securely through the VNet to the Private Endpoint of the Azure OpenAI service.
6.  **Response:** The model processes the request and returns the response via the same secure path.

## Deployment

### Prerequisites
*   Azure CLI
*   Terraform
*   An active Azure Subscription

### Steps
1.  Navigate to the `terraform/environments/dev` directory.
2.  Copy the example variables file:
    ```bash
    cp terraform.tfvars.example terraform.tfvars
    ```
3.  Update `terraform.tfvars` with your specific values (e.g., `subscription_id`).
4.  Initialize Terraform:
    ```bash
    terraform init
    ```
5.  Review the plan:
    ```bash
    terraform plan
    ```
6.  Apply the configuration:
    ```bash
    terraform apply
    ```

## Usage

Once deployed, you can access the model using the APIM URL.

**Example Request:**

```http
POST https://<your-apim-name>.azure-api.net/openai/deployments/<deployment-name>/chat/completions?api-version=2024-02-01
Content-Type: application/json
Authorization: Bearer <your-access-token>

{
  "messages": [
    { "role": "user", "content": "Hello, world!" }
  ]
}
```
