# Alphadyne Interview 

## Part A — Alphadyne MCQ / Short Answer Round

### 1. Tool to automate deploy + configuration management for VMs and containers
**Ansible.** It's agentless (SSH-based), works uniformly across VMs and containers, and is the standard choice for config management vs. Terraform (which provisions infra, not configures running systems).

### 2. Module to install NGINX via Ansible on a new server
`apt` (Debian/Ubuntu) or `yum`/`dnf` (RHEL/CentOS) — or the generic `package` module if OS-agnostic. Example: `ansible.builtin.apt: name=nginx state=present`.

### 3 & 4. Module to ensure a specific package is installed on a new web server
Same as above — the **`package`** module (or OS-specific `apt`/`yum`) with `state: present`. It's idempotent — running it twice won't reinstall if already present.

### 5. Object to manage a K8s cluster and ensure a pod always has specific resources
Two things work together here: **resource `requests`/`limits`** set in the Pod spec guarantee CPU/memory for that pod, and a **`LimitRange`** object enforces default/min/max resource values at the namespace level so every pod gets sane defaults automatically.

### 6. Best command to monitor disk read/write activity
**`iostat`** (from the `sysstat` package) — shows per-device read/write throughput and utilization. `iotop` is the alternative if you need it per-process.

### 7. Where do you store a dev's public key to grant server access?
In `~/.ssh/authorized_keys` under that dev's user account on the target server (or centrally via IAM/SSM if using AWS-managed access).

### 8. Where are user passwords stored on modern Linux?
**`/etc/shadow`** — holds the hashed passwords (root-readable only). `/etc/passwd` holds user metadata but no password hash since the shadow suite was introduced.

---

## Part B — Terraform on Azure (Coding Task)

This is a build task, not a one-liner — but know the resource blocks cold so you don't blank on names:

| Requirement | Azure Resource |
|---|---|
| VNet with IP range | `azurerm_virtual_network` |
| Subnets (bastion/app/db) | `azurerm_subnet` (one block per subnet, note: AzureBastion subnet **must** be named `AzureBastionSubnet`) |
| NICs attached to subnets | `azurerm_network_interface` with `ip_configuration.subnet_id` |
| VMs with user/pass auth | `azurerm_linux_virtual_machine` / `azurerm_windows_virtual_machine` with `admin_username`/`admin_password`, `disable_password_authentication = false` |
| Public IPs | `azurerm_public_ip` |
| Bastion host | `azurerm_bastion_host` (needs its own subnet + public IP) |
| Load Balancer | `azurerm_lb` + `azurerm_lb_backend_address_pool` + `azurerm_lb_probe` + `azurerm_lb_rule`, NICs joined via `azurerm_network_interface_backend_address_pool_association` |

Say this out loud if asked verbally: *"I'd define the VNet and subnets first, then NICs scoped to the right subnet per tier, provision app VMs with those NICs, expose them behind an internal or public Load Balancer with health probes, and put Bastion in its own dedicated subnet for secure RDP/SSH without exposing the VMs' public IPs directly."*

Want me to write the actual working `.tf` files for this? I can do that as a separate file if you want to submit or practice with real code.

---

## Part C — Alphadyne Discussion Round (5 YOE)

### Introduce yourself
Lead with years of experience, current stack, and one concrete win — not a chronological history. *"5 years in DevOps/SRE, currently managing AWS + EKS infrastructure for an insurance-domain client at Navigator Software — CI/CD, cluster ops, and cost optimization, most recently cutting our DB spend by ~25% through reserved instances. Before that, CI/CD and security scanning (Trivy/SonarQube) at Unified Infotech."*

### Migrate a public EC2 app to a private subnet — AWS best practices
Move the instance to a private subnet with no public IP; put an **ALB in the public subnet** in front of it to handle inbound traffic; route outbound internet access (updates, package installs) through a **NAT Gateway**; tighten **security groups** so the instance only accepts traffic from the ALB's SG, not `0.0.0.0/0`; for HA, deploy across multiple AZs with the ALB and an Auto Scaling Group.

### How to provide HTTPS to an app in a private subnet
Terminate SSL at the **ALB** using a certificate from **ACM** (free, auto-renewing), listener on port 443 forwards to the target group on the instance's HTTP port — the instance itself doesn't need to handle TLS. Security group on the instance allows inbound only from the ALB's SG on the app port.

### ALB vs NLB, ACM, routing, security groups
**ALB** = Layer 7, for HTTP/HTTPS — supports path/host-based routing, ideal for microservices/web apps. **NLB** = Layer 4, for raw TCP/UDP at very high throughput/low latency — used when you need static IPs or non-HTTP protocols. **ACM** issues/manages TLS certs so you don't handle cert renewal manually. Security groups act as stateful firewalls — I chain them so only the ALB's SG is allowed into the app tier, and only the app tier's SG is allowed into the DB tier.

### Infrastructure changes you've worked on (architecture/optimization/challenges)
Use your real examples: moving prod off spot instances after capacity-driven slowdowns, right-sizing EC2→Reserved Instances (~$10K→$7.5K/month), and the on-prem→EKS rolling migration of 15 microservices with zero downtime. Pick whichever is most relevant to what they're hiring for and go deep — they'll follow up.

### One major production Kubernetes issue you solved (root cause, fix, prevention)
Use your spot-instance capacity issue: *"Root cause: prod nodes on spot instances hit capacity unavailability, causing pod evictions and slow response times. Fix: migrated prod node groups to on-demand while keeping spot for non-prod. Prevention: now spot is explicitly scoped to dev/UAT only in our node group configs, and we alert on spot interruption notices before they cause impact."* If you have a more K8s-specific incident (crash loop, OOMKill, bad rollout), swap it in — this format (root cause → fix → prevention) is what they're grading you on structurally.

### Branching strategy — why chosen, how it supports environments/releases/hotfixes
Describe what you actually use, e.g. GitFlow-lite: `main` (prod), `develop` (integration), feature branches off `develop`, `release/*` branches for QA/staging validation, `hotfix/*` branches cut directly from `main` for urgent prod fixes then merged back to both `main` and `develop`. Justify it: *"Chose it because it cleanly maps to our DEV/QA/PROD promotion flow and lets us patch prod urgently without waiting for the next full release cycle."*

### New app, only source code exists — design CI/CD to DEV/QA/PROD
*"I'd set up a pipeline triggered on PR merge to `develop`: lint/test → build image → push to registry → auto-deploy to DEV. Merge to `release/*` promotes to QA with the same image (never rebuild between environments — promote the same artifact). Merge to `main` triggers PROD deploy, gated by manual approval, using the identical image tag that passed QA. ArgoCD handles the actual sync per environment off environment-specific manifest branches or Helm value files."*

### Multibranch pipeline in Jenkins — config, problems solved, why preferred
Configure via a **Multibranch Pipeline job** pointing at the repo, with a `Jenkinsfile` in each branch — Jenkins auto-discovers branches/PRs and creates a pipeline per branch without manual job creation. Solves: no need to hand-create a Jenkins job for every feature branch, and each branch can have its own build logic if needed. Preferred over a normal SCM pipeline because it scales automatically as branches are created/deleted and supports PR-triggered builds out of the box.
