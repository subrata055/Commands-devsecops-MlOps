# DevOps Interview Prep — CGI & Cisco

---

## CGI (4.1 YOE)

### CI/CD & Jenkins

**How did you reduce a pipeline from 1 hour to 20 minutes?**
I profiled the pipeline first (Jenkins Blue Ocean stage timing) to find the bottleneck — usually sequential scan stages. Then I ran independent stages in parallel (build, SonarQube, Trivy), added Docker layer caching so unchanged layers aren't rebuilt, and cached dependencies (npm/maven `.m2`) between runs.
> **Follow-up:** *"Which stage was actually the bottleneck, and how did you find it?"* — Say you enabled stage timestamps/Blue Ocean view and found SonarQube + Trivy running back-to-back was the biggest chunk, then parallelized them with a `parallel {}` block.

**Write a checkout stage with Git credentials.**
```groovy
stage('Checkout') {
    steps {
        git branch: 'main',
            url: 'https://github.com/org/repo.git',
            credentialsId: 'github-creds-id'
    }
}
```
> **Follow-up:** *"How do you store credentials securely in Jenkins?"* — Jenkins Credentials Store (scoped to folder/project), never hardcoded in the Jenkinsfile; reference only by `credentialsId`.

**If everyone wants to use the same variables across pipelines, what approach would you use?**
A Jenkins Shared Library — define reusable variables/functions in a separate Git repo, then import with `@Library('my-shared-lib@v1') _` at the top of each Jenkinsfile.
> **Follow-up:** *"How do you version the shared library?"* — Tag or branch the library repo (`@Library('lib@v1.2')`) so pipelines can pin to a stable version.

**How do you call variables in a Jenkins pipeline?**
Via `env.VAR_NAME` for environment variables, `${params.PARAM_NAME}` for build parameters, and variables defined in the `environment {}` block are referenced the same way as `env.*`.
> **Follow-up:** *"Difference between the `environment` block and `params`?"* — `environment` sets/exports vars for the pipeline run; `params` are user-supplied inputs at build-trigger time (from `parameters {}` block).

**What is a Jenkins agent?**
The worker (VM, container, or Kubernetes pod) that actually executes the pipeline steps assigned by the Jenkins controller — defined via `agent any`, `agent { label 'x' }`, or `agent { kubernetes {...} }`.
> **Follow-up:** *"`agent any` vs `agent { docker 'image' }`?"* — `any` runs on any available static/labelled agent; `docker` spins up a fresh container from a specified image just for that stage, giving a clean, reproducible environment.

**Sample Dockerfile question.**
Likely overlaps with the multi-stage question below — see the Docker section. If asked for a simple one: `FROM base image → COPY app → RUN install deps → EXPOSE port → CMD run`. Always mention using a slim/alpine base and a non-root user for production.

### Troubleshooting

**Database connection from a pod is not working only for you — how do you troubleshoot?**
Check if it's environment-specific: exec into your pod and run `nslookup`/`dig` on the DB service name to rule out DNS; check if your pod is in a different namespace with a NetworkPolicy blocking it; check the DB security group/whitelist (maybe it only allows a specific subnet your pod's node isn't in); verify the DB credentials/secret mounted in your pod's deployment vs a working one.
> **Follow-up:** *"How do you check DNS resolution inside a pod?"* — `kubectl exec -it <pod> -- nslookup <service>.<namespace>.svc.cluster.local`.

**Database logs are not being written.**
Check disk space on the DB volume/PVC (full disk silently stops logging), check the DB user has write permission on the log path, check logging is actually enabled at the DB config level, and for managed DBs (RDS) check CloudWatch log export is turned on with the correct IAM role.
> **Follow-up:** *"How would you prevent this going forward?"* — Alert on disk usage threshold and ship logs externally (CloudWatch/Fluent Bit) so a full local disk doesn't lose them.

### Security

**What are CVEs?**
Common Vulnerabilities and Exposures — publicly disclosed, standardized identifiers for known security flaws in software, each with a CVSS severity score.
> **Follow-up:** *"What's the CVSS range, and what counts as critical?"* — 0–10; 9.0–10.0 is Critical, 7.0–8.9 High.

**What CVEs have you seen in production and how did you resolve them?**
Trivy flagged a known vulnerability in an old base image (e.g. outdated OpenSSL in Alpine) during the image scan stage — I updated the base image tag and rebuilt; separately, SonarQube/Trivy flagged a vulnerable npm/pip dependency, resolved by bumping to the patched version and re-running the pipeline gate.
> **Follow-up:** *"What if there's no patch available yet?"* — Apply a compensating control (network restriction, WAF rule), document the risk acceptance, and monitor until a fix ships.

**Name 5 tools to identify/fix CVEs.**
Trivy, Grype, Snyk, SonarQube (SCA), AWS Inspector — (Clair and Dependabot are good backups to mention if asked for more).
> **Follow-up:** *"Difference between SAST and SCA?"* — SAST scans your own source code for vulnerable patterns; SCA scans third-party/open-source dependencies for known CVEs.

### Docker

**Write a sample multi-stage Dockerfile.**
```dockerfile
FROM node:18 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```
> **Follow-up:** *"Why multi-stage?"* — Final image only has the built artifacts, not build tools/dev dependencies/source — smaller image, smaller attack surface, no leaked build secrets.

**"Mostly asked CI/CD in depth, write stages in detail."**
Have a full Jenkinsfile skeleton ready to write from memory:
```groovy
pipeline {
  agent any
  stages {
    stage('Checkout') { steps { git branch: 'main', url: '...', credentialsId: '...' } }
    stage('Build') { steps { sh 'npm ci && npm run build' } }
    stage('Unit Test') { steps { sh 'npm test' } }
    stage('SonarQube Scan') { steps { sh 'sonar-scanner' } }
    stage('Quality Gate') { steps { waitForQualityGate abortPipeline: true } }
    stage('Docker Build') { steps { sh 'docker build -t app:$BUILD_NUMBER .' } }
    stage('Trivy Scan') { steps { sh 'trivy image app:$BUILD_NUMBER' } }
    stage('Push Image') { steps { sh 'docker push app:$BUILD_NUMBER' } }
    stage('Deploy') { steps { sh 'argocd app sync my-app' } }
  }
}
```

---

## Cisco (6+ YOE) — Round 1

**Describe a situation where you had to improve the reliability of a critical system.**
Our production EKS nodes ran on spot instances to save cost, but spot interruptions caused intermittent slowness on a customer-facing system. I moved production node groups to on-demand while keeping spot for dev/UAT, which eliminated the interruption-driven slowdowns.
> **Follow-up:** *"How did you measure the improvement?"* — Compared error/latency metrics and pod-restart counts in Grafana before/after the change.

**What proactive monitoring solutions have you implemented?**
Prometheus + Grafana for cluster/pod metrics and dashboards, Alertmanager for threshold-based alerts (CPU, memory, restart counts), and CloudWatch alarms for AWS-managed resources like RDS.
> **Follow-up:** *"How do you avoid alert fatigue?"* — Tune thresholds to avoid noise, group related alerts, and route by severity so only actionable pages go to on-call.

**Write a playbook to deploy Nginx and ensure it's started/enabled on boot. How do you manage secrets in Ansible?**
```yaml
- hosts: webservers
  become: yes
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
    - name: Ensure nginx is running and enabled
      service:
        name: nginx
        state: started
        enabled: yes
```
Secrets: Ansible Vault to encrypt sensitive variables/files (`ansible-vault encrypt vars.yml`), run with `--ask-vault-pass` or a vault password file kept outside the repo; for dynamic secrets, integrate with AWS Secrets Manager or HashiCorp Vault instead of static encrypted files.
> **Follow-up:** *"How do you manage the vault password itself in CI?"* — Store it as a Jenkins/CI secret credential, never commit it, inject at runtime only.

**How would you migrate a Terraform backend from local to S3 + DynamoDB locking?**
Create the S3 bucket (versioning + encryption enabled) and a DynamoDB table with `LockID` as the partition key, add a `backend "s3" {}` block with bucket/key/region/dynamodb_table, then run `terraform init -migrate-state` to copy the existing local state over.
> **Follow-up:** *"Why DynamoDB specifically?"* — It provides the locking mechanism so two people/pipelines can't `apply` concurrently and corrupt state.

**What happens if the Terraform state becomes corrupted, and how do you recover?**
Restore from the S3 bucket's versioned history (previous good version) or the local `terraform.tfstate.backup` file; if neither is usable, use `terraform state pull`/`push` to hand-edit, or worst case re-`import` each resource into a fresh state.
> **Follow-up:** *"How do you prevent this happening again?"* — Enforce remote state + locking, restrict who can run `apply` directly, and keep bucket versioning on.

**Write Terraform code for an EC2 instance with a security group allowing only SSH access.**
```hcl
resource "aws_security_group" "ssh_only" {
  name = "allow-ssh"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["<your-ip>/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami                    = "ami-xxxxxxxx"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.ssh_only.id]
}
```
> **Follow-up:** *"Why not `0.0.0.0/0` for the SSH ingress?"* — Opens SSH to the entire internet — restrict to a known IP/CIDR or use SSM Session Manager instead of exposing port 22 at all.

**Explain setting up a multi-branch Jenkins pipeline for a GitHub repo.**
Create a "Multibranch Pipeline" job pointing at the GitHub repo; Jenkins auto-discovers branches/PRs (via webhook or polling) and runs each branch's own `Jenkinsfile` automatically — no manual job per branch.
> **Follow-up:** *"How do you route different branches to different environments?"* — Use `when { branch 'main' }` / `when { branch 'develop' }` conditionals in stages to target prod vs dev.

**How would you implement dynamic stages based on environment variables?**
```groovy
stage('Deploy') {
    when { expression { return env.DEPLOY_ENV == 'prod' } }
    steps { echo 'Deploying to prod' }
}
```
For fully dynamic stage generation (not just skipping), a scripted pipeline with a loop building stages programmatically is more flexible than declarative.
> **Follow-up:** *"Declarative vs scripted — when do you need scripted?"* — Scripted gives full Groovy control (loops, conditionals building stages at runtime); declarative is simpler/more readable but less flexible for generated stages.

**Explain the EKS upgrade process for zero downtime. What do you verify post-upgrade?**
Upgrade the control plane first (AWS manages this for EKS), then upgrade node groups one at a time — cordon and drain each node (respecting PodDisruptionBudgets so minimum replicas stay available), let pods reschedule onto updated nodes, verify health, then move to the next node.
Post-upgrade: confirm all nodes report the new version, all pods are Running/Ready, check add-on version compatibility (VPC CNI, CoreDNS, kube-proxy), re-check for deprecated API usage in manifests, and confirm ingress/LB traffic is routing correctly.
> **Follow-up:** *"What's a PodDisruptionBudget and why does it matter here?"* — It guarantees a minimum number of replicas stay available during voluntary disruptions like node drains, preventing a service from dropping to zero pods mid-upgrade.

**Write a script to monitor a directory and auto-copy new files to a remote server via SCP.**
```bash
#!/bin/bash
WATCH_DIR="/path/to/watch"
REMOTE="user@remote-host:/path/to/dest"
KEY="/path/to/key.pem"

inotifywait -m -e create -e moved_to "$WATCH_DIR" |
while read path action file; do
    scp -i "$KEY" "$path$file" "$REMOTE"
done
```
> **Follow-up:** *"What if `inotify-tools` isn't available?"* — Fall back to a cron job that diffs a directory listing every N minutes, or `rsync` on an interval instead of real-time watching.

---

## Cisco — Round 2

**Write a playbook to install Apache on a VM.**
Same shape as the Nginx one — swap the package name (`apache2` on Debian/Ubuntu, `httpd` on RHEL) and service name accordingly.
> **Follow-up:** *"How do you handle OS differences (Debian vs RHEL) in one playbook?"* — Use `ansible_facts['os_family']` conditionals or separate `vars/Debian.yml` / `vars/RedHat.yml` included via `include_vars`.

**How do you migrate the state file from local to S3? What if it gets lost?**
Same as the earlier backend-migration answer (`backend "s3"` block + `terraform init -migrate-state`). If lost: restore from S3 versioning, or the local `.tfstate.backup`, or rebuild via `terraform import` per resource as a last resort.

**Terraform scripts for AWS services, Jenkinsfile, EKS and on-prem Kubernetes upgrade steps.**
Modular Terraform (separate VPC/EKS/RDS modules) provisioned through Jenkinsfile stages running `terraform plan`/`apply`. EKS upgrade: control-plane-first (AWS-managed) then rolling node-group upgrade. On-prem (kubeadm) cluster: `kubeadm upgrade plan` → `kubeadm upgrade apply` on the control plane, then drain/upgrade `kubelet`+`kubectl` on each worker node one at a time.
> **Follow-up:** *"How does kubeadm upgrade differ from EKS's managed upgrade?"* — With kubeadm you manually run each control-plane upgrade step yourself; EKS handles control-plane upgrades for you and you only manage node groups.

**Shell script: VM1 (ubuntu, SSH key auth) copies `/nobackup` to another VM.**
```bash
#!/bin/bash
rsync -avz -e "ssh -i /path/to/key.pem" /nobackup/ user@remote-vm-ip:/destination/path/
```
> **Follow-up:** *"Why `rsync` over plain `scp`?"* — `rsync` only transfers changed files (incremental), which matters for repeated/large syncs; `scp` re-copies everything each time.

**Jenkins + Kubernetes: a pod keeps restarting — what steps do you take?**
`kubectl describe pod <pod>` to see the restart reason (OOMKilled, CrashLoopBackOff, failed probe); `kubectl logs <pod> --previous` to see the crash output from before the restart; check resource `limits` (too low memory causes OOMKill) and liveness-probe config (too aggressive timing kills healthy pods).
> **Follow-up:** *"CrashLoopBackOff vs OOMKilled — different root causes?"* — CrashLoopBackOff usually means the app itself is erroring/exiting; OOMKilled specifically means it exceeded its memory limit and was killed by the kubelet.

**If deployment gets a timeout issue, what API gateway do you use, and how do you handle it?**
AWS ALB (with Ingress Controller) or API Gateway in front of services; for timeouts I check the ALB's idle timeout setting, confirm backend health-check/readiness config, and check connection draining settings during deploys.
> **Follow-up:** *"How do you increase ALB idle timeout?"* — Set the `idle_timeout` load balancer attribute (default is 60s).

**How did you manage security at the application level?**
IAM roles for service accounts (IRSA) so pods only get the AWS permissions they need, secrets via AWS Secrets Manager/Vault instead of hardcoding, NetworkPolicies + RBAC inside the cluster, TLS everywhere, and dependency/image scanning (Trivy/SonarQube) in the pipeline before anything ships.

**How do you secure a public API for an on-prem setup (no cloud WAF available)?**
Put a reverse proxy/API gateway (Nginx or Kong) in front with rate limiting and auth (API key/OAuth2/mTLS), restrict admin endpoints via firewall or VPN, and keep patching current since there's no managed cloud security layer to fall back on.
> **Follow-up:** *"How do you handle DDoS protection on-prem?"* — Rate limiting at the reverse proxy, `fail2ban` for repeated abuse, and optionally an upstream scrubbing/CDN service in front even for on-prem origins.

**Where and how do you check application performance metrics?**
Grafana dashboards fed by Prometheus for the RED metrics (Rate, Errors, Duration) at the service level, plus CloudWatch for AWS-managed resource metrics, and application/slow-query logs for deeper root-cause digging.
> **Follow-up:** *"What's the difference between RED and USE methodology?"* — RED (Rate/Errors/Duration) is for measuring services; USE (Utilization/Saturation/Errors) is for measuring resources like CPU/disk/network.
