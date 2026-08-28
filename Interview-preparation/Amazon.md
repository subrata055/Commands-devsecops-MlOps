# Amazon DevOps Consultant — Interview Prep (7 YOE level)

These expect more precision and "why" than your last interview — at 7 years they're testing depth, not just familiarity. Say the mechanism, not just the tool name.

---

## Set 1

### 1. Sending log files from EC2 to S3 — steps?
Install/configure the CloudWatch Unified Agent on the EC2 instance to tail the log file and ship it to CloudWatch Logs. From there, either set up a subscription filter to stream to Kinesis Firehose → S3, or use CloudWatch Logs' S3 export task for batch export. The EC2 instance needs an IAM role with `logs:PutLogEvents` and the Firehose/S3 destination needs `s3:PutObject` permission.

### 2. Limit resource usage in K8s — not via deployment.yaml, but via namespace
Use a `ResourceQuota` object on the namespace to cap total CPU/memory/object count for everything inside it, and a `LimitRange` to set default/min/max resource requests-limits per pod/container within that namespace — so even deployments that don't specify limits get constrained automatically.

### 3. Three-tier architecture
Presentation tier (ALB + web servers, public subnet) → Application tier (app servers/EKS, private subnet) → Data tier (RDS/DB, private subnet, no direct internet route). Each tier has its own security group, and traffic is only allowed from the tier directly above it — web can't talk to DB directly.

### 4. Updating worker nodes in K8s
Cordon the node (stop new scheduling) → drain it (evict pods gracefully, they reschedule elsewhere) → update the node (new AMI/launch template version) → uncordon. For EKS managed node groups, this rolling update is handled automatically when you update the node group's launch template — one node at a time by default.

### 5. "I'm an admin but I don't have access to an S3 bucket" — why?
Most likely a **Permission Boundary** — it sets the *maximum* permissions an IAM identity can have regardless of what the attached policy grants, so even an admin policy is capped by the boundary. Also check for an explicit `Deny` in the bucket policy or an SCP at the Org level — explicit denies always override admin allows.

### 6. Various stages of CI/CD
Source (checkout) → Build → Static/security scan (SAST, dependency scan) → Package/artifact (Docker image, versioned) → Deploy to staging → Integration/smoke test → Deploy to prod (often gated/approval) → Monitor/rollback if needed.

### 7. How do you build the image during CI, and how do you manage it?
Multi-stage Docker build in the CI job to keep the final image small, tag it with the Git commit SHA (not `latest`) for traceability, scan it (Trivy) before push, then push to ECR. Manage lifecycle with ECR image retention/lifecycle policies so old untagged images get auto-cleaned.

### 8. S3 bucket in one region (e.g. ap-south-1) — accessible from us-east-1?
Yes. S3 bucket *data* lives in one region, but the bucket is reachable globally over the internet via its regional endpoint (or the global `s3.amazonaws.com` endpoint) as long as IAM/bucket policy allows it — no bucket replication needed just to *access* it, only latency is added. Cross-region *replication* (for redundancy) is a separate, optional feature (S3 CRR).

### 9. Terraform code: VPC, subnet, EC2, S3 bucket
```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_instance" "app" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
}

resource "aws_s3_bucket" "logs" {
  bucket = "my-app-logs-bucket"
}
```
Say out loud: "provider config, resource blocks for VPC/subnet/EC2/S3, variables for reusability, and I'd normally wrap these into modules for multi-environment use."

### 10. Purpose of CNI in Kubernetes
The Container Network Interface plugin is what actually assigns IP addresses to pods and wires up pod networking. On EKS specifically, the AWS VPC CNI assigns pods real VPC IP addresses (from the subnet's ENI pool), so pods can communicate directly with other AWS resources without extra NAT/overlay networking.

### 11. Automation: ship EC2 logs to S3 + CPU alarm to users
CloudWatch Agent on EC2 ships app logs to CloudWatch Logs (and exports/streams to S3 via Firehose). Separately, create a CloudWatch Alarm on the `CPUUtilization` metric with a threshold (e.g. >80% for 5 min), and set the alarm action to publish to an SNS topic — subscribe users' email/SMS to that topic so they get notified automatically.

### 12. Can you create a NAT Gateway in a private subnet?
No — a NAT Gateway must sit in a **public** subnet because it needs a route to an Internet Gateway to provide outbound internet access for resources in private subnets. Putting it in a private subnet defeats its purpose since it would have no internet path itself.

### 13. How to configure cluster autoscaling
Deploy the Kubernetes Cluster Autoscaler (or use EKS managed node groups with min/max/desired capacity set) — it watches for pods stuck in `Pending` due to insufficient resources and adds nodes, and removes underutilized nodes when safe. Pair this with the Horizontal Pod Autoscaler (HPA) for pod-level scaling based on CPU/memory/custom metrics — cluster autoscaler handles nodes, HPA handles pods.

---

## Set 2

### 1. Migrating monolithic app (with local file system) on-prem → Cloud, which file system?
If multiple instances need shared access, use **EFS** (Elastic File System — POSIX-compliant, mountable across multiple EC2/containers simultaneously). If it's single-instance local disk, **EBS** is the equivalent. If the app can be refactored to use object storage instead of a file system, S3 is cheaper/more scalable long-term.

### 2. How will you store all the configs for your monolithic app in the cloud?
Non-secret config → **Systems Manager Parameter Store** (or AWS AppConfig for dynamic config with rollout controls). Secrets (DB passwords, API keys) → **Secrets Manager**, with automatic rotation. App reads these at startup via IAM role instead of hardcoded config files.

### 3. What observability is needed for an app?
Monitoring (metrics — CloudWatch/Prometheus), Logging (centralized — CloudWatch Logs/ELK), Alerting (thresholds → SNS/PagerDuty), automated Remediation (Lambda/SSM Automation for self-healing where possible), and PD/on-call escalation so a human gets paged when automation can't fix it.

### 4. Not allowed to install Filebeat on worker nodes — alternative for logging?
Run **Fluent Bit** as a DaemonSet instead — it's lighter-weight, AWS/EKS-optimized, and doesn't require installing an agent directly on the node OS (it runs as a pod). Alternatively use the CloudWatch Container Insights agent, also deployed as a DaemonSet.

### 5. Security protocols for a three-tier architecture
TLS/SSL for all traffic (including internal), security groups with least-privilege rules per tier, private subnets for app/DB tiers (no public IPs), WAF in front of the ALB, encryption at rest via KMS, IAM least-privilege roles per service, and centralized secrets management — no credentials in code/config files.

### 6. DB migration — how do you sync the data?
Use **AWS DMS (Database Migration Service)** with Change Data Capture (CDC) — it does an initial full load, then continuously replicates ongoing changes from source to target, so you can cut over with minimal downtime once source and target are in sync.

### 7. If a DB pod goes down, will it affect stored data?
No — as long as it's backed by a persistent volume (EBS-backed PVC) or, better, an external managed DB like RDS/Aurora rather than pod-local storage. The pod restarts and reattaches to the same PVC; data isn't lost. Data loss only happens if you're using ephemeral/emptyDir storage.

### 8. What about sticky session data if a pod goes down?
Yes — sticky session data is lost. Session affinity just routes a client to the same pod, but if that data lives in the pod's memory and the pod dies, it's gone; there's no replication of in-memory session state to other pods by default.

### 9. Alternative service to use instead of sticky sessions?
**Redis** (or Memcached) as an external, shared session store — pods become stateless, any pod can serve any request by reading session data from Redis instead of keeping it locally.

### 10. What causes the sticky-session problem, from the LB's perspective?
The load balancer uses cookie- or IP-based affinity to pin a client to one specific backend pod. The root cause of the *problem* isn't the LB itself — it's that session state is stored only in that pod's memory instead of externally, so when the LB's target becomes unavailable, that session data has nowhere else to be recovered from.

### 11. Do you create clusters in multiple regions — is it possible, how do you manage them?
Yes — deploy independent EKS clusters per region, manage them centrally via GitOps (ArgoCD watching a shared Git repo, or ArgoCD ApplicationSets for multi-cluster). Use Route 53 (latency-based or failover routing) for traffic distribution, and something like Aurora Global Database for cross-region data replication.

### 12. Onboarded a trading app into AWS — how do you ensure availability, scalability, security?
Availability: Multi-AZ deployment, ALB across AZs, RDS/Aurora Multi-AZ. Scalability: EKS with Cluster Autoscaler + HPA, read replicas for DB. Security: WAF + Shield for DDoS protection, encryption at rest/in-transit, private subnets, least-privilege IAM, regular pen-testing given it's financial data.

### 13. How do you back up your entire cluster regularly?
Use **Velero** — it backs up Kubernetes resource manifests plus takes PV snapshots, on a schedule, stored in S3. Test restores periodically (a backup you haven't tested restoring isn't a verified backup).

### 14. Python script: list EC2 instances tagged PROD
```python
import boto3

ec2 = boto3.client('ec2')

response = ec2.describe_instances(
    Filters=[
        {'Name': 'tag:Environment', 'Values': ['PROD']},
        {'Name': 'instance-state-name', 'Values': ['running']}
    ]
)

for reservation in response['Reservations']:
    for instance in reservation['Instances']:
        print(instance['InstanceId'], instance['State']['Name'])
```

### 15. 200 EC2 instances across 10 accounts — how do you connect/manage all of them?
Two angles: for **network connectivity** between VPCs across accounts, use **AWS Transit Gateway** (shared via AWS RAM) as a central hub. For **management access** (patching, running commands, no SSH keys needed), use **AWS Systems Manager (SSM) — Session Manager / Fleet Manager**, ideally with AWS Organizations for centralized multi-account visibility.

### 16. Connect to a DB in a private subnet — without NAT gateway, NAT instance, or bastion host
Use a **VPC Interface Endpoint (AWS PrivateLink)** if connecting to an AWS service, or **AWS Systems Manager Session Manager** via an SSM VPC endpoint to tunnel into the private subnet without any public exposure. For on-prem connectivity, a Site-to-Site VPN or Direct Connect also avoids needing NAT/bastion.

### 17. Explain the OSI model
Seven layers, physical to application: Physical (bits/cables) → Data Link (MAC/switches) → Network (IP/routing) → Transport (TCP/UDP, ports) → Session (connection management) → Presentation (encryption/encoding) → Application (HTTP/DNS — what the user-facing app talks). Say it fast, in order, that's usually all they're checking.

### 18. Difference between a directory and a mount
A **directory** is just a namespace entry in the filesystem tree — a folder that organizes files. A **mount** is the act of attaching a separate filesystem or device (a disk, EBS volume, EFS, NFS share) onto a directory path (the mount point), so that directory transparently becomes the root of that other filesystem.

### 19. Difference between `local` and `variable` in Terraform
A `variable` is an **input** — supplied externally via `.tfvars`, CLI flags, or environment variables to customize the config from outside. A `local` is a **computed value defined inside** the config itself — used to avoid repeating an expression or to simplify a complex reference; it's not meant to be set from outside.

### 20. Resources created via Terraform — how do you ensure they're not modified via the console, and how do you automate that check?
Two layers: **prevent** — restrict IAM so only the CI/CD role (not humans) has write access to those resources in the console; **detect** — run `terraform plan` on a schedule (cron job in CI/CD) to catch drift, since plan shows any manual changes as a diff against state; tools like `driftctl` or AWS Config rules can also alert automatically when a resource deviates from its Terraform-defined state.
