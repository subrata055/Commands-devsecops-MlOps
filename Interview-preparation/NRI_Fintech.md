# DevOps Interview — Prep Answers

Practice saying these out loud. Keep the number/result up front where there is one.

---

### 1. What are your day-to-day DevOps activities?
Every morning I check Prometheus and Grafana dashboards for pod/node health and alerts. If something's off, I investigate and fix it; if it's a pipeline failure on the dev side, I flag it to the relevant developer. Rest of the day is split between CI/CD pipeline maintenance, EKS cluster operations, and AWS cost/infra management for our insurance-domain project.

### 2. Have you designed an end-to-end CI/CD pipeline?
Yes — pull code from GitHub, run Trivy for filesystem scanning and SonarQube for code quality/vulnerabilities, build the image, scan the image with Trivy again, push to Docker Hub/ECR, then deploy via ArgoCD (GitOps) or Helm depending on the project. Built and maintained this end-to-end for the insurance client project.

### 3. Have you worked with Azure DevOps?
Limited exposure — my core platform is AWS, so most of my hands-on pipeline work is Jenkins and GitHub Actions with ArgoCD for deployment. I understand Azure DevOps' pipeline/YAML model conceptually and can ramp up quickly, but I can't claim production depth there.
*(Say this plainly — don't oversell it, interviewers respect an honest boundary more than a vague yes.)*

### 4. Have you used AWS CodePipeline?
No, I haven't used CodePipeline directly — my orgs standardized on Jenkins/GitHub Actions for CI and ArgoCD for CD. I understand CodePipeline is AWS's native equivalent (stages: Source → Build → Deploy, integrates with CodeBuild/CodeDeploy) and could pick it up fast given my Jenkins/GitHub Actions background.

### 5. What production issue have you faced, and how did you troubleshoot it?
Two concrete ones: (1) Spot instances in prod caused slowness when spot capacity was unavailable — I moved prod nodes to on-demand while keeping spot for dev/UAT. (2) An EC2 database was costing ~$10K/month — I right-sized it to a Reserved Instance and cut cost to ~$7.5K/month. Both were identified via cost/performance monitoring, not guesswork.

### 6. Have you worked with Terraform?
Yes, though not at deep scale — I've written and used Terraform modules (VPC, EKS, RDS) mainly for provisioning test/dev environments. I'm comfortable with modules, variables, and state, but haven't managed large multi-team Terraform codebases.

### 7. What are Terraform modules?
A module is a reusable, self-contained group of resources — for example a VPC module or an EKS module — parameterized with input variables so the same code can provision different environments without rewriting it.

### 8. How can Terraform modules be reused across multiple environments?
By passing different variable values per environment — e.g. `environment = "dev"` vs `"prod"`, different CIDR ranges, instance sizes, or replica counts — usually via separate `.tfvars` files (dev.tfvars, uat.tfvars, prod.tfvars) calling the same module.

### 9. How did you ensure zero downtime migrating 15 microservices to AWS EKS?
I used a rolling migration: deployed each microservice to EKS via CI/CD while the on-prem version stayed live, verified it was healthy and serving traffic correctly on EKS, then cut over and decommissioned the on-prem instance for that service — one at a time, not a big-bang switch. That way if one service had issues, only that one needed rollback.

### 10. How large is your current environment (microservices, infra, K8s add-ons, applications)?
Around 150 pods across roughly 8-10 microservices, monthly AWS spend ~$7-8K. Stack includes EKS, ALB Ingress Controller, ArgoCD for GitOps deployment, Prometheus/Grafana for monitoring, Redis and RDS for data. Separate frontend/backend for the public-facing site and for internal tooling.

### 11. How do you distinguish and secure separate applications in a Kubernetes cluster?
Namespace-based isolation (prod/UAT/dev, and per-app where needed) combined with NetworkPolicies to restrict cross-namespace traffic, RBAC to scope who/what can access each namespace, and IAM roles for service accounts (IRSA) so pods only get the AWS permissions they actually need.

### 12. How do you segregate applications across Kubernetes namespaces?
Namespaces act as a logical/virtual boundary within the same cluster. I separate by environment (prod, UAT, dev) and sometimes by tier (frontend, backend/API, database) so each has its own resource quotas, RBAC rules, and network policies without needing separate clusters.

### 13. How do you enable communication between services in different Kubernetes namespaces?
By default, cross-namespace communication is allowed — a pod can reach another namespace's service at `<service-name>.<namespace>.svc.cluster.local` unless a NetworkPolicy blocks it. So it's DNS-based service discovery plus explicit NetworkPolicy allow-rules when I want to restrict it.

### 14. What is the difference between ClusterIP and NodePort services?
ClusterIP is a virtual IP reachable only inside the cluster — used for internal pod-to-pod communication. NodePort opens a fixed port (30000-32767) on every node's IP, making the service reachable externally as `<NodeIP>:<NodePort>` — it works, but isn't preferred for production since it lacks built-in load balancing across nodes and exposes node IPs directly.

### 15. Why is an Ingress Controller required if a LoadBalancer service is already available?
A LoadBalancer service provisions one cloud load balancer *per service* — expensive and doesn't support routing rules. An Ingress Controller (I use ALB Controller) lets many services share a single load balancer, with path/host-based routing, SSL termination, and rewrites — all managed declaratively through Ingress resources.

### 16. Why is an Ingress Controller required in Kubernetes?
Because Kubernetes has no native concept of HTTP routing — the Ingress *resource* just declares rules (host/path → service); the Ingress Controller is the actual component (like ALB Controller or NGINX Ingress) that reads those rules and configures the real load balancer to implement them.

### 17. How would you restrict communication between Kubernetes namespaces?
Apply a default-deny-all NetworkPolicy per namespace, then explicitly allow only the traffic needed using `podSelector`/`namespaceSelector` labels — e.g. allow backend namespace to reach the database namespace, but block frontend from reaching the database directly.

### 18. What are best practices for Kubernetes cluster operations (e.g. upgrades)?
Check cluster health first (ArgoCD/Grafana), then before upgrading check API/CRD compatibility for the target version (deprecated API removals break manifests), drain and cordon nodes one at a time rather than all at once, and validate workloads are healthy after each node before moving to the next. AWS console can automate drain/upgrade, but I do it manually for safety in prod.

### 19. How would you write a GitHub Actions workflow (for CI/CD to AWS)?
Set required secrets/credentials (AWS keys, Docker registry) in the repo's environment settings, write a `.yml` workflow under `.github/workflows/` defining triggers (push/PR), then steps: checkout code → build/test → build Docker image → push to ECR/Docker Hub. Actual deployment to EKS is then handled by ArgoCD picking up the new image tag via GitOps.

### 20. Why choose ArgoCD instead of GitHub Actions for deployment?
GitHub Actions is good for CI (build/test/push image) but isn't built for continuously reconciling cluster state. ArgoCD watches the Git repo as the source of truth and continuously syncs the live cluster to match it — including auto-correcting manual drift (e.g. if someone manually scales a deployment, ArgoCD reverts it to match Git).

### 21. Why is GitOps popular, and what are its advantages?
Git becomes the single source of truth for cluster state — every change is version-controlled, auditable, and reviewable via PR. It gives automatic drift correction, easy rollback (just revert the Git commit), and removes the need for anyone to run manual `kubectl apply` commands against prod.
