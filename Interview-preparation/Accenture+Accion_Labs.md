# DevOps Interview Prep — Round 2 (Accenture + Accion Labs)

---

## Accenture

### 1. You created an IAM user and configured role-based access in EKS. How do you bind the IAM user to the EKS role?
Map the IAM user's ARN to a Kubernetes RBAC group in the `aws-auth` ConfigMap (`mapUsers` section), then bind that group to a Role/ClusterRole via a RoleBinding. Newer EKS clusters can instead use **EKS Access Entries** (`aws eks create-access-entry` + `associate-access-policy`), which does the same mapping without editing the ConfigMap directly.

### 2. You have 10 AWS accounts. How do you securely log in without access keys?
Use **AWS IAM Identity Center (SSO)** as a central identity provider — users authenticate once via SSO, then assume short-lived, auto-rotating credentials into each account's role via **cross-account IAM roles + STS AssumeRole**. No long-lived access keys are stored anywhere.

### 3. What are the ways to log in to an AWS account?
Root user login (avoided except emergencies), IAM user with username/password (console) or access keys (CLI, discouraged), IAM role assumption via STS, and federated/SSO login through AWS IAM Identity Center or a corporate SAML/OIDC identity provider.

### 4. Does Amazon S3 require a VPC?
No — S3 is a regional/global service accessed over public endpoints by default, so it works without any VPC. You *can* optionally use a VPC Gateway Endpoint to reach S3 privately from within a VPC without going over the public internet.

### 5. What happens when you run `terraform init`?
It initializes the working directory: downloads the required provider plugins, sets up the backend (where state will be stored, e.g. S3), and downloads any referenced modules — preparing everything needed before `plan`/`apply` can run.

### 6. Write a Terraform script to create an EC2 instance in multiple regions.
```hcl
provider "aws" {
  alias  = "region1"
  region = "us-east-1"
}
provider "aws" {
  alias  = "region2"
  region = "eu-west-1"
}

resource "aws_instance" "server_region1" {
  provider      = aws.region1
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
}

resource "aws_instance" "server_region2" {
  provider      = aws.region2
  ami           = "ami-0fedcba9876543210"
  instance_type = "t3.micro"
}
```
Say out loud: "I'd define a provider block per region with an alias, then reference the alias explicitly on each `aws_instance` resource's `provider` argument."

### 7. Multi-region config (region1, region2, region3) — which region does an EC2 instance deploy to?
Whichever provider (alias) that specific `aws_instance` resource references via its `provider =` argument. If no alias is set, it uses the **default (unaliased) provider block's region**. There's no automatic "pick a region" — it's always explicit per-resource.

### 8. Frontend, backend, and DB are all in private subnets — how does an end user access the app?
Through a public-facing **ALB/NLB placed in public subnets**, which routes traffic into the frontend in the private subnet. The private subnets get outbound internet access (for updates, etc.) via a **NAT Gateway** in the public subnet — but inbound user traffic only ever enters through the load balancer.

### 9. How can EKS access secrets stored in AWS Secrets Manager?
Via **IRSA (IAM Roles for Service Accounts)** — the pod's service account is tied to an IAM role with Secrets Manager read permission, and either the **Secrets Store CSI Driver** mounts the secret as a volume, or the **External Secrets Operator** syncs it into a native Kubernetes Secret automatically.

### 10. How do you set up RBAC in Amazon EKS?
Define a `Role`/`ClusterRole` specifying allowed verbs on resources (get, list, create, etc.), then a `RoleBinding`/`ClusterRoleBinding` to attach that Role to a user, group, or service account. For IAM identities, that binding traces back through the `aws-auth` ConfigMap or Access Entries mapping IAM identity → k8s group → Role.

---

## Accion Labs

### 1. How do you ensure high availability in Kubernetes?
Spread nodes and pods across multiple AZs using topology spread constraints/pod anti-affinity, run multiple replicas with PodDisruptionBudgets, use readiness/liveness probes so unhealthy pods get cycled out, and rely on the Cluster Autoscaler to replace failed nodes. EKS itself runs a multi-AZ managed control plane, so that layer is HA by default.

### 2. What are SLO, SLI, and SLA — why do they matter?
SLI is the measured metric (e.g. request latency, uptime %). SLO is the internal target for that metric (e.g. 99.9% uptime). SLA is the customer-facing contractual commitment, usually with penalties if missed. They matter because they turn "reliability" into something measurable, and the gap between SLI and SLO becomes your error budget for deciding how much risk you can take on new releases.

### 3. Describe a recent major incident you handled and how you resolved it.
We had intermittent slowness on the customer-facing site that traced back to EKS worker nodes running on Spot instances losing capacity during peak hours. I confirmed it via Grafana (pod evictions/node churn correlating with the slowness window), then migrated production node groups from Spot to On-Demand while keeping Spot for dev/UAT to control cost. Site stability returned immediately, and I documented it so we never mix Spot into prod-critical workloads again.

### 4. What is the deployment setup in your organization?
GitOps-based: code is built and scanned via GitHub Actions/Jenkins (Trivy + SonarQube), pushed as a Docker image to ECR/Docker Hub, and ArgoCD continuously syncs the EKS cluster to match the desired state defined in Git — using Helm charts for templating, separated by namespace per environment (dev/UAT/prod).

### 5. Maximum time for a node to start after a failure or restart?
For a managed node group in EKS, a replacement EC2 instance typically joins the cluster and is Ready in about **3-5 minutes** (instance boot + kubelet bootstrap + node registration). If scaling from zero or pulling large images for the first time, it can stretch to **8-10 minutes** — I'd flag that this is capacity/AMI-dependent rather than a fixed number.

### 6. How have you resolved high-performance issues or critical incidents?
Typically start with Grafana to isolate whether it's CPU/memory throttling, then check `kubectl describe pod` for resource limit issues or `kubectl top` for actual usage vs. requests. Fixed cases by right-sizing resource requests/limits, adding HPA for autoscaling under load, and in one case migrating an overloaded RDS instance to a larger class after query load outgrew it.

### 7. Difference between observability and monitoring?
Monitoring tracks **known, predefined metrics** against thresholds and alerts you when something you anticipated goes wrong. Observability is broader — having enough logs, metrics, and traces to **ask new questions about unknown failure modes** you didn't predict in advance. Monitoring tells you *that* something's wrong; observability helps you find out *why*.

### 8. Linux command to mount a file system?
`mount /dev/sdb1 /mnt/data` mounts a specific device to a directory; `mount -a` mounts everything listed in `/etc/fstab`. `umount` reverses it.

### 9. How do you detect the root cause when an application goes down in the cloud?
Start at Grafana/Prometheus for the timeline of resource/error-rate anomalies, then `kubectl get events` and `kubectl logs`/`describe pod` for the specific failing pods, cross-check ArgoCD for a recent bad sync/deploy, and check CloudWatch/CloudTrail for any AWS-side event (throttling, AZ issue, IAM change) in that same window.

### 10a. What do you do if the master (control plane) node goes down?
On EKS, the control plane is fully AWS-managed and runs multi-AZ for HA — I don't manage it directly. If I suspect a control-plane-level issue, I'd check the **AWS Health Dashboard** and open a support case rather than attempt any manual fix.

### 10b. What do you do if a worker/slave node goes down?
Kubernetes automatically reschedules the affected pods onto healthy nodes (assuming replicas > 1), and the managed node group/Cluster Autoscaler launches a replacement node to restore capacity. I'd still check *why* it went down — spot interruption, OOM, disk pressure — to prevent recurrence.

### 11. How do you configure a VPC for high availability?
Spread subnets across at least 2-3 AZs, with a public and private subnet pair per AZ, a **NAT Gateway in each AZ** (not a single shared one, which becomes a single point of failure), and redundant route tables per AZ. Pair that with Multi-AZ RDS for the database layer.

### 12. Have you worked on scripting — which tool, and what did you implement?
Mainly Bash — I've written scripts for automating routine ops tasks: health-check scripts that hit Grafana/API endpoints and alert on failure, cleanup cron jobs for old Docker images/logs, and small wrapper scripts around `kubectl`/`aws cli` to standardize repetitive deployment or node-drain steps across environments.

### 13. Have you written Terraform code for deployments? Explain the implementation.
Yes — mainly for provisioning, not app deployment itself: modules for VPC, EKS cluster, and RDS, parameterized by environment via `.tfvars` files so the same module provisions dev/UAT/prod with different sizing and CIDR ranges. Actual application deployment to the provisioned EKS cluster is handled separately via ArgoCD/Helm.

### 14. Explain your hands-on experience with Docker.
Writing and optimizing Dockerfiles (multi-stage builds to shrink final image size), scanning images with Trivy before push, using `docker-compose` for local multi-service dev environments, and troubleshooting container-level issues (layer caching, entrypoint/CMD behavior, resource limits) before they hit the cluster.

### 15. Why do we use workspaces in Terraform?
Workspaces let you maintain **separate state files for the same configuration** — e.g. one workspace for dev, one for UAT, one for prod — without duplicating your `.tf` code or setting up separate directories. Each workspace tracks its own resources independently even though the code is shared.

### 16. Tell me about Ansible. Have you worked on it before, in what context?
Honestly, limited hands-on — my configuration management/deployment work has been Kubernetes-native (Helm for templating, ArgoCD for GitOps) rather than Ansible playbooks, since most of our infra is containerized rather than long-lived VMs. I understand Ansible's model conceptually (agentless, YAML playbooks, idempotent tasks over SSH) and could ramp up quickly if a role needed it, but I won't claim production depth there.
*(Say this plainly and pivot immediately to what you **do** have — Helm/ArgoCD — so it reads as "different tool for a containerized world," not a gap.)*
