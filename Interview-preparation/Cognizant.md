# DevOps Interview Prep — CTS (Cognizant) Rounds

---

## Round 1 — Azure/Networking focus

### 1. What is connection draining?
When you remove/replace an instance behind a load balancer, connection draining keeps existing in-flight requests alive for a configurable timeout instead of killing them abruptly, while new requests stop being routed to that instance. Prevents users mid-request from getting errors during deploys or scale-down.
**Follow-up:** *What's the default/typical drain timeout, and what happens if a request doesn't finish before it expires?* → Typically configurable (e.g. 30-300s on AWS ALB, `deregistration_delay`); if it doesn't finish in time, the connection is forcibly terminated.

### 2. `backend.tf` is in the repo but it is not showing in the storage account — what may be the issue?
`backend.tf` only *defines* where state should live (storage account, container, key) — it doesn't create that backend or push state there by itself. Likely causes: `terraform init` was never run (or run without picking up the new backend config), the storage account/container name in `backend.tf` doesn't match what actually exists, missing IAM/SAS write permissions on that storage account, or someone applied locally before the backend was configured and state was never migrated.
**Follow-up:** *How do you migrate existing local state to a new remote backend?* → Add/update the backend block, run `terraform init`, and Terraform prompts to copy existing local state into the new remote backend.

### 3. How to login to a VM if the VM has a private IP?
Can't connect directly from the public internet. Options: a bastion host/jump box in a public subnet that you SSH into first, then hop to the private VM; a VPN into the VNet/VPC; or cloud-native tools like AWS SSM Session Manager / Azure Bastion which don't require any inbound port open at all.
**Follow-up:** *Why is SSM Session Manager / Azure Bastion preferred over a bastion host?* → No open SSH port, no key management, all access is IAM/AD-authenticated and logged — smaller attack surface.

### 4. Web app was working fine, went down, networking and ports all fine — how to troubleshoot?
*(Your draft was already good — reordered by what I'd actually check first, since "app is up but suddenly down with networking confirmed fine" points at the app/host layer, not the network.)*
Check application/service logs first (nginx/apache/app process — is it even running, and what's the last error before it died) → check server resource usage (memory/CPU/disk — OOM kill is the most common silent cause of "was fine, now down") → check for a bad recent deploy or config change → verify SSL cert hasn't expired → DNS resolution (`nslookup`) as a sanity check → browser cache last, since that's a client-side long-shot, not a server outage cause.
**On your specific list:** your 7 points are all individually valid — the only fix is ordering. Lead with logs + resource exhaustion (highest probability), put cache-clearing near the end (lowest probability for a full outage).
**Follow-up:** *What's the very first command you'd run?* → `systemctl status <service>` or check the pod/container logs immediately — fastest signal.

### 5. Types of load balancers
Layer 4 (transport layer — routes by IP/port, e.g. AWS NLB) vs Layer 7 (application layer — routes by HTTP path/host/headers, e.g. AWS ALB, Azure App Gateway). Also classified as internal vs internet-facing, and classic/legacy vs modern (ALB/NLB).
**Follow-up:** *When would you pick NLB over ALB?* → Need for extreme low latency/high throughput, a static IP, or non-HTTP protocols (TCP/UDP) — ALB is for HTTP/HTTPS-aware routing.

### 6. What is Azure App Gateway and how does it encrypt HTTP/HTTPS traffic?
It's Azure's Layer-7 load balancer/WAF — does path-based routing, SSL/TLS termination, session affinity, and autoscaling. For encryption: it terminates TLS at the gateway (decrypts using an uploaded certificate), can optionally re-encrypt traffic to the backend for end-to-end TLS, and supports SNI for multiple certs on one gateway.
**Follow-up:** *SSL termination vs SSL passthrough?* → Termination decrypts at the gateway then forwards (plain or re-encrypted); passthrough forwards encrypted traffic untouched to the backend, which does its own decryption.

### 7. App is down and throwing 503 — what steps should be taken?
503 means the server/gateway is up but the backend service isn't responding. Check backend health checks on the load balancer (is the target marked unhealthy?) → check if the app process crashed or is resource-starved (memory/CPU) → check backend connection pool/timeout settings → check for a bad deploy or scaling event that dropped healthy instance count to zero.
**Follow-up:** *503 vs 502 — what's the difference?* → 502 = backend sent an invalid response (bad gateway); 503 = backend is unavailable/overloaded (service unavailable) — 503 often points to autoscaling or health-check issues.

---

## Round 2 — AWS/K8s deeper dive (3-4 yr level)

### 8. How do you manage the Terraform state file?
Store it remotely (S3 + DynamoDB for locking, or Azure Storage with blob leasing) instead of local — enables team collaboration and prevents concurrent-edit corruption. Never commit state to Git (it can contain secrets in plaintext). Use workspaces or separate state files per environment.
**Follow-up:** *What happens if two people run `apply` at the same time without locking?* → State corruption/race condition — one person's changes can overwrite the other's, which is exactly what DynamoDB locking prevents.

### 9. How would you design an architecture for a 2-tier application?
Web/app tier in a public (or via ALB) subnet handling requests, database tier in a private subnet with no direct internet access — reachable only from the app tier via security group rules. Add a NAT Gateway for the private subnet's outbound needs (patches, etc.), and a load balancer in front of the app tier for HA.
**Follow-up:** *How would you make this highly available?* → Deploy across multiple AZs, use Multi-AZ RDS for the DB tier, auto-scaling group for the app tier.

### 10. Difference between subnet and NACL?
A subnet is a range of IP addresses within a VPC — a network segment. A NACL (Network ACL) is a stateless firewall attached *to* a subnet, controlling inbound/outbound traffic at the subnet boundary via allow/deny rules evaluated in order.
**Follow-up:** *NACL vs Security Group?* → NACL is stateless (need explicit inbound AND outbound rules) and subnet-level; Security Group is stateful (return traffic auto-allowed) and instance/ENI-level.

### 11. Difference between NAT Gateway and Internet Gateway?
Internet Gateway allows resources with public IPs to send/receive traffic directly to/from the internet (bidirectional). NAT Gateway lives in a public subnet and lets private-subnet resources initiate *outbound* internet traffic (e.g. for updates) without exposing them to inbound internet traffic.
**Follow-up:** *Can a NAT Gateway allow inbound connections initiated from the internet?* → No — only outbound-initiated traffic and its return traffic.

### 12. How would you trigger Pipeline B in Jenkins automatically after Pipeline A finishes?
Use the `build` step in a declarative/scripted Jenkinsfile (`build job: 'PipelineB'`) in Pipeline A's post/success block, or configure Pipeline A with a "Build other projects" post-build action, or set up an upstream/downstream trigger relationship in Jenkins job config.
**Follow-up:** *How would you pass parameters from Pipeline A to B?* → `build job: 'PipelineB', parameters: [string(name: 'X', value: params.X)]`.

### 13. How will you know if a network policy is enabled or not in K8s?
Run `kubectl get networkpolicy -A` to see if any policy resources exist. But existence of the resource doesn't guarantee enforcement — that depends on the CNI plugin (Calico, Cilium, or the AWS VPC CNI with policy support enabled). To confirm enforcement, actually test it: try to `curl`/`exec` between pods that should be blocked.
**Follow-up:** *Does the default AWS VPC CNI enforce NetworkPolicies?* → Not by default — needs Calico or the VPC CNI's network policy feature turned on.

### 14. Difference between ClusterRole and ClusterRoleBinding?
ClusterRole defines a set of permissions (verbs on resources) cluster-wide, not scoped to a namespace. ClusterRoleBinding actually grants those permissions to a user/group/service account cluster-wide. Role defines permissions, Binding assigns them — same relationship as Role/RoleBinding but cluster-scoped instead of namespace-scoped.
**Follow-up:** *Can a ClusterRole be bound within a single namespace only?* → Yes — bind it via a namespace-scoped RoleBinding instead of a ClusterRoleBinding.

### 15. What will happen when an IaC-managed resource is modified manually? How would you avoid it?
Terraform state now diverges from real infrastructure ("drift") — the next `plan`/`apply` will either try to revert the manual change or show unexpected diffs. Prevention: restrict console/CLI write access via IAM so only the pipeline can modify resources, run scheduled `terraform plan` in CI to catch drift, and for GitOps-managed K8s resources, ArgoCD auto-reverts manual changes to match Git.
**Follow-up:** *How do you detect drift proactively rather than waiting for the next apply?* → A scheduled drift-detection `terraform plan` job in CI, or tools like driftctl.

### 16. Difference between DaemonSet and StatefulSet?
DaemonSet ensures exactly one pod runs on every (or selected) node — used for node-level agents like log collectors or monitoring exporters. StatefulSet manages pods with stable, unique identities and persistent storage per pod (ordered creation/scaling, stable network names) — used for stateful apps like databases.
**Follow-up:** *Why can't you just use a Deployment for a database?* → Deployments give pods random names/no guaranteed persistent volume binding per pod — StatefulSet guarantees stable identity and storage across restarts.

### 17. How would you set up networking in a VPC?
Define the VPC CIDR, split into public and private subnets across multiple AZs, attach an Internet Gateway for public subnets, add a NAT Gateway in a public subnet for private subnet outbound access, set up route tables per subnet type, and configure security groups/NACLs for traffic control.
**Follow-up:** *Why multiple AZs?* → High availability — if one AZ fails, resources in the other AZ(s) keep the app running.

### 18. How will you direct traffic to and from an instance in a private subnet?
Outbound: route table sends internet-bound traffic through a NAT Gateway in a public subnet. Inbound from the internet: not direct — traffic comes via a load balancer in a public subnet that forwards to the private instance, or via VPN/Direct Connect for internal access.
**Follow-up:** *Can a private-subnet instance have a public IP directly?* → No — private subnets don't route to an Internet Gateway, so a public IP alone wouldn't make it reachable.

---

## Round 3 — General + scripting

### 19. Day-to-day tasks
Same as before — Grafana/Prometheus dashboard checks each morning, triaging pipeline failures, EKS cluster maintenance, and cost/infra management.

### 20. How did you reduce the sizes of Docker images?
Switched to multi-stage builds (build in one stage, copy only the final artifact into a slim runtime stage), used alpine/distroless base images instead of full OS images, and added a `.dockerignore` to avoid copying unnecessary files/dependencies into the image.
**Follow-up:** *Give a rough before/after size number.* → Have a real number ready from your project (e.g. "cut a ~900MB image to ~150MB using multi-stage + alpine").

### 21. Explain the CI/CD pipeline used
GitHub → Trivy filesystem scan → SonarQube code quality/vulnerability scan → build → Trivy image scan → push to ECR/Docker Hub → ArgoCD (GitOps) syncs the new image to EKS, with Helm used in some projects.

### 22. What have you done in Kubernetes?
Managed EKS clusters end-to-end: namespace design, deployments/services/ingress configuration, NetworkPolicies, cluster upgrades with node draining, monitoring via Grafana, and GitOps-based deployment via ArgoCD.

### 23. How did you write deployment files for microservices, and configure services/ingress?
Each microservice got its own Deployment manifest (image, replicas, resource requests/limits, readiness/liveness probes), a ClusterIP Service for internal access, and shared Ingress rules routing by path/host to the right service via the ALB Ingress Controller.
**Follow-up:** *What do readiness and liveness probes each do?* → Liveness restarts a container if it's stuck/unhealthy; readiness controls whether traffic is sent to it at all — a pod can be alive but not ready.

### 24. Did you configure Ingress and Egress rules?
Yes — Ingress rules on the Ingress resource for path-based routing to services, and Egress rules via NetworkPolicies/security groups to control what the pods are allowed to reach outbound (e.g. restricting database pods to only talk to specific internal services).

### 25. What have you done in Terraform and how did you do the integration?
Wrote reusable modules (VPC, EKS, RDS) parameterized by environment, integrated it into the pipeline so `terraform plan` runs on PR and `apply` runs on merge to main (with a manual approval gate for prod), state stored remotely in S3 with DynamoDB locking.

### 26. Difference between `terraform destroy` and `terraform refresh`?
`destroy` tears down all resources tracked in state. `refresh` (now largely folded into `plan`/`apply -refresh-only`) just updates the state file to match real-world resource status — no infrastructure changes, just syncing Terraform's knowledge of what exists.

### 27. How to prevent someone from running `terraform destroy` or destroying the infra?
Restrict IAM/pipeline permissions so `destroy` isn't callable by individuals directly — only through a gated CI pipeline. Use `prevent_destroy = true` lifecycle blocks on critical resources, require PR approval + manual approval gate for any apply/destroy in prod, and keep prod state locked down separately from dev/UAT.
**Follow-up:** *What does `prevent_destroy` actually block — CLI destroy too, or just plan/apply?* → It blocks any plan (including inside a destroy) that would destroy that specific resource — Terraform errors out before applying.

### 28. How did you do cost optimization in your project?
Concrete example: moved a heavily-used EC2 database from on-demand to Reserved Instance pricing, cutting cost from ~$10K to ~$7.5K/month; also used spot instances for dev/UAT (not prod) node groups to cut compute cost further.

### 29. Python — separate list items by starting letter
```python
items = ['abc', 'vca', 'abc', 'bca']

a_items = [i for i in items if i.startswith('a')]
b_items = [i for i in items if i.startswith('b')]

print("Starting with 'a':", a_items)
print("Starting with 'b':", b_items)
```
**Output:** `Starting with 'a': ['abc', 'abc']` and `Starting with 'b': ['bca']`
**Follow-up:** *How would you generalize this for any set of starting letters, not just a/b?* → Use a `defaultdict(list)` and bucket by `item[0]`:
```python
from collections import defaultdict
buckets = defaultdict(list)
for i in items:
    buckets[i[0]].append(i)
```

### 30. What have you done in Ansible?
Used Ansible playbooks for configuration management — installing packages, managing config files, and orchestrating multi-server setup tasks that don't fit the Kubernetes/container workflow (e.g. bootstrapping VMs before they join a cluster).

### 31. If an Ansible playbook keeps running for 2-3 hours, what are your next steps?
Check which task it's stuck on with `-vvv` verbose output, check if it's hanging on a specific host (network issue, waiting on a prompt, or an unbounded loop), verify `async`/`poll` settings if it's a task that should be backgrounded, and check target host resource usage in case the host itself is unresponsive.
**Follow-up:** *How would you make a genuinely long-running task not block the whole playbook?* → Use `async: <seconds>` with `poll: 0` to fire-and-forget, then check status later with `async_status`.

### 32. Ansible Tower?
Tower (now AWX/Ansible Automation Platform) is a web UI + API layer on top of Ansible for centralized job scheduling, RBAC, credential management, and audit logging — used to run playbooks in a controlled, auditable way instead of ad-hoc from the CLI.
**Follow-up:** *Have you used it hands-on or only conceptually?* → Be honest here — if it's conceptual only, say so and pivot to what you *have* used for orchestration (Jenkins/GitHub Actions).
