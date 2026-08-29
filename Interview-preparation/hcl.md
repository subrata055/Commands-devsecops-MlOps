# HCL Interview Prep — All Sets

---

## SET 1 — HCL (exp 4-5 yrs) — Git / CI Pipeline Basics

**1. What Git branching strategy is used in your organisation?**
We use environment-mapped branching: `develop` → auto-deploys to Dev, a `release`/`uat` branch → deploys to UAT, and `main` → deploys to Prod after PR approval. Feature branches are cut from `develop` and merged back via PR with mandatory review.
*Follow-up: "What if two features conflict?" → Rebase the feature branch on latest `develop` before raising the PR, resolve conflicts locally.*

**2. How is deployment done in different environments using the Git repo?**
Each environment maps to a branch or a tag; the pipeline is triggered on push/merge to that branch, and the pipeline reads environment-specific variables (via `.tfvars`, Helm `values-<env>.yaml`, or pipeline variable groups) to deploy the same code differently per environment.

**3. How and from where do you clone the repo — local repo, then push to remote, or direct?**
You clone the **remote repo directly** (`git clone <url>`) to your machine or CI runner — that creates a local `.git` copy linked to the remote as `origin`. There's no separate "local repo you build first" step; the confusion is because every clone technically creates a full local Git repo, but you always start from an existing remote (GitHub/GitLab/Azure Repos), not the other way around. Auth is via SSH key or PAT.

**4. What is a PAT (Personal Access Token)?**
A token used instead of a password for Git operations over HTTPS (or API calls) — it's scoped to specific permissions (repo read/write, pipeline trigger, etc.), has an expiry, and can be revoked independently without changing your account password.

**5. How do you configure SonarQube?**
Install/run the SonarQube server, create a project and generate a project token, then add a `sonar-project.properties` file (or scanner CLI args) in the repo specifying project key, source paths, and language. The pipeline runs `sonar-scanner` with that token, and a Quality Gate (pass/fail threshold) is defined on the SonarQube server side.

**6. How do you integrate Azure Key Vault in Jenkins / Azure Pipelines?**
In Azure Pipelines: create a service connection to Azure using a Service Principal, then use the **Azure Key Vault task** to pull secrets into pipeline variables at runtime. In Jenkins: install the Azure Key Vault plugin, configure the vault URL and SP credentials, then reference secrets as environment variables in the pipeline.

**7. How do you handle a merge conflict when two people edit the same file?**
Pull the latest changes, Git flags the conflicting lines with `<<<<<<<`/`=======`/`>>>>>>>` markers — manually edit to keep the correct combined code, then `git add` and commit (or continue the rebase). Ways to resolve: manual edit, a merge tool (`git mergetool`), or coordinate with the other person on intent if it's not obvious which change should win.
*Follow-up: "How do you avoid conflicts in the first place?" → Smaller, frequent commits; pull/rebase often; avoid long-lived feature branches.*

**8. What's the output of SonarQube, and how do you fix issues found?**
Output includes: Bugs, Vulnerabilities, Code Smells, Security Hotspots, Duplication %, and Coverage %, rolled up into a pass/fail Quality Gate. Fix by triaging by severity — blocker/critical first — refactoring the flagged code, then re-running the scan to confirm the gate passes before merge.

**9. Where do you write the code/YAML file for the pipeline?**
In the repo itself, as pipeline-as-code — `Jenkinsfile` for Jenkins, `.github/workflows/*.yml` for GitHub Actions, `azure-pipelines.yml` for Azure DevOps, `.gitlab-ci.yml` for GitLab.

**10. What's inside a Dockerfile?**
Base image (`FROM`), working directory (`WORKDIR`), dependency install (`RUN`), copy source code (`COPY`), environment variables (`ENV`), exposed port (`EXPOSE`), and the start command (`CMD`/`ENTRYPOINT`).

**11. How do you schedule a pipeline to run against a stage/main branch after validating an update?**
Use branch filters/triggers on the pipeline — configure it to trigger automatically on push/merge to `stage` or `main`, or trigger it manually specifying the target branch as a parameter ("Build with Parameters" in Jenkins, or manual run with branch selector in Azure/GitHub Actions). A cron/scheduled trigger can also be added for time-based runs against a fixed branch.

---

## SET 2 — HCL — Kubernetes Deep Dive

**1. What's the difference between PV and PVC?**
A PersistentVolume (PV) is the actual storage resource provisioned in the cluster (by an admin or dynamically via a StorageClass). A PersistentVolumeClaim (PVC) is a request for storage made by a pod/user — Kubernetes binds the PVC to a matching PV.

**2. Explain Kubernetes architecture.**
Control plane: API server (entry point for all requests), scheduler (assigns pods to nodes), controller manager (reconciles desired vs actual state), etcd (cluster state store). Worker nodes: kubelet (talks to API server, runs pods), kube-proxy (networking rules), and the container runtime.

**3. Difference between Deployment and StatefulSet?**
Deployment manages stateless, interchangeable pods — no stable identity, any replica can be replaced by any other. StatefulSet is for stateful apps needing stable network identity and storage per pod — ordered, predictable pod names (`app-0`, `app-1`), each with its own persistent volume via `volumeClaimTemplates`.

**4. What is Calico?**
A CNI (Container Network Interface) plugin that handles pod networking and also enforces NetworkPolicies for traffic control between pods/namespaces.

**5. What is etcd?**
A distributed, consistent key-value store that holds all cluster state and configuration — it's the source of truth the API server reads from and writes to.

**6. How do you take a backup of a Kubernetes cluster?**
`etcdctl snapshot save` for the etcd state (covers all object definitions), plus a tool like **Velero** for a full backup including PersistentVolume data and scheduled/automated backups.

**7. How do you upgrade an EKS cluster?**
Upgrade the control plane first (`eksctl upgrade cluster` or console, one minor version at a time), then upgrade managed node groups (rolling replace with new AMI), then upgrade core add-ons (VPC CNI, kube-proxy, CoreDNS) to versions compatible with the new cluster version. Check API deprecations before starting.

**8. What is a rolling update?**
The default deployment strategy — new pods are created and old ones terminated gradually (controlled by `maxSurge`/`maxUnavailable`), so the app stays available throughout instead of an all-at-once cutover.

**9. What deployment strategy are you using?**
Rolling update for most services; I'm also familiar with canary and blue-green for higher-risk releases, though rolling update is our default via ArgoCD/Helm.

**10. Can one container run as 2 pods?**
A single container *image* can back multiple pods — each replica pod runs its own independent instance of that container. (A single Pod, on the other hand, can run multiple containers together as sidecars — that's the reverse relationship.)

**11. What is a StatefulSet?**
Manages pods needing stable identity, ordered/graceful scaling, and per-replica persistent storage — used for things like databases (MongoDB, Kafka, Elasticsearch) where each replica's identity and data matter.

**12. Terraform — have you built a VM?**
Yes — using `aws_instance` (or `azurerm_linux_virtual_machine` on Azure), defining AMI/image, instance size, subnet, and security groups as code, and using variables to make it reusable across environments.

**13. What is an Ingress Controller?**
The component (e.g. ALB Controller, NGINX Ingress) that reads Ingress resources (routing rules) and configures the actual load balancer/proxy to implement host- and path-based routing to backend services — letting many services share one load balancer.

**14. If you've taken an etcd backup and the old VM is corrupted, can you create a new VM with that backup?**
Yes — restore the etcd snapshot into the new node's etcd data directory (`etcdctl snapshot restore`), point the control plane at the restored data dir, and once etcd is healthy the API server reconstructs cluster state from it. For a managed control plane like EKS this is largely AWS-managed, but the same restore logic applies for self-managed/on-prem clusters.

**15. Steps to upgrade an EKS cluster?**
1) Review release notes/API deprecations for target version. 2) Upgrade control plane version. 3) Upgrade managed node groups (rolling, one at a time). 4) Upgrade add-ons (CNI, CoreDNS, kube-proxy) to matching compatible versions. 5) Validate workloads are healthy after each step before continuing.

**16. In a StatefulSet with `mongo-0`, `mongo-1`, `mongo-2` — if `mongo-0` dies, what's the new pod's name?**
It's recreated with the **same name, `mongo-0`** — StatefulSets preserve stable, ordinal-based identity, so a replaced pod always gets its original ordinal name back, not a random new one.

**17. Have you worked on ArgoCD and Helm?**
Yes — ArgoCD for GitOps-based deployment/sync to EKS, and Helm for templating and packaging manifests across environments using different `values.yaml` files.

**18. If some pods are in a Deployment and some in a StatefulSet, how does rolling update work across both?**
They're independent — each controller manages its own rollout with its own strategy. The Deployment does a standard rolling update via ReplicaSets (parallel-ish, controlled by maxSurge/maxUnavailable). The StatefulSet does an ordered, one-pod-at-a-time update in reverse ordinal order (highest index first) by default. They don't coordinate with each other; you'd sequence dependent rollouts manually if order between them matters.

**19. What is Docker multi-stage build, and why is it used?**
Multiple `FROM` stages in one Dockerfile — an early stage builds/compiles the app with all build tools, and a final slim stage copies over only the compiled artifacts. Reduces final image size and removes build tools/secrets from the shipped image, improving both performance and security.

**20. Have you worked with Grafana?**
Yes — building dashboards on top of Prometheus metrics for cluster/pod health, and setting up alerting rules for on-call visibility.

---

## SET 3 — HCL (exp 5 yrs) — AWS / IAM Deep Dive

**1. Landing Zone, Guardrails, SCP, Control Tower — explain the vocabulary.**
Landing Zone = a secure, pre-configured multi-account AWS baseline (account structure, logging, networking). Control Tower = AWS's managed service that automates setting up and governing a Landing Zone. SCP (Service Control Policy) = an AWS Organizations-level policy that sets the *maximum* permissions allowed for accounts under it, regardless of IAM policies inside the account. Guardrails = preventive or detective rules (often SCP-backed) enforced by Control Tower across accounts.
*Honest add: I know this conceptually from AWS documentation/architecture discussions but haven't configured Control Tower hands-on in production.*

**2. Send an AMI from Account 1 to Account 2, but it's KMS-encrypted — how?**
Share the AMI with Account 2 (modify launch permissions), and update the KMS key policy in Account 1 to grant Account 2's principal `kms:Decrypt` / `kms:CreateGrant` permissions on that key — the target account needs explicit key access, not just AMI-share permission, since it's a separate CMK.

**3. EC2 has IAM roles — what can you explore from it?**
The role gives the instance temporary credentials without hardcoding keys. You can check: attached permission policies (what the instance can do — e.g. S3, DynamoDB access), the trust policy (which service can assume it), the instance profile linking role to EC2, and session/credential rotation via the instance metadata service.

**4. EC2 and S3 in the same subnet/region — how do you access the bucket from the instance?**
Attach an IAM role to the EC2 instance with S3 permissions, then access via AWS CLI/SDK using those role credentials — no hardcoded keys needed. For private, non-internet-routed access, add a VPC Gateway Endpoint for S3 so traffic stays inside AWS's network.

**5. EC2 instance has no internet connectivity — how do you tackle this?**
Check first: is it in a private subnet? If it needs outbound internet, attach/verify a NAT Gateway in the route table. If it only needs AWS service access (S3, ECR, etc.), a VPC endpoint is better than routing through NAT. Also check security group outbound rules and NACLs aren't blocking traffic.

**6. Two instances need to communicate — new NIC or attach existing?**
Just use the existing primary ENI and private IP with the right security group rules allowing traffic between them — no need for a new NIC unless you specifically need multi-homing (e.g. separate network interfaces for management vs data traffic).

**7. Multiple IAM users — attach policy individually, or group + policy?**
Group-based: create a group, attach the policy to the group, add users to the group. Scales far better — updating one group policy updates access for everyone in it, instead of editing N individual users.

**8. Inline policy vs attached (managed) policy — which is right?**
Managed policies (AWS-managed or customer-managed) are preferred — reusable across multiple users/roles/groups, versioned, and easier to audit centrally. Inline policies are tightly coupled 1:1 to a single identity and get hard to track at scale — I'd only use inline for a very specific one-off exception.

**9. Have you used permission boundaries?**
Not hands-on in production, but I understand the concept: a permission boundary sets the *maximum* permissions a role/user can ever have, even if a more permissive policy is attached later — commonly used to safely delegate role-creation to other teams without risking privilege escalation.

**10. S3 lifecycle rules — advantage?**
Automates moving objects to cheaper storage tiers (Standard-IA, Glacier) as they age, and can auto-expire/delete old objects — reduces storage cost without manual intervention.

**11. Have you worked on Transit Gateway?**
Not directly, but I understand it's a central hub for connecting multiple VPCs and on-prem networks, replacing the complexity of full-mesh VPC peering with a single hub-and-spoke model.

**12. ALB vs NLB — have you used them?**
Yes. ALB is Layer 7 — HTTP/HTTPS, supports path/host-based routing, used for web apps and our Kubernetes Ingress. NLB is Layer 4 — TCP/UDP, ultra-low latency, static IP support, used for high-throughput or non-HTTP traffic.

**13. Public/private subnet with NAT gateway on the private subnet — what's the use?**
It lets instances in the private subnet reach the internet for outbound needs (updates, API calls) **without** being directly reachable from the internet — the NAT gateway masks their private IPs behind its own public IP (SNAT), so inbound connections can't be initiated to them directly.

**14. How does NAT gateway protect the private subnet — what concept does it use?**
Source NAT (IP masking) — outbound traffic from private instances is rewritten to appear as coming from the NAT gateway's public IP. Since there's no route *into* the private subnet from the internet, and the NAT only allows return traffic for connections it initiated, the private instances stay unreachable from outside.

**15. Have you worked on KMS / Secrets Manager?**
Limited hands-on — I understand KMS manages encryption keys used for S3/EBS/RDS encryption, and Secrets Manager stores and can auto-rotate credentials (DB passwords, API keys) that apps pull at runtime instead of hardcoding. I've consumed secrets from these but haven't set up rotation policies myself.

**16. EC2 manually resized t3.medium → t3.large, code updated and committed locally, but the pipeline wasn't run. If you run the pipeline now, what happens?**
Nothing changes from that local commit — if it was only committed locally and never pushed to the remote repo, the pipeline (which pulls from remote) has no visibility into it, so running the pipeline deploys whatever *is* already in the remote branch, not the uncommitted local change.

**17. Can the same buildspec used in AWS CodeBuild be reused elsewhere?**
Yes — `buildspec.yml` can be shared across multiple CodeBuild projects (including ones provisioned via Terraform) as long as the build steps are kept generic and environment-specific values are injected via environment variables/parameters rather than hardcoded.

**18. What is a DaemonSet, and what default daemons come with Kubernetes?**
A DaemonSet ensures exactly one pod runs on every (or selected) node automatically — used for node-level agents. Defaults typically include `kube-proxy` and the CNI plugin (e.g. `aws-node` for VPC CNI on EKS); log/metrics agents like Fluentd or the CloudWatch agent are commonly added as DaemonSets too.

**19. What is an init container?**
A container that runs and completes *before* the main app container starts in a pod — used for setup tasks like waiting on a dependency, running migrations, or pulling config. EKS system add-ons sometimes use init containers internally, but they're mainly something I define myself for app-level setup steps.

**20. What is taint and toleration in Kubernetes?**
A taint on a node repels pods from scheduling there unless the pod has a matching toleration — used to dedicate nodes to specific workloads (e.g. GPU nodes, or keeping system pods off application nodes).
*Follow-up: "How's this different from node affinity?" → Taints/tolerations repel by default (opt-in via toleration); node affinity attracts pods toward nodes based on labels but doesn't repel others.*

**21. What is a compute reservation in a manifest file?**
This refers to `resources.requests` in the pod spec — it reserves a guaranteed amount of CPU/memory on the node for that pod (used by the scheduler for bin-packing), distinct from `resources.limits`, which caps the maximum the pod can use.

---

## SET 4 — HCL (exp 5 yrs) — Practical / Hands-on

**1. Display the last 10 lines of a large log file without opening it fully.**
`tail -n 10 filename.log` — or `tail -f filename.log` to also follow new lines being appended live.

**2. In Kubernetes, how would you configure a deployment to double CPU allocation once usage crosses 70%?**
Use a HorizontalPodAutoscaler (HPA) with `targetCPUUtilizationPercentage: 70`, and set `minReplicas`/`maxReplicas` so the replica count scales up (roughly doubling pod count, which doubles aggregate CPU capacity) once average utilization crosses that threshold — `kubectl autoscale deployment <name> --cpu-percent=70 --min=2 --max=4` as a quick example.

**3. Can you write a basic Dockerfile for your application?**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

**4. What top-level OWASP security risks do you usually check for?**
Injection (SQL/command), broken authentication, sensitive data exposure, broken access control, security misconfiguration, cross-site scripting (XSS), use of components with known vulnerabilities, and insufficient logging/monitoring — these map to what SonarQube/Trivy scans catch in our pipeline.

**5. How do you configure Prometheus and Grafana for monitoring?**
Deploy via the `kube-prometheus-stack` Helm chart, which sets up Prometheus, Alertmanager, and Grafana together. Configure `ServiceMonitor`/`PodMonitor` resources so Prometheus scrapes the right targets, then add Prometheus as a data source in Grafana and build/import dashboards (e.g. node-exporter, kube-state-metrics dashboards) for visibility.

**6. If you have an on-prem application, how would you migrate and deploy it in a cloud-native environment?**
Containerize the app (write a Dockerfile), define Kubernetes manifests/Helm chart for it, set up a CI/CD pipeline (build, scan, push, deploy), then do a phased rolling cutover — deploy to the new environment alongside the on-prem instance, validate it's healthy and serving correctly, redirect traffic gradually, then decommission on-prem. Same approach I used migrating our 15 microservices to EKS.

**7. Explain Docker Compose and how it helps with multi-container deployments.**
Docker Compose defines multiple related containers (app, database, cache, etc.) in a single `docker-compose.yml` — handling networking between them, volumes, and startup dependencies (`depends_on`) with one command (`docker-compose up`). It's mainly for local development/testing multi-service apps quickly, without needing a full Kubernetes cluster.

---

## Bonus — New "real-life problem" story (different from spot-instance/RI one)

Keep this ready for any "tell me about a production issue" follow-up in these interviews, since you'll likely get asked again:

> "We had pods intermittently going into **CrashLoopBackOff** during peak traffic — turned out the memory limits on a few services were set too low, so under load they were getting **OOMKilled** by the kubelet, restarting, and briefly dropping requests. I used `kubectl describe pod` and `kubectl logs --previous` to confirm the OOMKill reason, checked actual usage against requests/limits in Grafana, then right-sized the memory requests/limits based on real usage data and added an HPA so replica count scales up before any single pod gets overloaded. Restarts dropped close to zero after that, and we haven't had a repeat during traffic spikes since."

This works for: "production issue you faced," "how do you debug pod crashes," or "how do you set resource requests/limits."
