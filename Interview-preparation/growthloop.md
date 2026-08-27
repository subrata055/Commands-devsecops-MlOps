# DevOps Interview — Prep Answers (Set 2)

---

### 1. Please introduce yourself.
I'm a DevOps engineer with 4+ years of experience in AWS, Kubernetes, and CI/CD automation. Currently at Navigator Software, where I manage infrastructure and deployments for an insurance-domain client — including EKS clusters, CI/CD pipelines, and AWS cost optimization. Before that I worked at Unified Infotech, focused on CI/CD pipelines, SonarQube, and security scanning with Trivy. I hold AWS Certified Solutions Architect and CKA certifications.

### 2. What experience do you have with AWS, Azure, Kubernetes, Jenkins, and Terraform?
AWS is my primary platform — EKS, EC2, RDS, ALB, IAM — used daily in production. Kubernetes and Jenkins I use hands-on for cluster ops and CI pipelines. Terraform I've used for provisioning modules (VPC, EKS, RDS) mainly in dev/test. Azure exposure is limited — conceptual understanding, not production depth.

### 3. Can you describe your current role and project?
I'm a DevOps engineer at Navigator Software on an insurance-domain client project. I own the AWS infrastructure, CI/CD pipelines, EKS cluster, and databases end-to-end — from code being pushed to GitHub through to production deployment and monitoring.

### 4. What are your current DevOps responsibilities?
Daily monitoring via Prometheus/Grafana, maintaining CI/CD pipelines (GitHub Actions → Trivy/SonarQube → ArgoCD), managing the EKS cluster and its upgrades, AWS cost optimization, and being the escalation point when a developer's deployment fails.

### 5. What is your experience with Docker and Kubernetes?
Docker: building and scanning images as part of the CI pipeline, pushing to ECR/Docker Hub. Kubernetes: running production EKS clusters — deployments, namespaces, Ingress/ALB Controller, NetworkPolicies, node upgrades and drains, and GitOps-based deployment via ArgoCD.

### 6. Can you explain your application architecture?
A microservices architecture on EKS — separate frontend and backend services, Redis for caching, RDS for the database, all fronted by an ALB Ingress Controller. Roughly 8-10 microservices totaling ~150 pods, split across production, UAT, and dev namespaces.

### 7. Is the application monolithic or microservices-based?
Microservices — each service (frontend, backend, cache, DB-facing services) is deployed and scaled independently in its own set of pods within EKS.

### 8. How do you manage namespaces across EKS clusters?
Namespaces are split by environment — production, UAT, development — each with its own NetworkPolicies and RBAC. Within an environment, I sometimes further separate by tier, e.g. frontend namespace vs backend/API namespace, so failures or resource limits in one don't affect another.

### 9. How do the frontend and backend communicate?
Internally via Kubernetes Service DNS — the frontend calls the backend's ClusterIP service name (`backend-svc.namespace.svc.cluster.local`) rather than a hardcoded IP, so it stays stable even as pods are rescheduled.

### 10. Are the workloads deployed in public or private subnets?
Application pods (frontend, backend, database) run in private subnets for security — only the load balancer sits in the public subnet and forwards traffic in. This limits direct internet exposure of the actual workloads.

### 11. How do you expose the frontend?
Through an ALB provisioned by the AWS Load Balancer Controller via an Ingress resource — the ALB sits in the public subnet and routes incoming traffic to the frontend service running in the private subnet.

### 12. Do you still need a NAT Gateway when using a load balancer?
Yes — a load balancer only handles *inbound* traffic to your pods. A NAT Gateway is needed for *outbound* traffic — private-subnet pods pulling images, calling external APIs, or hitting AWS services still need a NAT Gateway to reach the internet.

### 13. What is the difference between an ALB and an NLB?
ALB operates at Layer 7 (HTTP/HTTPS) — supports path/host-based routing, SSL termination, ideal for web apps. NLB operates at Layer 4 (TCP/UDP) — ultra-low latency, handles millions of requests, used for non-HTTP traffic or when you need a static IP. I use ALB for the web-facing frontend since I need path-based routing.

### 14. What would you use for internal communication?
ClusterIP services for pod-to-pod traffic within the cluster — no need for a load balancer internally since Kubernetes' own service discovery (DNS + kube-proxy) handles routing between services in the same cluster.

### 15. Do you have experience with Amazon ECS?
Limited — my production experience is EKS-focused. I understand ECS's task/service model conceptually (simpler than Kubernetes, tightly integrated with AWS) but haven't run it in production.

### 16. How much experience do you have with ECS and Fargate?
Minimal hands-on — I know Fargate removes the need to manage EC2 nodes by running containers serverlessly, which is useful for lighter workloads, but my day-to-day depth is in EKS, not ECS/Fargate.

### 17. Do you have experience with GitHub and GitHub Actions?
Yes — I use GitHub for source control and GitHub Actions for CI: build, test, scan (Trivy/SonarQube), and push the Docker image. Deployment itself is handled by ArgoCD via GitOps, not directly by the Actions workflow.

### 18. What is the flow for building a Docker image and pushing it to ECR from GitHub?
GitHub Actions triggers on push → checkout code → authenticate to AWS/ECR → `docker build` the image → tag it with the commit SHA or version → `docker push` to the ECR repository. ArgoCD then picks up the new image tag and syncs it to the cluster.

### 19. What credentials are required to push an image to ECR?
AWS credentials with ECR push permissions — traditionally an IAM user's access key/secret key stored as GitHub Secrets, used to run `aws ecr get-login-password` to authenticate Docker to the registry.

### 20. What is the industry-recommended authentication method?
Short-lived, temporary credentials rather than long-lived static access keys — using OIDC federation so GitHub Actions assumes an IAM role directly, with no stored secrets at all.

### 21. Are you familiar with OIDC?
Yes — OpenID Connect lets GitHub Actions request a signed token from GitHub's OIDC provider, which AWS trusts to grant temporary role credentials via `sts:AssumeRoleWithWebIdentity` — so no static AWS keys need to be stored in GitHub Secrets at all.

### 22. Can OIDC be used for deployment?
Yes — the same OIDC-to-IAM-role pattern used for pushing to ECR can be used to grant the pipeline temporary permissions to deploy — e.g. updating an ECS service, or in a GitOps setup, just to push the updated manifest/image tag to Git, with ArgoCD handling the actual cluster sync.

### 23. What other short-term authentication methods can be used?
AWS STS `AssumeRole` with short session durations, IAM Roles Anywhere for non-AWS workloads needing temporary AWS credentials, and IRSA (IAM Roles for Service Accounts) inside EKS so pods themselves get scoped temporary credentials instead of long-lived keys mounted as secrets.
