# EPAM DevOps Interview Prep

Answers kept to 1-4 lines. Follow-ups the interviewer is likely to ask are noted under *Follow-up:*.

---

## Set 1 — Kubernetes, Terraform, AWS, Docker, Linux, Scripting

### Kubernetes

**1. How to create and use Custom Resources in Kubernetes?**
Define a CustomResourceDefinition (CRD) that registers a new API type (e.g. `kind: Database`) with the API server. Then create instances of it as normal YAML manifests. A Custom Controller/Operator watches these objects and reconciles real infra to match the desired spec.
*Follow-up: What's the difference between a CRD and an Operator?* → A CRD just defines the schema/API. An Operator is the controller logic (usually a pod running a reconcile loop) that actually acts on those custom objects.

**2. What are namespaces in K8s?**
Logical partitions within a single cluster used to isolate resources — by team, environment, or app — so names don't collide and RBAC/quotas/network policies can be scoped per namespace.

**3. What is the difference between Deployment and StatefulSet?**
Deployment manages stateless, interchangeable pods with random names/IPs — good for web/API tiers. StatefulSet gives pods stable identities, stable names (`pod-0`, `pod-1`), stable storage (PVC per pod), and ordered start/stop — used for databases, Kafka, etc.

**4. What is Role-Based Access Control (RBAC)?**
A permission model where `Role`/`ClusterRole` define a set of allowed actions on resources, and `RoleBinding`/`ClusterRoleBinding` attach that role to a user, group, or service account — scoped to a namespace or cluster-wide.

**5. What is Cluster Autoscaler and Horizontal Pod Autoscaler?**
Cluster Autoscaler adds/removes **nodes** based on whether pods are unschedulable due to resource shortage. HPA adds/removes **pod replicas** based on CPU/memory/custom metrics. They work together — HPA scales pods first, Cluster Autoscaler scales nodes when there's no room left for those pods.

### Terraform

**6. What is a provider?**
A plugin that lets Terraform talk to a specific platform's API (AWS, Azure, GCP, Kubernetes) — it translates your `.tf` resource blocks into actual API calls.

**7. How do you manage state in Terraform?**
State is a JSON file tracking what Terraform believes exists in real infra. I store it remotely (S3 + DynamoDB for locking, or Terraform Cloud) rather than locally, so teams share consistent state and avoid conflicts.

**8. Do you store the statefile locally or remotely? What block do you use?**
Remotely, using a `backend` block, e.g.:
```hcl
terraform {
  backend "s3" {
    bucket         = "my-tf-state"
    key            = "prod/network.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-lock-table"
    encrypt        = true
  }
}
```

**9. What is a Terraform module?**
A reusable, self-contained set of resources parameterized by input variables — e.g. a VPC or EKS module — so the same code can be called multiple times with different inputs.

**10. How do you manage multiple environments in Terraform?**
Either separate `.tfvars` files per environment (dev.tfvars, prod.tfvars) calling the same module with different values, or separate Terraform workspaces, or fully separate state files/directories per environment for stronger isolation.

### AWS

**11. What is CloudWatch used for?**
Centralized metrics, logs, and alarms — I use it for EC2/RDS/EKS metrics, Lambda logs, custom application metrics, and alarms that trigger SNS notifications or auto-scaling actions.

**12. What is ECS and EKS?**
Both are container orchestrators on AWS. ECS is AWS's own simpler, proprietary scheduler. EKS is managed Kubernetes — same K8s API you'd use anywhere, just with AWS managing the control plane.

**13. What is Fargate?**
Serverless compute for containers — runs ECS or EKS pods without you provisioning or managing EC2 nodes; you pay per task/pod resource usage instead of per instance.

**What are the limitations of Lambda?**
15-minute max execution time, 10GB memory cap, cold starts add latency, limited to specific runtimes (or custom containers), and 512MB-10GB ephemeral `/tmp` storage limit.

**14. How does Lambda work with containers?**
Lambda can run a container image (up to 10GB) instead of a zip — the image must implement the Lambda Runtime API; Lambda pulls the image from ECR and executes it in its managed environment on invocation.

**15. What is an EC2 instance?**
A virtual machine in AWS — you choose CPU/memory (instance type), storage (EBS), and networking (VPC/subnet), and AWS handles the underlying hypervisor/hardware.

**16. What is AWS Direct Connect?**
A dedicated, private physical network connection from your on-prem datacenter to AWS — bypasses the public internet for lower latency, higher bandwidth, and more consistent performance than a VPN.

**17. What is AWS Storage Gateway?**
A hybrid storage service connecting on-prem applications to AWS storage (S3, EBS, Glacier) — used for backup, archiving, or extending on-prem storage into the cloud without rewriting applications.

**18. VPC, NAT Gateway, S3, Route 53, VPC Peering, Transit Gateway, Auto Scaling Group — one line each:**
- **VPC** — your isolated private network in AWS.
- **NAT Gateway** — lets private-subnet resources reach the internet outbound without being reachable inbound.
- **S3** — object storage, not a filesystem, accessed via API/HTTPS.
- **Route 53** — AWS's DNS + domain routing service (also does health checks, failover routing).
- **VPC Peering** — direct 1-to-1 private network connection between two VPCs.
- **Transit Gateway** — a central hub connecting many VPCs/on-prem networks without needing full-mesh peering.
- **Auto Scaling Group** — automatically adds/removes EC2 instances based on load or schedule.

**19. Difference between Security Group and NACL?**
Security Group is stateful, applied at the instance/ENI level, allow-rules only. NACL is stateless, applied at the subnet level, and supports both allow and deny rules — used as a second layer of defense.

### Docker

**20. Difference between COPY and ADD?**
COPY just copies files/directories from build context into the image. ADD does that plus extra features — auto-extracts tar archives and can fetch remote URLs. Best practice: use COPY unless you specifically need ADD's extra behavior.

**21. Difference between CMD and ENTRYPOINT?**
ENTRYPOINT defines the fixed executable that always runs. CMD provides default arguments (to ENTRYPOINT) or a default command — CMD is easily overridden at `docker run`, ENTRYPOINT is not (without `--entrypoint`).

**22. What is `docker run` vs `docker exec`?**
`docker run` creates and starts a **new** container from an image. `docker exec` runs a command inside an **already running** container — commonly used to get a shell into a live container for debugging.

### Linux

**23. What's inside `/var` and `/opt`?**
`/var` holds variable data that changes at runtime — logs (`/var/log`), spool/cache, mail. `/opt` holds optional, self-contained third-party/add-on software packages that don't follow the standard Linux filesystem layout.

### Scripting

**24. Search for 'error' and 'warning' patterns in test.log, store each in separate files, log file passed as argument:**
```bash
#!/bin/bash
LOGFILE="$1"
grep -i "error" "$LOGFILE" > error.log
grep -i "warning" "$LOGFILE" > warning.log
```
Run as: `./script.sh test.log`

---

## Set 2 — AWS Networking, Load Balancing, EKS Operations (7 YOE)

**1. Difference between ALB and NLB?**
ALB works at Layer 7 (HTTP/HTTPS) — supports path/host-based routing. NLB works at Layer 4 (TCP/UDP) — ultra-low latency, handles millions of requests/sec, preserves source IP, used for extreme performance or non-HTTP traffic.

**2. Purpose of a VPC Endpoint, with use case?**
Lets resources in a VPC privately reach AWS services (S3, DynamoDB, etc.) without going over the public internet or through a NAT Gateway. Use case: an EC2 in a private subnet needs to read from S3 without internet access — a Gateway VPC Endpoint for S3 solves it securely and cheaper than NAT.

**3. Is it possible to get AMI details from a snapshot?**
Not directly the other way — a snapshot doesn't inherently store AMI metadata unless it was originally created *from* one. But you can create a **new AMI from an existing snapshot** (register it as a root volume), which is a common recovery technique.

**4. How to check Load Balancer health details via AWS monitoring?**
CloudWatch metrics for the ALB/NLB (HealthyHostCount, UnHealthyHostCount, TargetResponseTime, HTTPCode_Target_5XX_Count) plus the Target Group's health check status in the EC2 console.

**Different types of instance profiles?**
An instance profile is a container that passes an IAM role to an EC2 instance. There isn't a "type" hierarchy beyond that — the profile just wraps a single IAM role granting the instance specific permissions (e.g. S3 read-only role, full admin role).

**5. AMI vs Snapshot?**
A Snapshot is a point-in-time backup of a single EBS volume's data. An AMI is a full template to launch an EC2 instance — includes root volume snapshot(s) plus launch metadata (instance type compatibility, block device mapping).

**6. Dev team changed AMI in ASG launch template — how do you verify the new version deploys properly?**
Do an instance refresh with a rolling strategy (min healthy percentage set below 100%) so new instances launch gradually, pass health checks, and old ones terminate only after new ones are healthy — monitor via ASG activity history and target group health before letting it complete fully.

**7. Is 170.90.00.9/0 a public or private IP? / How to tell if a given IP is public or private?**
Private IP ranges are defined by RFC1918: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`. Anything outside those ranges is public. (Note: `/0` isn't a valid host mask for a single IP — that's likely a typo in the question; check for `/32` or no prefix.)

**8. 192.90.90.88/12 — private or public?**
`192.x` is only private within `192.168.0.0/16`. `192.90.x` falls outside that RFC1918 block, so it would be a **public** IP (the `/12` prefix here doesn't match a private range either).

**9. Transit Gateway (TGW) in AWS?**
A managed hub that connects multiple VPCs and on-prem networks through a single gateway, avoiding full-mesh VPC peering — routing between attachments is controlled via TGW route tables.

**10. After connecting VPCs via TGW, how do you block A→B and B→C traffic?**
Use separate TGW route tables per VPC attachment (segmented routing) so A's route table doesn't include a route to B, and B's doesn't include a route to C — while still allowing whatever routes you *do* want. NACLs/Security Groups can reinforce this at the VPC level.

**11. EC2 in a private subnet needs inbound traffic, without a NAT Gateway — how?**
NAT Gateway is only for outbound. For inbound, put a Load Balancer (ALB/NLB) in a public subnet that forwards to the private EC2, or use a Bastion/VPN/Direct Connect for admin access, or VPC Peering/TGW if traffic originates from another VPC.

**12. How to enable tight security on a Load Balancer?**
Restrict Security Group inbound to only required ports/sources, enable HTTPS with ACM certs and disable weak TLS policies, attach a WAF, enable access logging to S3, and use a private (internal) LB when public exposure isn't needed.

**13. Can multiple LBs be added to a single web app's different sub-pages?**
Not typically needed — use one ALB with path-based routing rules to send different paths to different Target Groups/services. Multiple LBs are usually for different domains or isolation requirements, not sub-pages of the same app.

**14. What is EC2 UserData?**
A bootstrap script (bash, cloud-init) passed at launch that runs automatically on first boot — used to install packages, join a cluster, or pull config without baking it into the AMI.

**15. How to segregate critical details from VPC Flow Logs?**
Ship flow logs to CloudWatch Logs or S3, then use CloudWatch Logs Insights (or Athena if in S3) to filter by fields like `action=REJECT`, specific `srcaddr`/`dstaddr`, or high `bytes` — isolating denied traffic or traffic to/from sensitive subnets.

**16. Fargate vs EKS worker nodes?**
Fargate: serverless, AWS manages the underlying compute per-pod, no node patching, slightly higher cost per pod. EKS worker nodes (EC2): you manage the nodes yourself — more control (DaemonSets, custom AMIs, GPU instances) but you own patching/scaling of the nodes.

**17. How do you update an EKS cluster?**
Upgrade control plane version first (one minor version at a time via console/CLI), then update node groups (or trigger a rolling AMI update), draining/cordoning nodes gradually, and finally update core add-ons (CoreDNS, kube-proxy, VPC CNI) to match the new version.

**18. ASG under heavy load takes 2-3 min to provision because it's terminating old instances first — how to avoid?**
Check the scaling policy — this suggests a "terminate-then-launch" style refresh instead of scale-out. Switch to a scale-out policy that launches new instances immediately on high demand, and consider a "warm pool" of pre-initialized instances to cut boot time.

**19. Heavy traffic daily between 5-8 PM — how to configure ASG for this?**
Use a **scheduled scaling policy** on the ASG to pre-emptively raise min/desired capacity just before 5 PM and scale back down after 8 PM, layered on top of a normal target-tracking policy for unexpected spikes.

**20. Can two different CIDR blocks (172.x and 192.x) exist in the same VPC?**
Yes — AWS allows adding secondary CIDR blocks to a VPC, so you can have `172.16.0.0/16` as primary and `192.168.0.0/16` as a secondary block in the same VPC.

**21. Customizing WAF?**
Create custom rules (rate-based, SQLi/XSS managed rule groups, IP allow/block lists, geo-match), combine into a Web ACL with rule priority order, and attach it to CloudFront/ALB/API Gateway.

**22. CloudFront configuration basics?**
Define an origin (S3, ALB, custom), set caching behavior (TTL, cache keys, headers/cookies to forward), attach a certificate for custom domain HTTPS, and optionally attach WAF and configure origin access control for private S3 origins.

**23. AWS Image Builder?**
A service to automate building, testing, and maintaining golden AMIs (or container images) on a schedule — bakes in patches/hardening so you don't manually update AMIs.

**24. Different types of EC2 instances?**
General purpose (T/M series), Compute optimized (C series), Memory optimized (R/X series), Storage optimized (I/D series), Accelerated computing (P/G series for GPU). Chosen based on workload's CPU:memory:IO ratio.

**25. How to view VPC Flow Logs stored in an S3 bucket?**
Query them with Athena (create a table over the S3 path) or CloudWatch Logs Insights if also streamed there, or download and grep for ad-hoc analysis — Athena is the standard method for larger volumes.

**26. API Gateway configuration basics?**
Define resources/routes (REST or HTTP API), integrate each with a backend (Lambda, HTTP endpoint, AWS service), configure authorizers (IAM, Cognito, Lambda authorizer) for auth, set up stages for versioning, and enable throttling/caching as needed.

**27. Difference between private and public IPs?**
Private IPs (RFC1918 ranges) are only routable within a private network and not reachable from the internet. Public IPs are globally routable and internet-reachable.

**28. Spot vs Reserved Instances?**
Spot: unused AWS capacity at up to 90% discount, but can be reclaimed with short notice — good for stateless/fault-tolerant workloads. Reserved: 1-3 year commitment for a discount (~40-60%) on guaranteed capacity — good for steady-state, predictable workloads.

---

## Set 3 — Architecture & Advanced Scenarios (6 YOE)

*These are open-ended design questions — keep the 1-4 line version as your spoken opener, then expand if they probe further.*

**1. Design a scalable, HA CI/CD system for microservices across multiple teams**
Per-team pipeline templates (shared reusable workflow/library) feeding a common GitOps repo, with ArgoCD ApplicationSets to manage many services declaratively. Centralize secrets (Vault), enforce policy-as-code checks in the pipeline, and keep build agents auto-scaled and stateless.

**2. Cross-region Terraform deployments in multi-cloud**
Separate state per region/cloud (workspace or backend key per region), use provider aliases for multi-region/multi-cloud resources in the same config, and orchestrate apply order via a pipeline (e.g. region A before B) with remote state data sources for cross-region references.

**3. Implement GitOps in Kubernetes**
Git repo as source of truth for manifests/Helm charts; ArgoCD or Flux continuously reconciles cluster state to match Git; changes go through PR review, merge triggers automatic sync, manual cluster drift gets auto-reverted.

**4. Fully automated blue-green deployment in K8s microservices**
Run two identical environments (blue=live, green=new version) as separate Deployments/Services; deploy and test green fully before switching the Service selector/Ingress to route traffic to green; keep blue running briefly for instant rollback. Tools like Argo Rollouts automate this switch and rollback.

**5. End-to-end DevSecOps pipeline for a fintech app (PCI-DSS)**
SAST (SonarQube) and dependency scanning (Snyk/Trivy) at commit, secrets scanning pre-commit, container image scanning before push, policy-as-code gates (OPA) before deploy, signed images (cosign), and full audit logging of every pipeline action for compliance evidence.

**6. Best practices for pipeline-as-code in large distributed teams**
Shared reusable pipeline templates/libraries (not copy-pasted YAML per repo), version-pin the templates, enforce via required PR checks, and keep environment-specific config out of the pipeline logic (inject via variables/secrets store).

**7. Dynamically provision ephemeral dev/test environments via pipelines**
On PR open, trigger a pipeline stage that spins up a namespace (or short-lived cluster) via Terraform/Helm using the PR number as a unique identifier, auto-destroy on PR close/merge via a cleanup job or TTL controller.

**8. Monorepo — build/deploy only relevant services**
Use path-based change detection (e.g. `git diff` against base branch, or tools like Nx/Turborepo/Bazel) to determine which service directories changed, and trigger only those services' build/deploy jobs.

**9. Canary deployment with real-time monitoring rollback**
Argo Rollouts or Flagger shifts a small % of traffic to the new version, watches Prometheus metrics (error rate, latency) against a threshold during each step, auto-promotes if healthy or auto-rolls-back if metrics breach threshold.

**10. Manage secrets/config securely at scale without breaking GitOps**
Never commit plaintext secrets to Git — use Sealed Secrets or External Secrets Operator pulling from Vault/AWS Secrets Manager, so Git only stores encrypted or reference values while the operator injects real secrets at runtime.

**11. Kubernetes control plane components & hardening for production**
Components: API server, etcd, scheduler, controller-manager (plus cloud controller manager). Hardening: encrypt etcd at rest, restrict API server access via private endpoint + RBAC, enable audit logging, rotate certs, run control plane in isolated/managed mode (EKS/AKS handle much of this).

**12. Scale a K8s cluster horizontally across regions with zero-downtime upgrades**
Typically means multiple regional clusters behind a global load balancer/DNS (not one cluster spanning regions, since etcd needs low latency) — upgrade one cluster at a time while the global LB routes traffic to the others, then roll to the next.

**13. What is a PodDisruptionBudget?**
Defines the minimum number/percentage of pods that must stay available during voluntary disruptions (node drains, upgrades) — Kubernetes won't evict pods below that threshold, protecting critical workloads during maintenance.

**14. Implement network policies for strict inter-service communication**
Default-deny-all NetworkPolicy per namespace, then explicit allow rules per service pair using label selectors — e.g. only `frontend` pods can reach `backend` on port 8080, only `backend` can reach `db`.

**15. Refactor legacy Terraform for DRY/modularity**
Extract repeated resource blocks into shared modules with variables, move environment differences into `.tfvars`, split a monolithic state into smaller state files by domain (network, compute, data) to reduce blast radius and speed up plans.

**16. Terraform dependency/graph internals during planning**
Terraform builds a DAG (directed acyclic graph) from resource references (implicit dependencies) and explicit `depends_on`; it walks the graph to determine safe parallel/sequential order for create/update/destroy operations.

**17. Manage/isolate Terraform state across environments and teams**
Separate state files per environment (and often per domain) using distinct backend keys or workspaces, restrict access via IAM policies on the S3 bucket/DynamoDB table per team, and use remote state data sources for cross-referencing outputs.

**18. Strategy for a corrupted/deleted remote backend state file**
Prevent it first: enable S3 versioning + MFA delete on the state bucket. If it happens: restore from the previous S3 version, or worst case rebuild state with `terraform import` for each resource against real infra.

**19. Policy-as-code with Terraform (Sentinel/OPA) — real use case**
Enforced a rule that no S3 bucket could be created without `encryption` and `public access block` set, using OPA/Conftest in the CI pipeline against the Terraform plan JSON — plan fails the pipeline if the policy is violated.

**20. Centralized logging across multiple cloud platforms**
Ship logs from each cloud's native agent (CloudWatch agent, Azure Monitor agent) into a common backend — either a hosted ELK/OpenSearch stack or a SaaS tool (Datadog, Grafana Loki) — normalize log format at ingestion for consistent querying.

**21. Securing DevOps infra with Identity Federation (Azure AD + AWS IAM)**
Set up Azure AD as a SAML/OIDC identity provider trusted by AWS IAM, so engineers assume AWS roles using their existing Azure AD login (via IAM Identity Center) instead of separate AWS credentials — centralizes access control and offboarding.

**22. Workload identity federation: GitHub Actions ↔ Google Cloud/Azure**
Configure an OIDC trust between GitHub Actions and the cloud provider (Workload Identity Federation in GCP, Federated Credentials in Azure) so the pipeline gets short-lived tokens tied to the specific repo/workflow — no long-lived cloud secrets stored in GitHub.

**23. Cost-efficient auto-scaling for CI/CD under high workloads**
Use ephemeral, auto-scaled build agents (spot instances or Fargate-based runners) that scale to zero when idle, and cache dependencies/layers aggressively to reduce build time (and thus compute cost) per run.

**24. Disaster Recovery strategy for DevOps infrastructure**
Multi-region backup of Terraform state, IaC stored in Git (so infra is fully reproducible from code), regular automated DR drills (spin up in secondary region from IaC), and RTO/RPO defined per critical system with backups tested, not just taken.

**25. Enforce compliance/auditability across global regions (GDPR/HIPAA)**
Region-pin data storage/processing per compliance requirement, enable full audit trails (CloudTrail/Azure Activity Log) shipped to a tamper-evident log store, and gate deployments with policy-as-code checks specific to each region's regulatory requirement.

**26. Container image security across all pipeline stages**
Scan base images and dependencies at build (Trivy/Snyk), sign images (cosign) after build, enforce an admission controller (Kyverno/OPA Gatekeeper) that only allows signed, scanned images to run in the cluster, and continuously rescan images already running for new CVEs.

**27. Runtime threat detection in Kubernetes (Falco/Sysdig)**
Deploy Falco as a DaemonSet monitoring syscalls against a ruleset (e.g. shell spawned in a container, unexpected outbound connection); alerts route to Slack/PagerDuty or trigger automated response (kill pod, isolate node).

---

## Miscellaneous / Rapid-fire

**1.  What are Availability Sets (Azure)?**
A way to spread VMs across multiple physical **Fault Domains** (separate power/network) and **Update Domains** (patched at different times) within a datacenter, so a hardware failure or maintenance reboot doesn't take down all instances of an app at once.

**2. "You have 5 domains which are all interrelated" — likely referring to Update Domains in an Availability Set?**
By default Azure Availability Sets use 5 Update Domains — Azure updates/reboots one Update Domain at a time, so VMs spread across all 5 ensure at least some remain up during platform maintenance.

**3. Pod is in CrashLoopBackOff and logs show nothing — how do you troubleshoot?**
`kubectl describe pod` to check Events (OOMKilled, failed probes, image pull errors). Check previous container logs with `kubectl logs <pod> --previous`. If still nothing, check the container's entrypoint/command for silent exits, and verify resource limits aren't killing it before it can log.

**4. How do you configure a monitoring solution?**
Deploy Prometheus (via kube-prometheus-stack/Helm) to scrape metrics from nodes, pods, and app `/metrics` endpoints; Grafana for dashboards on top of that; Alertmanager for routing alerts to Slack/PagerDuty based on defined thresholds.

**5. What are probes in Kubernetes?**
Liveness probe (restarts the container if it fails — app is stuck), Readiness probe (removes pod from Service endpoints if not ready to serve traffic), Startup probe (delays the other two until slow-starting apps are fully up).

**6. How do you deploy 10 pods on all nodes at the same time?**
Use a **DaemonSet** — it ensures exactly one (or a defined number via replicas isn't applicable, but you can run multiple containers per pod) copy of a pod runs on every node automatically, including new nodes as they join.

**7. What are Terraform taints?**
`terraform taint <resource>` marks a resource for forced destroy-and-recreate on the next apply, without changing its config — useful when a resource is broken/corrupted outside Terraform's knowledge. (Note: newer Terraform versions favor `terraform apply -replace=<resource>` instead of `taint`.)

**8. Terraform meta-arguments beyond `for_each` and `count`?**
`depends_on` (explicit dependency), `lifecycle` (`create_before_destroy`, `prevent_destroy`, `ignore_changes`), and `provider` (select a specific provider alias for a resource).

**9. Can `for_each` and `count` be used together on the same resource?**
No — Terraform disallows using both on the same resource block; you must pick one.

**10 . What is fine-tuning in AI?**
Taking a pre-trained model and continuing training it on a smaller, task/domain-specific dataset so it adapts its weights to perform better on that specific use case, without training a model from scratch.

**11. Two sites connected over Site-to-Site VPN, connection broken — how do you troubleshoot?**
Check the VPN tunnel status in the console (down/up, which phase — IKE Phase 1 or 2 failing), verify the customer gateway's public IP hasn't changed, check route tables/BGP routes are propagating, confirm Security Groups/NACLs/on-prem firewall allow the VPN traffic, and check for a pre-shared key or config mismatch.

**12. 100 applications need a common rule applied — how do you do this from the cloud side?**
Apply it centrally rather than per-app — e.g. a shared Security Group all 100 apps attach to, an Organization-level SCP, a central WAF Web ACL associated with all their ALBs, or a policy-as-code rule enforced in the deployment pipeline so it's automatically applied to every new app.

**13. Zero-shot prompting?**
Asking a model to perform a task with no examples given — just the instruction — relying entirely on its pre-trained knowledge to infer what's wanted.

**14. Few-shot prompting?**
Providing a small number of example input/output pairs in the prompt before the actual task, so the model can pattern-match the expected format/style from those examples.

**15. Features of Network Watcher — is it usable globally?**
Azure Network Watcher provides diagnostics: IP flow verify, NSG flow logs, connection troubleshoot, packet capture, topology view. It's **region-scoped** — you need it enabled per region where your resources live, not a single global instance.

**16. Difference between StatefulSet and Deployment?** *(see Set 1 answer above — same question repeated)*

**17. How to configure monitoring via Log Analytics?**
Deploy the Azure Monitor Agent (or legacy Log Analytics agent) to VMs/AKS, point it at a Log Analytics Workspace, define Data Collection Rules for what to collect, then query with KQL and build alerts/workbooks on top.

**18. How do you use Prometheus and Grafana?**
Prometheus scrapes metrics from configured targets (exporters, `/metrics` endpoints) on a pull model and stores them as time-series data. Grafana connects to Prometheus as a data source and visualizes those metrics in dashboards, with alerting rules layered on top.

**19. Terraform: deploy Azure storage accounts based on environment (2 for dev, 5 for prod)**
```hcl
variable "environment" {
  type = string
}

locals {
  storage_count = var.environment == "prod" ? 5 : 2
}

resource "azurerm_storage_account" "this" {
  count                    = local.storage_count
  name                     = "st${var.environment}${count.index}"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
```

**20. Shell script: extract log entries containing 'ERROR' for the current date**
```bash
#!/bin/bash
LOGFILE="$1"
TODAY=$(date +"%Y-%m-%d")
grep "$TODAY" "$LOGFILE" | grep "ERROR" > error_today.log
```

**21. Shell script: print numbers divisible by 3 or 5, but not 15, within a range**
```bash
#!/bin/bash
START=$1
END=$2
for ((i=START; i<=END; i++)); do
  if (( (i % 3 == 0 || i % 5 == 0) && i % 15 != 0 )); then
    echo "$i"
  fi
done
```

**22. Explain RBAC in Kubernetes** *(see Set 1 answer above)*

**23. How to write variables in a pipeline (Azure DevOps)?**
Define them in the pipeline YAML under a `variables:` block, or set them as pipeline/library variable group in the UI (for secrets), and reference with `$(variableName)` in steps.

**24. How to run Terraform in a pipeline?**
Add stages/steps: `terraform init` (with backend config), `terraform plan -out=tfplan` (often gated for manual approval on prod), then `terraform apply tfplan` — using a service connection/OIDC for cloud credentials rather than hardcoded secrets.

**25. Difference between Classic and YAML pipelines (Azure DevOps)?**
Classic is a GUI-based, click-through pipeline editor with no version control by default. YAML pipelines are defined as code (`azure-pipelines.yml`) checked into the repo — versioned, reviewable via PR, and reusable via templates. YAML is the current best practice.

**26. What's the difference between a Service Endpoint (networking) and a Private Endpoint (Azure)?**
Service Endpoint keeps traffic to a PaaS service (e.g. Storage) on the Azure backbone but the service still has a public IP reachable from allowed VNets. Private Endpoint assigns the PaaS service a **private IP inside your VNet** — fully removes public exposure.

**27. Explain Docker networking**
Default `bridge` network lets containers on the same host talk via internal IPs; `host` network shares the host's network namespace directly (no isolation); `none` disables networking; user-defined bridge networks add automatic DNS resolution between containers by name — most common for multi-container apps.

**28. Difference between ARG and ENV in Docker?**
`ARG` is only available at **build time** (not present in the running container) and can be overridden with `--build-arg`. `ENV` persists into the running container's environment and is available both at build and runtime.

**29. Suppose someone deleted resources manually — how do you handle this in Terraform?**
Run `terraform plan` — it will show Terraform wants to recreate the "missing" resource since it still exists in state. Either let it recreate (if that's desired), or `terraform state rm` if you want Terraform to stop tracking it, then optionally `terraform import` if it needs re-linking to a resource that still exists elsewhere.

**30. What are sets and lists in Terraform?**
Both are collection types. `list` is ordered and allows duplicate values, indexed (`list[0]`). `set` is unordered and does not allow duplicates — used with `for_each` when order doesn't matter and uniqueness does.
