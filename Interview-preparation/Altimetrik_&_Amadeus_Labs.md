# Interview Prep — Altimetrik & Amadeus Labs

---

## ALTIMETRIK

### 1. How do you import a resource into Terraform that was created manually?
`terraform import <resource_type>.<resource_name> <resource_id>` — e.g. `terraform import aws_vpc.main vpc-0123456`. It only imports into state, though — you still have to write the matching resource block in your `.tf` file yourself so `terraform plan` shows no diff afterward.

### 2. Exposure to Dev, QA, and Prod environments?
I manage all three day to day — separate namespaces/clusters per environment, with dev used for active development, UAT/QA for pre-release validation, and prod locked down with stricter change control (no spot instances, manual-approval deploys, tighter RBAC).

### 3. Understanding of software architecture components (LB, web/app servers, DB, integrations)?
Load balancer (ALB/Ingress) distributes traffic to web-tier pods, which handle HTTP/static content and forward business logic to app-tier services (backend microservices), which talk to the database layer (RDS/Redis) and external integrations (payment gateways, third-party APIs) — each layer scaled and secured independently.

### 4. Experience with alerts, logging, and incident/problem resolution?
I use Prometheus/Grafana for metrics and alerting, check dashboards each morning for anomalies, and when an incident hits I follow: identify affected service → check logs/metrics → mitigate (rollback/scale/restart) → root-cause → document. This process contributed to the 40% MTTR improvement on my resume.

### 5. Knowledge of production system sizing, provisioning, setup, maintenance, closure?
I size based on observed CPU/memory usage and traffic patterns, provision via Terraform/CI-CD rather than manually, set up monitoring and alerting before go-live, do ongoing capacity reviews (e.g. moving over-provisioned instances to reserved/right-sized), and decommission cleanly (drain, backup if needed, remove from IaC) rather than leaving orphaned resources.

### 6. Infrastructure administration: licensing, billing, cost reduction, security?
I regularly review AWS Cost Explorer/billing, right-sized an EC2 database from ~$10K to ~$7.5K/month via Reserved Instances, moved non-prod workloads to spot instances for savings, and handle security via IAM least-privilege, security groups, and vulnerability scanning (Trivy/SonarQube) in the pipeline.

### 7. Walk me through what's in your Helm charts — what's actually written there?
A Helm chart has `Chart.yaml` (metadata), `values.yaml` (configurable defaults — image tag, replica count, resource limits, env vars), and a `templates/` folder with Kubernetes manifests (Deployment, Service, Ingress, ConfigMap) using Go templating to pull in values. I use it to template the same app definition across dev/UAT/prod by just swapping values files.

### 8. What is defined in your values.yaml?
Image repository and tag, replica count, resource requests/limits, environment variables/ConfigMap references, service type and port, ingress host/path, and any autoscaling (HPA) thresholds — all parameterized per environment.

### 9. How does a microservice actually get deployed into a pod in GKE?
Image gets built and pushed to a registry (GCR/Artifact Registry) by CI, then ArgoCD/Helm applies the Deployment manifest to the cluster; the scheduler picks a node with available resources, kubelet pulls the image and starts the container, and the pod moves through Pending → ContainerCreating → Running once health checks pass.

### 10. Pod deployment failing / pod in error state and terminating — how do you troubleshoot?
`kubectl describe pod <pod>` first to see events (image pull error, OOMKilled, failed probes, scheduling issues), then `kubectl logs <pod> --previous` if it already restarted, check resource limits vs actual usage, and check readiness/liveness probe configuration if it's crash-looping.

### 11. General approach to Kubernetes troubleshooting?
Start broad then narrow: `kubectl get pods` for status → `describe` for events → `logs` for application errors → check resource/node health → check recent changes (deploy history, config changes) — I always check "what changed recently" first since most incidents follow a recent change.

### 12. Observability dashboards / frameworks you use?
Prometheus for metrics collection, Grafana for dashboards, and Alertmanager for routing alerts — occasionally ELK/Loki for log aggregation depending on the project.

### 13. Have you set up dashboards and alerts yourself?
Yes — I build Grafana dashboards for pod health, node resource usage, and pipeline status, and configure Alertmanager rules for threshold-based alerts (CPU/memory, pod restarts, deployment failures).

### 14. Walk me through the dashboards/alerts you've created.
Dashboards for cluster-level health (node CPU/memory/disk), per-service pod status and restart counts, and CI/CD pipeline success/failure rates. Alerts cover pod crash-looping, high memory/CPU thresholds, and failed deployments — routed to Slack/email for the on-call developer.

### 15. Have you used SRE golden signals (latency, traffic, errors, saturation) day-to-day?
*(Answer honestly based on your actual practice — if you monitor CPU/memory/restarts but haven't formally framed it as "golden signals," say so:)* "I monitor the equivalent metrics — request latency, error rates from app logs, and resource saturation via Grafana — though I haven't formally structured dashboards around the four golden signals as a named framework. I'm familiar with the concept and could apply it directly."

### 16. Have you done SLO-based work?
*(Same honesty approach — don't claim it if you haven't formally set SLOs. Suggested answer if you haven't:)* "Not formal SLO/error-budget tooling — my monitoring has been threshold/alert-based rather than SLO-driven. I understand the concept and how it differs from simple threshold alerting."

### 17. What is an error budget?
The allowed amount of unreliability before you breach your SLO — e.g. a 99.9% availability SLO over 30 days allows ~43 minutes of downtime; that 43 minutes is the error budget. Once it's spent, teams typically pause new feature releases and focus on reliability.

### 18. Have you configured SLO-based alerting?
*(If not, answer honestly, don't fabricate — e.g.:)* "I haven't implemented formal SLO-based burn-rate alerting — my alerting has been metric-threshold-based (CPU, memory, restart count) rather than error-budget-burn-based. I understand the model: alert faster when burn rate indicates the budget will be exhausted soon."

### 19. What is an ideal burn rate?
A burn rate of 1x means you're consuming the error budget exactly on pace to exhaust it right at the SLO window's end. Ideal steady-state is well under 1x; multi-window alerting typically fires at burn rates like 14x (fast, page immediately) over a short window and 6x (slower, ticket) over a longer window — catching both sudden and slow-burn issues.

### 20. How do you use Terraform to deploy cluster nodes?
I define the EKS/GKE cluster and node group as Terraform resources (`aws_eks_node_group` or `google_container_node_pool`), specifying instance type, scaling min/max/desired, and subnet placement, then `terraform apply` provisions the managed node group — Kubernetes then schedules pods onto those nodes as they join.

### 21. What goes in your provider file and main.tf?
`provider.tf` declares the cloud provider block (`provider "aws" { region = "ap-south-1" }`) and required version/backend config for state (e.g. S3 backend). `main.tf` contains the actual resource blocks — VPC, subnets, EKS cluster, node groups — often calling reusable modules rather than inline resources.

### 22. Write Terraform to create a VPC, subnet, and attach the subnet to the VPC (AWS).
```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
}
```
Say it out loud as: "Create the VPC resource with a CIDR block, then create a subnet resource referencing `aws_vpc.main.id` so Terraform knows the dependency — that's what attaches it to the VPC."

### 23. You optimized Kubernetes deployment configs — what was your role, what did you do?
I reviewed resource requests/limits that were misconfigured (either unset, causing noisy-neighbor issues, or oversized, wasting capacity), right-sized them based on actual usage from Grafana, added/tuned liveness and readiness probes to reduce false restarts, and adjusted rolling update strategy (maxSurge/maxUnavailable) — this was part of what reduced deployment failures by 60%.

### 24. You architected a blameless postmortem framework — what did you do to reduce critical incidents?
After major incidents, I ran postmortems focused on process/system gaps rather than blaming individuals, documented root cause and action items, and fed recurring issues back into monitoring (new alerts) or automation (auto-remediation) so the same class of incident wouldn't repeat undetected.

### 25. What automation did you do to reduce MTTR?
Automated rollback in the CI/CD pipeline when post-deploy health checks fail, added alerting tied directly to deployment status so failures are caught in minutes instead of being discovered by users, and standardized runbooks/dashboards so on-call could diagnose faster — together this drove the 40% MTTR reduction.

---

## AMADEUS LABS (SRE, 5yr exp)

### 1. Pod-level autoscaling (HPA) not happening — approach?
Check `kubectl describe hpa <name>` first — common causes: metrics-server not running/reporting (HPA shows `<unknown>` for targets), resource *requests* not set on the pod (HPA needs requests to calculate % utilization), or the metric simply hasn't crossed the threshold yet. Fix metrics-server/requests first, then verify with `kubectl top pods`.

### 2. HPA was working fine, suddenly stopped — approach?
Same diagnostic path but framed as "what changed": check if metrics-server pod is healthy/crashed, check if resource requests were removed/changed in a recent deploy, check HPA's `describe` output for error events, and check if min/max replica bounds were hit (it's "working" but capped at max).

### 3. Ingress configured but not accessible to end users — how do you resolve?
Check in order: `kubectl get ingress` (is it assigned an address?) → Ingress Controller/ALB pod logs and health → DNS resolution to that address → security group/firewall rules allowing inbound traffic → backend service/pod health via `kubectl get endpoints`. Most often it's DNS not pointing to the LB, or a security group blocking the port.

### 4. How does Kubernetes handle service discovery?
Every Service gets a stable DNS name via CoreDNS (`<service>.<namespace>.svc.cluster.local`) and a virtual ClusterIP; kube-proxy maintains iptables/IPVS rules that route traffic to that ClusterIP toward healthy backend pod IPs, so pods discover each other by service name instead of tracking changing pod IPs directly.

### 5. Ensure 5 application teams don't use more than a set amount of resources?
Create a namespace per team with a `ResourceQuota` (caps total CPU/memory/storage requests+limits per namespace) and `LimitRange` (default and max per-pod limits) — this prevents any one team from consuming more than their allocated share of the cluster.

### 6. Leap second in Linux — what is it / how handled?
A leap second is an occasional +1 second adjustment to UTC to account for Earth's rotation slowing. Linux systems handle it via NTP; some systems "smear" the leap second (spread the extra second gradually) to avoid an abrupt clock jump that can break time-sensitive distributed systems.

### 7. What automation have you done in Kubernetes?
Automated image build → scan → deploy via CI/CD + ArgoCD GitOps, so any Git merge auto-deploys without manual `kubectl apply`; also automated node draining during EKS version upgrades and rollback-on-failed-health-check in the deployment pipeline.

### 8. Automation that saved time in your project?
The GitOps pipeline itself — before it, deployments were manual `kubectl apply` steps taking real coordination time; automating it via ArgoCD cut deployment turnaround and reduced human error, contributing to the 60% deployment failure reduction on my resume.

### 9. Can this pod be scheduled? `securityContext: runAsNonRoot: true, runAsUser: 0`
**No.** This is a contradictory config — `runAsNonRoot: true` requires the container run as a non-root user, but `runAsUser: 0` explicitly sets it to root (UID 0). Kubernetes will refuse to start the container and it'll fail with an error like `container has runAsNonRoot and image will run as root` — it won't even get to Running state.
