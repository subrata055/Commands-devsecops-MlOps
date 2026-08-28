# Capgemini Interview Prep — All Rounds

---

## Round 1 (6+ yrs overall, 3 yrs DevOps)

### 1. How to assign memory to a pod, ensure it doesn't hit a constraint, and what to do if it does
Set `resources.requests.memory` (what the scheduler guarantees) and `resources.limits.memory` (hard cap) on the container. If a pod exceeds its limit, the kubelet **OOMKills** it and it restarts. To prevent it: right-size requests/limits using real usage data (metrics-server/VPA), leave headroom, and monitor OOMKilled events. If it happens: `kubectl describe pod` shows the OOMKilled reason, then either fix a memory leak in the app or raise the limit.
*Follow-up: What's the difference between request and limit, and how does the scheduler use requests?*

### 2. How to pass variables in Azure Pipelines / parameterize a pipeline
Use `parameters:` for values set at pipeline trigger/run time (with type-checking, shows as UI prompts), `variables:` for reusable values referenced as `$(varName)`, and **variable groups** (optionally linked to Azure Key Vault) for values shared across multiple pipelines.
*Follow-up: Difference between variables and parameters in Azure Pipelines?*

### 3. What is an Availability Zone — explain the layout in depth
An AZ is one or more physically separate, isolated data centers within a region, each with independent power/cooling/networking but linked to other AZs in the region via low-latency private links. Spreading resources across AZs (one subnet per AZ, nodes/instances distributed) protects against a single data-center failure. Most regions have 3+ AZs; RDS Multi-AZ, ALB, and EKS node groups are all built to be AZ-aware for HA.
*Follow-up: How does RDS Multi-AZ failover actually work?*

### 4. How does MySQL interact with Azure Key Vault privately, without going over the public internet
Store MySQL credentials as secrets in Key Vault, access them via a **Managed Identity** (no keys in code) over a **Private Endpoint** — this keeps traffic on Azure's private backbone instead of the public internet. Disable public network access on the Key Vault to enforce it.
*Follow-up: What's a Private Endpoint vs Private Link? How would you rotate the secret with zero downtime?*

### 5. Difference between git fetch and git pull (in depth)
`git fetch` downloads new commits/branches from the remote and updates remote-tracking refs (`origin/main`) — it never touches your working directory or current branch. `git pull` = fetch + merge (or rebase with `--rebase`) — it automatically merges fetched changes into your current branch, which can create a merge commit or conflicts. I prefer fetch + manual merge/rebase for control.
*Follow-up: When would you rebase instead of merge?*

### 6. What happens behind the hood when `git add` runs (in depth, Git's object database)
Git reads the file, computes its SHA-1 hash, zlib-compresses it, and stores it as a **blob object** under `.git/objects/`. It then updates the **index** (`.git/index`, the staging area) to point that filename at the new blob — the working tree file itself is untouched. On `git commit`, Git builds a **tree object** (the staged directory snapshot) and a **commit object** pointing to that tree plus its parent commit(s) — this blob → tree → commit chain is Git's content-addressable object database.
*Follow-up: How does Git avoid re-hashing a file that hasn't changed?*

---

## Round 2 (9 yrs overall, 5 yrs DevOps)

### Ansible

**1. What is an Ansible playbook?**
A YAML file defining one or more "plays" — each mapping a group of hosts to an ordered list of tasks/roles executed via modules over SSH, idempotently and agentlessly.

**2. Install Ansible on Ubuntu and RedHat, and start services**
Ubuntu: `sudo apt update && sudo apt install ansible -y`. RedHat: `sudo yum install epel-release -y && sudo yum install ansible -y`. Ansible is agentless — nothing to install/start on managed nodes, just SSH + Python. On the control node, `ansible --version` confirms install.
*Follow-up: Does Ansible need an agent on target hosts? (No — that's its main differentiator from Puppet/Chef.)*

**3. Create 3 users mapped to prod/task/QA groups in a single task**
```yaml
- name: Create users
  user:
    name: "{{ item.name }}"
    groups: "{{ item.group }}"
    state: present
  loop:
    - { name: 'user1', group: 'prod' }
    - { name: 'user2', group: 'task' }
    - { name: 'user3', group: 'QA' }
```
*Follow-up: Difference between `loop` and the older `with_items`?*

**4. How to include and input parameters in a playbook**
Via a `vars:` block, a separate `vars_files:`, CLI overrides with `-e "key=value"`, or by passing `vars:` inline when using `include_tasks`/`import_tasks` for reusable parameterized task files.
*Follow-up: Difference between include_tasks and import_tasks (dynamic vs static)?*

**5. What are Ansible roles?**
A standard directory structure (`tasks/`, `handlers/`, `templates/`, `vars/`, `defaults/`, `files/`, `meta/`) that packages reusable, shareable automation, invoked from a playbook via a `roles:` block.
*Follow-up: Which directory holds overridable default variables? (`defaults/main.yml`)*

**6. Use of templates in Ansible**
Jinja2 `.j2` files rendered dynamically with variables via the `template` module — used for config files (e.g. `nginx.conf.j2`) needing per-host or per-environment values.
*Follow-up: Difference between the `copy` and `template` modules?*

**7. Difference between templates and roles**
Templates are single Jinja2 files for dynamic config generation. Roles are the entire reusable automation package (tasks, handlers, vars, templates, files bundled together) — a role can contain templates, but they're not equivalent.

**8. Initialize a role and push it to Ansible Galaxy**
`ansible-galaxy init <role_name>` scaffolds the folder structure. Push the role's repo to GitHub, then either connect it via Galaxy's GitHub import or `ansible-galaxy publish` with an API key from your Galaxy profile.
*Follow-up: What has to be in meta/main.yml for Galaxy to accept it?*

**9. How to encrypt a playbook**
`ansible-vault encrypt playbook.yml` (or `ansible-vault encrypt_string` for a single variable) — prompts for a vault password and AES256-encrypts the file.

**10. How to execute a vault file**
`ansible-playbook playbook.yml --ask-vault-pass`, or `--vault-password-file <path>` to supply the password non-interactively (e.g. in CI).

**11.  How to use an environment variable for passwords**
Reference it as `"{{ lookup('env', 'DB_PASSWORD') }}"` in the playbook, or inject it into a task via the `environment:` block — keeps the secret out of vault/playbook entirely if it's sourced from CI secrets.
*Follow-up: Why combine env var injection with vault rather than relying on just one?*

**12. MySQL dump from encrypted data via Ansible playbook**
Store DB credentials in a vault-encrypted vars file, reference them in a `command`/`shell` task: `mysqldump -u {{ db_user }} -p{{ db_pass }} dbname > dump.sql`, run the playbook with `--ask-vault-pass`, then optionally use the `fetch` module to pull the dump file back to the control node.

**13.  Execute on all DB servers excluding one server**
`ansible-playbook playbook.yml --limit 'db_servers:!dbserver3'`

**14. Shut down all servers using an ad-hoc command**
`ansible all -m command -a "/sbin/shutdown -h now" -b`

**15. How to reduce execution time on an RDBMS server task**
Use `async`/`poll` so long-running tasks don't block, increase `forks` in `ansible.cfg` for more host parallelism, switch `strategy: free` instead of default linear, and skip unnecessary fact-gathering with `gather_facts: no`.
*Follow-up: Difference between linear and free strategy?*

**16. How to increase debug log level**
Run with `-v` / `-vv` / `-vvv` / `-vvvv` on `ansible-playbook` for increasing verbosity, or set `log_path` in `ansible.cfg` to persist logs to a file.

**17.  Difference between static and dynamic inventory**
Static inventory is a fixed INI/YAML file listing hosts/groups manually. Dynamic inventory is generated at runtime by a script or plugin (e.g. the AWS EC2 dynamic inventory plugin) that queries the cloud provider's API for current instances — essential when infrastructure changes via autoscaling.

### Kubernetes

**1.  Architecture of Kubernetes**
Control plane: API server (central hub everything talks through), etcd (cluster state store), scheduler, controller manager, cloud-controller-manager. Worker nodes: kubelet, kube-proxy, container runtime.
*Follow-up: What exactly does etcd store?*

**2. kubectl apply — how it's used with services**
`kubectl apply -f file.yaml` is a declarative create-or-update: it diffs the desired state in the YAML against live cluster state and patches only the difference — unlike `create` (fails if it exists) or `replace` (overwrites everything).

**3.  Deployment YAML file**
Core fields: `apiVersion`, `kind: Deployment`, `metadata` (name/labels), `spec` (`replicas`, a `selector` matching the pod template's labels, and the pod `template` with containers, resource requests/limits, ports).
*Follow-up: What actually connects a Service to a Deployment's pods? (label selector matching, not the Deployment name)*

**4.  Labels and annotations**
Labels are key-value pairs used for **selection/grouping** — Services and Deployments select pods by label. Annotations are metadata **not used for selection** — build info, descriptions, or config for tooling/controllers (e.g. ALB Ingress annotations).

**5. Traffic coming from outside into the cluster**
External request → cloud Load Balancer (provisioned by the Ingress Controller) → Ingress resource routing rules (host/path) → ClusterIP Service → kube-proxy routes it to a healthy pod via iptables/IPVS.

**6.  Controller manager's task**
Runs the core control loops (Node, ReplicaSet, Deployment, Endpoint controllers, etc.) that continuously watch actual cluster state via the API server and reconcile it toward the desired state in etcd.

**7.  Node affinity and anti-affinity**
Node affinity schedules pods onto nodes matching label rules (e.g. `disktype=ssd`), required or preferred. Pod anti-affinity keeps pods away from other pods matching a label — e.g. spreading replicas across nodes/AZs for HA.
*Follow-up: How is this different from taints and tolerations?*

**8. Run 2 pods where one depends on another — how to set that up**
Use an **initContainer** in the dependent pod to wait for/check the other service's readiness before the main container starts. For deployment-order dependency across resources, use Helm hooks or ArgoCD sync waves.

**9. Taint and toleration**
Taints are applied to **nodes** to repel pods (`kubectl taint nodes node1 key=value:NoSchedule`). Tolerations are applied to **pods**, letting them be scheduled on a tainted node despite the taint. Together they reserve nodes for specific workloads.

**10. Reason for tainting worker nodes**
To dedicate nodes to specific workloads (GPU nodes, spot nodes, a specific team) so general pods aren't scheduled there, or to mark a node as under maintenance so the scheduler avoids it.

**11.  How to limit resources in Kubernetes**
Container-level `resources.requests`/`resources.limits`, plus namespace-level **ResourceQuota** (total caps) and **LimitRange** (default/min/max per pod/container).

**12.  Blue-Green deployment**
Two full environments running side by side (Blue = live, Green = new version). Once Green is validated, switch all traffic instantly via Service selector or LB/Ingress. Instant rollback by switching back — costs double the resources during cutover.

**13. Canary deployment**
Gradually shift a small % of traffic to the new version while most stays on stable, monitor metrics, and progressively increase — Argo Rollouts or Flagger automate this with weighted traffic splitting.

**14. What is CSI?**
Container Storage Interface — a standard API letting Kubernetes provision/attach/mount storage from any vendor (EBS, Azure Disk, etc.) via a vendor-supplied CSI driver, without that logic living in Kubernetes core.

### AWS

**1. Lambda function and Step Function**
Lambda: serverless function that runs code on an event trigger, billed per invocation/duration, no server management. Step Functions: orchestrates multiple Lambdas/services into a visual state machine, handling retries, branching, and error handling between steps.

**2. Autoscaling policies and their uses**
Target Tracking (hold a metric like CPU at X%), Step Scaling (scale by defined increments off CloudWatch alarm thresholds), Scheduled Scaling (scale at known times). Used to match capacity to demand and control cost.

**3. Target tracking / target in autoscaling**
A target-tracking policy sets a target value for a metric (e.g. CPU 60%), and CloudWatch alarms automatically add/remove instances to hold that target.
*Follow-up (worth asking back): "Do you mean target-tracking scaling policy, or ALB target group health checks?" — the term is ambiguous and it's fine to clarify.*

**4. Which role to give to access AWS services**
An **IAM Role** (not a long-lived user key) — e.g. an EC2 instance profile, or **IRSA** (IAM Roles for Service Accounts) in EKS — scoped to least-privilege permissions.

**5. Configure a role for a service account (EKS/IRSA)**
Create an IAM role with a trust policy scoped to the cluster's OIDC provider, annotate the Kubernetes ServiceAccount with `eks.amazonaws.com/role-arn`, and pods using that ServiceAccount get temporary AWS credentials automatically via the EKS Pod Identity webhook.

**6. Service account end-to-end**
OIDC provider registered on the EKS cluster → IAM role trust policy scoped to that OIDC provider + specific namespace/ServiceAccount → K8s ServiceAccount annotated with the role ARN → pod uses that ServiceAccount → AWS SDK in the pod auto-assumes the role via the mounted projected token.

**7. Create a secret / service account for secrets**
`kubectl create secret generic <name> --from-literal=key=value`, reference via `envFrom`/`volumeMounts` in the pod spec. For AWS-managed secrets, use External Secrets Operator to sync from Secrets Manager into a native K8s Secret automatically.

**8. Static vs dynamic storage provisioning**
Static: admin pre-creates PersistentVolumes manually ahead of time. Dynamic: a StorageClass with a provisioner (e.g. EBS CSI driver) auto-creates a PV on-demand when a PVC is created — no manual PV needed.

**9. Type of error tied to pod labels**
If a Service's `selector` doesn't match any pod's labels (typo or mismatch), the Service has zero endpoints and traffic silently fails — check with `kubectl get endpoints <svc>` (empty) or `kubectl describe svc`.

---

## Round 3 (AWS / Terraform heavy)

**1. Difference between NAT Gateway and IGW**
IGW gives resources with public IPs in a public subnet **bidirectional** internet access. NAT Gateway lets resources in a **private subnet** make **outbound-only** internet calls (e.g. patching) while staying unreachable from the internet inbound.

**2. Pod in Pending state — troubleshoot steps**
`kubectl describe pod <name>` → check Events. Common causes: insufficient node CPU/memory for scheduling, no node matches nodeSelector/affinity/taints, an unbound PVC, or image pull failures blocking scheduling. Also check `kubectl get nodes` for capacity.

**3. Secondary RDS vs Read Replica**
"Secondary" usually means the standby in **Multi-AZ** — synchronous replication, automatic failover, not independently queryable. A **Read Replica** is asynchronous, can be cross-region, is directly queryable for read-offload, and can be manually promoted — but has no automatic failover.

**4.  Have you built RDS yourself or only managed it**
Answer from real experience — e.g. "I've provisioned RDS via Terraform/console, including Multi-AZ and read replicas, and manage day-to-day ops — backups, parameter groups, monitoring. The underlying replication engine itself is AWS-managed."

**5. Configure RDS so only one user can access at a time**
Restrict via **Security Group** (allow inbound only from one specific IP/SG), pair with IAM database authentication scoped to a single IAM principal, and if enforcing at the DB engine level, set `max_connections` low in the parameter group.
*Follow-up: "Where would you set that up?" — the Security Group attached to the RDS instance, within its DB Subnet Group.*

**6. Where do you set up RDS (subnet-wise)?**
In a **DB Subnet Group** spanning private subnets across multiple AZs in your VPC — not a single subnet — so Multi-AZ HA is possible.

**7. Upgrade MySQL 7.0 → 8.0 in RDS — process**
Take a manual snapshot first, review AWS's major-version upgrade/deprecation notes, test the upgrade against a cloned non-prod instance first, then run the upgrade via console/CLI (`modify-db-instance --engine-version 8.0`) during a maintenance window, and validate app compatibility after (MySQL 8 changes some defaults).
*Follow-up: Apply immediately or during a maintenance window, and why?*

**8. Multi-account: resources in one account, users in another — how to configure access**
Set up a **cross-account IAM role**: create a role in the resource account with a trust policy allowing the users' account/principal to assume it; users call `sts:AssumeRole` to get temporary credentials scoped to the resource account.

**9. "What about the VPC?" (follow-up)**
If the resource is network-isolated (e.g. RDS in a private VPC), you also need **VPC Peering** or a **Transit Gateway** between the two accounts' VPCs, plus route table and security group updates — IAM handles API-level access, networking handles reachability.

**10. Migrate an EC2 instance from one region to another**
Create an AMI of the instance in the source region, copy the AMI to the target region, then launch a new instance from that AMI there — recreate EBS volumes, security groups, Elastic IP, and DNS as needed. (EC2 instances can't move directly, only via AMI copy.)

**11.  EC2 creation error: "IP address exceeded" — troubleshoot**
The subnet has run out of available IPs. Fix: launch into a different subnet with free IPs, or create a new, larger subnet if VPC CIDR space allows.

**12. Can you extend a subnet's CIDR after creation?**
No — an existing subnet's CIDR block cannot be modified once created. You'd create a new, larger subnet and migrate resources into it.

**13. Will an instance in the new subnet reach instances in the old one?**
Yes — as long as both subnets are in the same VPC (or peered VPCs) with proper route tables and security groups allowing the traffic; same-VPC subnets route to each other by default.

**14. Terraform provisioners**
`local-exec` (runs a command on the machine running Terraform) and `remote-exec` (runs a command on the created resource via SSH/WinRM). Used sparingly — Terraform's own docs call provisioners a last resort; config management tools like Ansible are usually better for this.

**15. Remove a state file lock**
If a lock is stuck (e.g. a crashed apply), run `terraform force-unlock <LOCK_ID>` using the ID from the error message. With S3 + DynamoDB remote state, this clears the DynamoDB lock entry.

**16. Manage a console-created EC2 instance using Terraform**
Write a matching `resource "aws_instance"` block, then run `terraform import aws_instance.example <instance-id>` to bring it under state management without recreating it, then `terraform plan` to catch any config drift.

**17. Resources in Terraform**
A `resource` block defines an infrastructure object Terraform manages, e.g. `resource "aws_instance" "web" {...}` — a type and local name. Terraform tracks its real-world ID in state and owns its full lifecycle (create/update/destroy).

**18. Different types of Kubernetes Services**
ClusterIP (internal only, default), NodePort (exposes on each node's IP:port), LoadBalancer (provisions a cloud LB, external), ExternalName (maps to an external DNS name, no proxying).

**19. Multi-cloud: block a pod from scheduling on a particular node**
Apply a **taint** on that node (pods need a matching toleration to land there), or use **nodeAffinity with the `NotIn` operator** on a node label to explicitly exclude it.

**20. PVC**
PersistentVolumeClaim — a request for storage (size, access mode, StorageClass) that Kubernetes binds to a matching PersistentVolume (static) or dynamically provisions — decouples the pod from the underlying storage implementation.

**21. If `terraform import` works for existing resources, what's the point of a data source?**
`import` brings an existing resource **under Terraform's management** — Terraform now owns its lifecycle and can modify/destroy it. A **data source** only **reads/references** info about an existing resource (Terraform-managed or not) **without managing it** — e.g. looking up an existing VPC's ID to use in a new resource, with zero control over that VPC's lifecycle. Different purposes: ownership vs. read-only reference.
