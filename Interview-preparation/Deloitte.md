# Deloitte Interview Prep — All Rounds

---

## Set 1 — AWS Networking / Storage / Backup

**1. What types of nodes did you deploy in AWS?**
EC2-based worker nodes for EKS — a mix of on-demand (prod) and spot (dev/UAT) — plus some Fargate profiles for lightweight/serverless workloads where I didn't want to manage nodes at all.

**2. Difference between Interface Endpoint and Gateway Endpoint?**
Interface Endpoint creates an ENI with a private IP inside your subnet (PrivateLink-based) and works for most AWS services (SSM, ECR, SNS, etc.), incurring hourly + data cost. Gateway Endpoint is just a route table entry — no ENI, no extra cost — but only supports S3 and DynamoDB.
*Follow-up: "When would you pick one over the other?" → Gateway endpoint whenever it's S3/DynamoDB (free, simpler); Interface endpoint for everything else needing private access.*

**3. How did you set up ECS using EC2 instances?**
Created a cluster with EC2 launch type, launched EC2 instances with the ECS-optimized AMI (ECS agent + user-data registering them to the cluster), defined task definitions (image, CPU/mem, ports), then created a service to place/schedule tasks across those instances and register them with an ALB target group.
*Follow-up: "EC2 vs Fargate launch type?" → EC2 = you manage the underlying instances/capacity; Fargate = AWS manages compute, you just define the task, no server management.*

**4. "Can't we configure Route 53?" (for a domain not registered there)**
Yes — you don't need to register the domain with Route 53. Create a public hosted zone for the domain in Route 53, then point the domain's nameservers (at wherever it's registered) to the 4 NS records Route 53 gives you.

**5. Third-party domain (GoDaddy) in Route 53 — how?**
Create a public hosted zone in Route 53 for the domain, copy the 4 NS records it generates, then log into GoDaddy's DNS management and replace GoDaddy's default nameservers with those 4 Route 53 nameservers. All DNS management then happens in Route 53.

**6. AWS Config vs CloudTrail?**
Config tracks the *state and configuration history* of resources and evaluates them against compliance rules ("what does this resource look like now vs. before"). CloudTrail logs *API activity* — who called what action, when, from where ("who did this"). Config = state/compliance, CloudTrail = audit trail.

**7. Node groups in EKS / types of node groups?**
Three types: Managed Node Groups (AWS handles provisioning/lifecycle/upgrades of the EC2 nodes), Self-Managed Node Groups (you manage the ASG/EC2 yourself), and Fargate Profiles (no nodes at all — serverless pods).

**8. If a user wants to access an S3 bucket, what's the process?**
Authentication (IAM user/role credentials), then authorization checked against IAM policy + bucket policy (+ ACL if used) + Block Public Access settings, then the request goes through via console/CLI/SDK/API. For EC2/EKS workloads I use an instance/IRSA role instead of static keys.

**9. How does VPC Peering work?**
A direct, private, one-to-one connection between two VPCs over the AWS backbone (no gateway, no single point of failure) using private IPs. It's non-transitive — if A peers with B and B peers with C, A cannot reach C through B. Requires updating route tables on both sides and CIDR ranges must not overlap.

**10. How does Transit Gateway work and how did you configure it?**
TGW is a central hub that multiple VPCs, VPNs, and Direct Connect attach to, avoiding the N² mesh problem of VPC peering. I created the TGW, created a VPC attachment per VPC/subnet, then updated each VPC's route table to send traffic destined for other VPCs' CIDRs to the TGW.

**11. Connecting VPCs to TGW — what do you update in the VPC route table?**
Add a route where the destination is the other VPCs' CIDR ranges (or 0.0.0.0/0 if routing everything through TGW, e.g., for centralized egress) with the Transit Gateway as the target.

**12. Do you configure TGW attachment with CIDR range for all VPCs?**
The attachment itself is per subnet, not tied to a CIDR directly — routing is controlled separately via TGW route tables associated with each attachment, which lets you segment which VPCs can reach which (e.g., isolate a VPC even though it's attached to the same TGW).

**13. What is Route 53?**
AWS's managed DNS service — handles domain registration, DNS resolution via public/private hosted zones, health checks, and routing policies (simple, weighted, latency-based, failover, geolocation).

**14. What is WAF and "AAF"?**
WAF (Web Application Firewall) protects web apps from common exploits like SQL injection and XSS via rule sets attached to CloudFront, ALB, or API Gateway. I'm not familiar with "AAF" as a standard AWS term — if you meant something specific, I'd want to clarify, but it may be Application/Access-related firewalling, which WAF + Security Groups + NACLs together typically cover.
*(Say this honestly rather than guessing confidently — it's likely a mishearing or org-specific term.)*

**15. What is VPC Flow Logs, and how do you track IPs hitting the VPC?**
Flow Logs capture metadata about IP traffic to/from network interfaces in a VPC (source/dest IP, port, protocol, accept/reject, bytes). Publish them to CloudWatch Logs or S3, then query for specific source/destination IPs to see what's hitting the VPC.

**16. How to filter a particular IP from a CloudWatch Log Group?**
Use CloudWatch Logs Insights with a query like `fields @timestamp, srcAddr, dstAddr | filter srcAddr = "1.2.3.4"`, or a metric filter/filter pattern if just doing a quick substring search.

**17. If logs are in S3, how do you track a particular IP?**
Use Athena to run SQL queries directly against the S3-stored flow logs (create a table over the S3 location, query `WHERE srcaddr = '1.2.3.4'`), or S3 Select for a quick one-off filter without setting up Athena.

**18. How do you take backups of AWS services?**
AWS Backup as the centralized service — define backup plans/policies covering EBS, RDS, DynamoDB, EFS with retention and schedule. For simpler needs, native snapshots (EBS snapshots, RDS automated/manual snapshots).

**19. Can we create AWS backups using shell scripting?**
Yes — using AWS CLI commands like `aws ec2 create-snapshot` or `aws backup start-backup-job` inside a script, triggered via cron or a Lambda function on a schedule.

**20. Once a backup is created, where do the log files get stored?**
Backup job status/logs are visible in the AWS Backup console and via CloudTrail (API call logs); if I want them centralized, I'd forward CloudTrail/Backup events to a CloudWatch Log Group or S3 bucket for retention and alerting.

---

## Set 2 — Jenkins / Kubernetes / Docker / Helm (Round 1 & 2)

**1. Explain your CI/CD workflow and pipeline type. How do you define/invoke pipelines in Jenkins?**
Declarative Jenkinsfile checked into the repo: checkout → build → test → SonarQube scan → Trivy scan → build image → push to registry → deploy via ArgoCD/Helm. Defined as a Pipeline job pointing to the Jenkinsfile, triggered via GitHub webhook.

**2. What are Jenkins shared libraries, and how are they written/defined?**
Reusable Groovy code stored in a separate Git repo, loaded into a Jenkinsfile with `@Library('lib-name') _`. Structured as `vars/` (global callable steps used directly in pipelines) and `src/` (Groovy classes for more complex logic), configured under Manage Jenkins → Global Pipeline Libraries.

**3. What applications do you deploy via Jenkins, and what deployment tools?**
Java, Python, and Angular microservices. CI builds/pushes the image in Jenkins; actual deployment to EKS is via Helm or ArgoCD (GitOps), not Jenkins directly.

**4. Jenkins pipeline runs but the build doesn't happen — possible causes?**
Wrong branch checked out, a `when` condition skipping the build stage, missing/misconfigured build tool on the agent (Maven/Node not installed or wrong version), agent label mismatch so it runs on the wrong node, or a silently failing early step that short-circuits before the build stage.

**5. Purpose of a webhook in CI/CD?**
Lets the Git provider push an event (e.g., on commit/PR) directly to Jenkins to trigger a build instantly, instead of Jenkins polling the repo on an interval — faster feedback and less load.

**6. How do you create/manage K8s clusters with Terraform — what are master and worker nodes?**
Use Terraform's `aws_eks_cluster` + node group resources (or the EKS module) to define the control plane and node groups declaratively. In EKS, the master (control plane — API server, etcd, scheduler) is fully managed by AWS; worker nodes are the EC2/Fargate capacity I manage that actually run pods.

**7. Common K8s errors and how you resolved them?**
CrashLoopBackOff — app crashing repeatedly, checked `kubectl logs` and fixed a bad config/missing env var. ImagePullBackOff — wrong image tag or missing registry credentials, fixed via correct `imagePullSecrets`. OOMKilled — pod exceeding memory limit, increased resource limits. Pending — insufficient node capacity, resolved by scaling the node group.

**8. Command to access a pod / create a K8s object?**
`kubectl exec -it <pod-name> -- /bin/bash` to get a shell inside a pod. Create an object with `kubectl apply -f manifest.yaml` (declarative, preferred) or `kubectl create -f manifest.yaml`.

**9. Helm chart folder structure and deploy commands?**
`Chart.yaml` (metadata/version), `values.yaml` (default config values), `templates/` (Go-templated K8s manifests), `charts/` (subcharts/dependencies). Deploy with `helm install <release> <chart>`, upgrade with `helm upgrade --install`, and validate with `helm lint`/`helm template`.

**10. Docker build stages — why ENTRYPOINT and CMD?**
Typical flow: `FROM` base image → `COPY`/`ADD` source → `RUN` install deps/build → `EXPOSE` port → `ENTRYPOINT`/`CMD` to run. ENTRYPOINT sets the fixed command that always runs; CMD supplies default arguments that can be overridden at `docker run` time — combining both gives a fixed executable with overridable defaults.

**11. How do you manage/connect services like DB, EC2, EKS, ECS? Command to connect to ECS?**
DB connection strings via K8s Secrets or AWS Secrets Manager, security groups scoping network access, IAM roles (IRSA for EKS, task roles for ECS) for AWS service access. To connect into a running ECS task: `aws ecs execute-command --cluster <cluster> --task <task-id> --container <name> --interactive --command "/bin/bash"`.

**12. Which container registry do you use?**
Mainly Amazon ECR, integrated with IAM for access control; Docker Hub for some public/less sensitive images.

**13. Branching strategy — how do you handle merges without breaking release? Production bug approach?**
Feature-branch workflow off `develop`, PR + review + CI checks required before merge, protected `main`/release branch needing approvals. For a production bug: cut a hotfix branch off `main`, fix and test it, fast-track merge and deploy, then backport the fix into `develop` so it isn't lost in the next release.

**14. Deployment flow / pipeline stages / how you ensure full quality checks?**
Checkout → unit tests → SonarQube quality gate (fails build if gate not passed) → Trivy filesystem + image scan → build → push to ECR → deploy via ArgoCD/Helm → post-deploy smoke test. Quality gate enforcement is what actually blocks bad code from progressing, not just running the scan.

**15. How are Jenkins shared libraries structured/integrated?**
Same as above: `vars/` for callable pipeline steps, `src/` for Groovy classes, imported via `@Library` at the top of each Jenkinsfile so multiple pipelines reuse the same logic instead of duplicating it.

**16. Security scanning tools — how do you scan images at build and registry level?**
Trivy for both filesystem and container image scanning in the pipeline before push; SonarQube for SAST/code quality. At the registry level, ECR also has built-in image scanning (scan-on-push) as a second layer of defense.

**17. Environment variables in Docker build — where do you store images?**
Pass build-time values with `--build-arg KEY=VALUE`, matched to an `ARG` instruction in the Dockerfile (for runtime config, use `-e` or K8s env/Secrets instead, not build args). Images stored in ECR primarily.

**18. How do you establish DB connections in your deployments?**
Connection details (host, port, credentials) injected via K8s Secrets or pulled from AWS Secrets Manager at runtime, security group rules allowing traffic from the app's subnet/SG to the DB port, and the app reads them as environment variables.

**19. How do you handle EKS authentication and secret storage?**
EKS auth uses the `aws-auth` ConfigMap (or newer EKS Access Entries) to map IAM roles/users to Kubernetes RBAC groups. Secrets are stored as K8s Secrets (optionally KMS-encrypted at rest) or centrally in AWS Secrets Manager/Parameter Store, synced into the cluster via External Secrets Operator.

**20. How do you create Lambda functions and manage/push artifacts?**
Define via Terraform/SAM/CLI, package code as a zip or container image, and push it either directly (`aws lambda update-function-code --zip-file`) or via CI/CD — upload the artifact to S3 first, then point Lambda to that S3 object for the update.

**21. What is email signing and Helm chart signing? Which tools?**
Helm supports GPG-based chart signing: `helm package --sign --key <key> --keyring <keyring>` produces a `.prov` provenance file, verified on install with `helm verify`. "Email signing" generally refers to the same GPG key mechanism used to sign commits/emails — same underlying trust model, different artifact.

---

## Set 3 — Git / EKS vs ECS / Linux / Terraform (5 YOE)

**1. Migrate a Git repo (e.g. GitHub → GitLab) with full commit history?**
`git clone --mirror <source-url>` to get a full mirror including all branches/tags/history, then `git push --mirror <destination-url>` to push everything to the new remote. No history is lost.

**2. git fetch vs git pull — when do you use each?**
`fetch` downloads remote changes into local tracking branches without touching your working branch — safe to review before merging. `pull` = fetch + merge (or rebase) into your current branch automatically. I use fetch when I want to inspect changes first, pull for a quick, low-risk sync.

**3. What is git cherry-pick?**
Applies one specific commit from another branch onto your current branch without merging the whole branch — `git cherry-pick <commit-hash>`. Useful for backporting a single fix to a release branch.

**4. How do you handle merge conflicts? Do you check history on source or target?**
Resolve the conflict markers in each file, `git add` the resolved files, then commit/continue the merge. I check `git log --oneline --graph` on both branches, but focus mainly on the target branch's recent history since that's what my changes are being merged into.

**5. What CI/CD tools do you use?**
Jenkins and GitHub Actions for CI, ArgoCD for GitOps-based CD, Helm for packaging deployments.

**6. New Jenkins install — connecting to GitHub, and how many ways?**
Two main ways: (1) Webhook — configure the GitHub repo webhook to POST to Jenkins' `/github-webhook/` endpoint, requires Jenkins to be reachable from GitHub; (2) Poll SCM — Jenkins periodically checks the repo for changes, works even if Jenkins isn't publicly reachable. I'd also set up a GitHub credential/token in Jenkins for API access (status checks, private repo cloning) regardless of trigger method.

**7. Different kinds of pipeline stages?**
Checkout, Build, Unit/Integration Test, Code Quality (SAST) scan, Security/Image scan, Package, Push to registry, Deploy, Post-deploy verification.

**8. Can more than two stages run at the same time?**
Yes — use the `parallel` block in a declarative pipeline to run independent stages concurrently, e.g., running lint and unit tests simultaneously.

**9. Have you done Groovy scripting from scratch? Declarative vs scripted pipeline?**
I mainly use declarative pipelines and write Groovy for shared library functions rather than full scripted pipelines. Declarative is structured, easier to read/lint, uses predefined sections (`pipeline{ stages{ stage{ steps{} } } }`); scripted is full imperative Groovy using `node{}` blocks — more flexible but steeper learning curve.

**10. Difference between EKS and ECS?**
EKS is managed Kubernetes — open standard, portable across clouds, more flexible but a steeper learning curve. ECS is AWS's own proprietary orchestrator — simpler, tightly integrated with AWS services, but not portable outside AWS and lacks the K8s ecosystem (Helm, operators, etc.).

**11. Prerequisites to set up an EKS cluster with 2 worker nodes?**
A VPC with public/private subnets across at least 2 AZs, an IAM role for the EKS control plane, an IAM role for worker nodes (with the EKS worker node, CNI, and ECR read-only policies attached), security groups, then create the control plane and a managed node group specifying instance type, count, and subnets.

**11. How do you manage load balancing across pods — are you sure it's ALB?**
Internally, the Kubernetes Service (ClusterIP) load-balances across pod endpoints via kube-proxy automatically. For external traffic I do use ALB (via the AWS Load Balancer Controller/Ingress) in most of my projects, but NLB is the right choice instead when it's non-HTTP/high-throughput/low-latency traffic.

**12. When do you use ALB vs NLB?**
ALB — Layer 7, HTTP/HTTPS, path/host-based routing — best for web apps and microservices. NLB — Layer 4, TCP/UDP, ultra-low latency, static IP support — best for high-throughput or non-HTTP protocols.

**13. Dockerfile has Tomcat on port 8080 — need the container to expose 9090. How?**
`EXPOSE` in the Dockerfile is just documentation, it doesn't change what port the app listens on. Simplest fix: run with a port mapping — `docker run -p 9090:8080 <image>` (host 9090 → container 8080). If the container itself must listen on 9090, you'd need to change Tomcat's `server.xml` connector port and rebuild the image.
*Follow-up: "Difference between EXPOSE and -p?" → EXPOSE just documents the container's listening port (informational, used by tools); -p actually publishes/maps a host port to it at runtime.*

**14. Use of Helm charts?**
Package Kubernetes manifests into reusable, versioned, parameterized templates — makes install/upgrade/rollback consistent and repeatable across dev, UAT, and prod using the same chart with different values.

**15. What have you worked on in Linux?**
File permissions, process management, systemd services, package management, shell scripting for automation, log troubleshooting (`journalctl`, `/var/log`), basic networking (`netstat`/`ss`, `iptables`).

**16. Command to get number of CPU cores?**
`nproc`, or `lscpu`, or `cat /proc/cpuinfo | grep -c processor`.

**17. What is a cronjob and how is it used?**
A scheduled task run by the cron daemon on a defined schedule (`crontab -e`, syntax: minute hour day month weekday). In Kubernetes, the equivalent is a `CronJob` resource that runs a Job on a schedule inside the cluster.

**18. How do you check the size of a particular file in a Linux folder?**
`du -sh <filename>` for one file, `du -sh *` to list sizes for everything in a directory, or `ls -lh` to see size in a regular listing.

**19. What kind of installations have you done on Linux?**
Docker, Jenkins, Java/Maven/Node runtimes, monitoring agents (Prometheus node exporter), AWS CLI, kubectl, Helm.

**20. Have you worked on Ansible?**
Some exposure — used playbooks for basic configuration management tasks like package installs and agent setup, but not at deep scale. Be honest here rather than overselling.

**21. What have you done with Terraform in AWS?**
Provisioned VPCs, EKS clusters, and RDS instances using modular Terraform — parameterized modules reused across dev/UAT/prod via variables.

**22. Terraform vs CloudFormation?**
Terraform is multi-cloud, uses HCL, has a larger module ecosystem, and you manage state yourself (often via remote backend like S3+DynamoDB). CloudFormation is AWS-native only, YAML/JSON, state is managed by AWS with tighter native integration (drift detection, StackSets).

**23. Given an AWS account, create a VPC and expose an EC2 service to the internet — what all comes into play?**
VPC with a public subnet, Internet Gateway, route table with `0.0.0.0/0` → IGW, Security Group allowing the needed inbound port, EC2 instance with a public/Elastic IP. For production I'd add an ALB in front, Route 53 for DNS, and ACM for HTTPS, plus a NAT Gateway if private resources need outbound internet.

**24. What is Transit Gateway?**
A central hub connecting multiple VPCs, VPNs, and Direct Connect links, replacing the need for a full mesh of VPC peering connections — each VPC attaches to the TGW and routing is controlled via TGW route tables.

**25. Top 5 technologies you're strongest in?**
AWS (EKS, EC2, IAM), Kubernetes, Jenkins/GitHub Actions CI/CD, Docker, Terraform.

**26. High-level architecture of Kubernetes?**
Control plane — API server (entry point for all requests), etcd (cluster state store), scheduler (places pods on nodes), controller manager (reconciles desired vs actual state). Worker nodes — kubelet (manages pod lifecycle), kube-proxy (networking rules), and the container runtime running the actual pods.

**27. What have you done with monitoring solutions?**
Prometheus + Grafana for cluster/app metrics and dashboards, CloudWatch for AWS-native resource monitoring and alarms.

---

## Set 4 — Troubleshooting / Cost / Terraform (4 YOE)

**1. Web application is not accessible but EC2 is running fine — major reasons?**
Security Group or NACL blocking the port, the app itself crashed or isn't listening on the expected port inside the instance, ALB target group health check failing (so it's removed from rotation), missing/incorrect route table or IGW attachment, Route 53 DNS pointing to the wrong target, or an app-level error (5xx) rather than an infra issue.

**2. What measures would you take to reduce infra cost by 20%?**
Right-size instances based on actual CPU/memory utilization, move non-prod workloads to spot instances, use Reserved Instances/Savings Plans for steady-state prod load, auto-scale down during off-hours, clean up unattached EBS volumes/old snapshots/unused Elastic IPs, and apply S3 lifecycle policies to move cold data to cheaper storage tiers.

**3. Write a Terraform config for an EC2 instance with an EBS volume attached.**
```hcl
resource "aws_instance" "app" {
  ami           = "ami-xxxxxxxx"
  instance_type = "t3.medium"
  subnet_id     = var.subnet_id

  tags = { Name = "app-server" }
}

resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.app.availability_zone
  size              = 50
  type              = "gp3"
}

resource "aws_volume_attachment" "data_attach" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.app.id
}
```

**4. What will you do for zero-downtime during an EKS cluster upgrade?**
Upgrade the control plane first (AWS-managed, brief and non-disruptive), then roll worker nodes one at a time — cordon, drain, replace with the new version, confirm healthy, move to the next node. Set PodDisruptionBudgets so the app always keeps a minimum number of replicas running during each drain.

**5. Have you written any automation script for cost optimization?**
Yes — scripts using AWS CLI/Python (boto3) to find unattached EBS volumes, unused Elastic IPs, and stopped instances still incurring EBS cost, scheduled via cron or Lambda to run regularly and send a report/alert.

**6. What is your Terraform file structure for VPC/EKS?**
`main.tf`, `variables.tf`, `outputs.tf` at the root, with reusable modules under `modules/vpc/` and `modules/eks/`, environment-specific values in `dev.tfvars`/`prod.tfvars`, and a `backend.tf` for remote state (S3 + DynamoDB lock).

**7. Get EC2/EBS counts across 50-60 AWS accounts without logging into each individually?**
Use AWS Organizations with a central management account, and either AWS Config aggregator / Resource Explorer for a built-in cross-account view, or a script that assumes a cross-account IAM role in each member account (via `sts assume-role`) and calls `describe-instances`/`describe-volumes`, aggregating results centrally — often orchestrated with Lambda + Step Functions for scale.

**8. What is Terraform init and Terraform refresh?**
`terraform init` sets up the working directory — downloads providers/modules and configures the backend. `refresh` (now folded into `plan`/`apply`) reconciles the state file with the real infrastructure's actual current status, without changing any config.

**9. How do you integrate SonarQube into your pipeline?**
Add a scan stage after build/test using the `sonar-scanner` CLI (or Jenkins' `withSonarQubeEnv`), pass the project key and auth token, and configure a Quality Gate webhook so the pipeline waits for and fails on a bad gate result — rather than just running the scan for visibility.

**10. What is the major Kubernetes issue you resolved?**
Best to reuse a real story here — e.g., the spot-instance-in-production slowness issue, or a CrashLoopBackOff root-caused to a missing environment variable, told as problem → diagnosis → fix → result.

---

### General note
Several of these ("AAF", Ansible depth, exact TGW-CIDR wording) sit right at the edge of what's in your resume — for those, the honest "I have exposure but not deep production experience" answer will land better than guessing. Interviewers at this level probe follow-ups specifically to catch overclaiming.
