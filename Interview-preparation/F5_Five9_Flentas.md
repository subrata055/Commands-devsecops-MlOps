# Interview Prep — F5, Five9, Flentas

---

## F5 — Associate Consultant

**1. What is a Web Application Firewall (WAF)?**
A reverse-proxy layer that inspects HTTP/S traffic and blocks malicious requests (SQLi, XSS, bad bots) using rule sets — sits in front of the app, e.g., AWS WAF attached to an ALB/CloudFront.
*Follow-up: How do you attach it? →* As a Web ACL linked to your ALB, CloudFront distribution, or API Gateway, with managed + custom rule groups.

**2. How would you secure a cloud web app from the OWASP Top 10?**
Parameterized queries (SQLi), output encoding + CSP headers (XSS), WAF managed rule groups, rate limiting, TLS everywhere, least-privilege IAM, dependency/image scanning, and centralized logging/alerting (CloudTrail, GuardDuty).

**3. What happens if the tfstate file gets deleted?**
Terraform loses its mapping between config and real infrastructure — the next `plan`/`apply` thinks nothing exists and tries to recreate everything, causing duplicate-resource errors. Recovery: restore from S3 versioning (if versioning was enabled) or rebuild state with `terraform import` per resource.

**4. What is the `.terraform.lock.hcl` file?**
A dependency lock file that pins exact provider versions and checksums used, so every team member/CI run uses identical provider versions — similar to `package-lock.json`.

**5. Best practices to follow in Terraform?**
Remote state with locking (S3 + DynamoDB), modularize reusable resources, separate `.tfvars` per environment, never commit secrets, always run `plan` before `apply`, pin provider versions, use consistent tagging/naming conventions.

**6. If a security group is already configured, do we still need a NACL?**
Yes — defense in depth. SGs are stateful and instance-level (allow rules only); NACLs are stateless and subnet-level, and support explicit deny rules, so they can block traffic before it even reaches the instance.

**7. Difference between Transit Gateway and VPC?**
A VPC is an isolated virtual network; a Transit Gateway is a hub that interconnects multiple VPCs and on-prem networks through one central gateway, avoiding a full mesh of VPC peering connections.

**8. Best practices for cloud security?**
Least-privilege IAM, encryption at rest/in transit, MFA everywhere, network segmentation (SG/NACL/private subnets), centralized logging (CloudTrail/GuardDuty), regular patching, secrets management (no hardcoded credentials), periodic audits.

**9. HTTP request headers and methods?**
Headers carry metadata (Content-Type, Authorization, Cache-Control). Methods: GET (read), POST (create), PUT (replace — idempotent), PATCH (partial update), DELETE (remove), HEAD, OPTIONS.

**10. With SG + WAF + DDoS protection enabled, does that stop bot attacks?**
Not fully. SG/WAF/Shield handle network-layer and known app-layer attacks/volumetric DDoS, but sophisticated bots that mimic human behavior or rotate IPs need dedicated bot protection (e.g., AWS WAF Bot Control, CAPTCHA, rate-based rules) — it's not automatic from the basics alone.

**11. Same PUT entry (name, location) made twice — what happens?**
Nothing changes after the first write — PUT replaces the resource at that identifier, so the second identical PUT just overwrites it with the same values. No duplicate is created.

**12. Why is PUT idempotent? Same name, different location — what does the DB store?**
Idempotent means repeating the same request any number of times leaves the system in the same end-state as doing it once. If the identifier (name) matches but location differs, PUT updates that same record — the DB ends up storing the latest submitted location, not a new duplicate row.

**13. What happens when you type www.google.com and hit enter?**
Browser checks cache → DNS resolution → TCP handshake → TLS handshake (HTTPS) → HTTP request sent → server processes and responds → browser renders the page.

**14. What is the SSL/TLS handshake?**
Client Hello (supported ciphers/TLS version) → Server Hello (certificate + chosen cipher) → client verifies the cert and exchanges a session key using asymmetric encryption → both sides switch to symmetric encryption for the actual session — secure channel established.

**15. What is DNS resolution? Step-by-step for a brand-new system with no cache?**
Browser cache (miss) → OS resolver cache (miss) → query recursive resolver (ISP/8.8.8.8) → resolver asks a root server → root points to the `.com` TLD server → TLD server points to the domain's authoritative nameserver → authoritative server returns the IP → result cached at each layer on the way back → browser connects to that IP.

**16. What is Kubernetes? Explain the architecture.**
A container orchestration platform. Control plane (API server, scheduler, controller manager, etcd) makes cluster-wide decisions; worker nodes run kubelet, kube-proxy, the container runtime, and the actual pods.

**17. Can a pod run on the master node itself?**
Not by default — control-plane nodes carry a `NoSchedule` taint that blocks regular workloads. It's possible only if you explicitly remove or tolerate that taint, which isn't recommended in production.

**18. Have you deployed any security application on Kubernetes?**
*(Adapt to what you've actually used — if none yet, say so and name what you'd use.)* Example answer: Yes, Trivy Operator for continuous in-cluster image vulnerability scanning, and OPA/Gatekeeper for policy enforcement (blocking non-compliant manifests at admission time).

---

## Five9 — 7 YOE

**1. How do you find the second-largest integer in an array?**
Single pass, track two variables — `largest` and `secondLargest` — updating both as you iterate. O(n) time, O(1) space. (Sorting works too but is O(n log n), mention the single-pass approach as the better answer.)

**2. How do you set a CPU and memory limit on a Linux machine?**
Via cgroups directly, or a systemd unit's `CPUQuota=`/`MemoryMax=`, or `ulimit` for per-process limits; for containers, Docker's `--cpus` and `--memory` flags.

**3. TLS handshake?**
Same as above — Client Hello → Server Hello + cert → key exchange (asymmetric) → switch to symmetric encryption for the session.

**4. Apart from storing TF logs in S3, any other options?**
Stream `TF_LOG` output to CloudWatch Logs, ship it to an ELK/OpenSearch stack, or use Terraform Cloud/Enterprise's built-in run logging instead of self-managing log storage.

**5. Different types of Terraform provisioners?**
`local-exec` (runs a command on the machine running Terraform), `remote-exec` (runs a command inside the newly created resource via SSH/WinRM), and `file` (copies files to the remote resource).

**6. Difference between local and remote provisioners?**
`local-exec` executes on your Terraform host after resource creation; `remote-exec` connects into the created resource itself and runs commands there — requiring network reachability and credentials during apply.

**7. Difference between user-data and a remote-exec provisioner?**
`user-data` is a cloud-init script passed at launch and run natively by the OS at boot — no SSH/Terraform dependency, more reliable. `remote-exec` requires Terraform to SSH into the instance after creation, so it's more fragile and considered a last resort by HashiCorp.

**8. A and CNAME records in DNS?**
A record maps a hostname to an IPv4 address (AAAA for IPv6). CNAME maps a hostname to another hostname (an alias), not directly to an IP.

**9. Failover mechanism in DNS if one IP is unreachable?**
DNS failover routing (e.g., Route 53 failover routing policy) — health checks continuously probe the primary endpoint, and if it fails, DNS automatically starts resolving to the secondary/standby IP.

**10. How are logs segregated in ELK?**
Separate indices per app/environment (index-per-service or index-per-day via Logstash/Filebeat), tagged with fields like `service_name`/`environment`, filtered in Kibana — sometimes separate clusters entirely for strict tenant isolation.

**11. Apart from a password, how else can you log into EC2?**
SSH key pair, AWS Systems Manager Session Manager (no open SSH port or key needed), or EC2 Instance Connect.

---

## Flentas — 3.5 YOE

**1. What is your architecture in your current project?**
Microservices running on EKS behind an ALB Ingress Controller, RDS and Redis for data/cache, GitOps deployment via ArgoCD, and Prometheus/Grafana for monitoring — separate namespaces for prod/UAT/dev.

**2. What applications are deployed in the frontend and backend?**
A customer-facing website with its own frontend/backend, and a separate internal frontend/backend for office use — plus supporting services like Redis and the database layer.

**3. Why wasn't the frontend deployed on S3 + CloudFront instead of EKS?**
The frontend has server-side logic/dynamic routes and needs to share session/auth context with the backend, so keeping it on the same EKS/CI-CD pipeline as the rest of the stack was simpler than maintaining two separate deployment models.
*Follow-up: When would S3+CloudFront make sense? →* For a fully static frontend with no server-side rendering — cheaper and simpler than running it in a cluster.

**4. What is a namespace in EKS?**
A logical partition inside a cluster used to organize resources by environment or team, and to scope RBAC and network policies.

**5. How many namespaces do you currently have?**
Separate namespaces for prod, UAT, and dev, with additional splits by tier (frontend/backend/db) where it helps with access control and network policy scoping.

**6. What is a node group?**
A set of EC2 worker nodes managed together with the same configuration (instance type, AMI, scaling settings) — you can run multiple node groups for different workload types, e.g., spot for dev/UAT, on-demand for prod.

**7. How do you perform cost optimization on ECS, RDS, and ElastiCache?**
ECS: right-size task CPU/memory, use Fargate Spot for non-critical workloads. RDS: right-size the instance class, use Reserved Instances, enable storage autoscaling instead of over-provisioning. ElastiCache: right-size the node type and use reserved nodes where usage is predictable.

**8. Why did you use RDS Proxy?**
It pools and manages database connections centrally, so many app instances don't each open a direct connection to RDS — prevents connection exhaustion and speeds up failover.

**9. The client application had no connection pooling — how did you handle it?**
I put RDS Proxy in front of the RDS instance so all application pods shared a managed connection pool instead of each opening its own DB connection. This eliminated the "too many connections" errors we were seeing during traffic spikes and cut total DB connections significantly — without any application code changes.

**10. A node is unable to join the cluster — what could be the reason?**
Security group not allowing control-plane/node communication, node IAM role missing required EKS policies, AMI/kubelet version mismatch with the cluster, the `aws-auth` ConfigMap not mapping the node role, or a subnet/routing issue blocking reach to the control-plane endpoint.

**11. Difference between control plane and data plane?**
Control plane manages cluster state and scheduling decisions (API server, scheduler, etcd, controller manager). Data plane is the worker nodes actually running your application workloads (kubelet, kube-proxy, pods).

**12. Difference between a Pod and a Container?**
A container is a single running process/image instance. A Pod is Kubernetes' smallest deployable unit and can wrap one or more containers that share the same network namespace and storage.

**13. What are requests and limits in Kubernetes?**
Requests = the minimum resources the scheduler guarantees/reserves when placing a pod. Limits = the maximum a pod can use before it's throttled (CPU) or OOMKilled (memory).

**14. Node has 8 vCPU/32GB RAM. Pods autoscale up to 4 replicas, each with limits 4 vCPU/16GB and requests 2 vCPU/10GB — how many pods run?**
Scheduling is based on *requests*, not limits. By CPU: 8 ÷ 2 = 4 pods possible. By memory: 32 ÷ 10 = 3.2 → 3 pods possible. Memory is the binding constraint, so **only 3 pods** fit on that single node — the 4th stays Pending until more node capacity is added (e.g., via Cluster Autoscaler).

**15. What did you implement in Lambda and API Gateway?**
*(Adapt to your real project.)* Example: lightweight internal APIs — webhook handlers and notification triggers — using API Gateway as the entry point and Lambda for the business logic, avoiding an always-on service for low, bursty traffic.

**16. Difference between Redis and Memcached?**
Redis supports rich data structures (lists, sets, hashes, sorted sets), persistence, replication, and pub/sub. Memcached is a simpler pure key-value in-memory cache, multithreaded, no persistence. Redis is generally preferred now for its versatility.

**17. Explain your Terraform folder structure.**
`modules/` for reusable resource groups (vpc, eks, rds), `environments/dev|uat|prod/` each with its own `main.tf`, `backend.tf`, and `terraform.tfvars` calling those shared modules with environment-specific values.

**18. Difference between Terraform and Terragrunt?**
Terraform is the core IaC tool. Terragrunt is a thin wrapper around it that keeps configs DRY — manages remote state config, variable inheritance, and multi-module dependency ordering across environments without repeating backend blocks everywhere.

**19. What is the state file in Terraform?**
A JSON file that maps your configuration to the real-world resources Terraform created, tracking metadata and dependencies so `plan`/`apply` know the current state of infrastructure.

**20. How do you handle resource dependencies in Terraform?**
Mostly implicit — referencing one resource's attribute in another builds the dependency graph automatically. Use explicit `depends_on` only when there's an ordering requirement with no direct attribute reference.

**21. Did `terraform apply` ever produce unexpected changes?**
Yes — usually from drift (someone changed infra manually outside Terraform) or a provider default changing between versions. Fixed by always reviewing the `plan` diff carefully before applying, and reconciling drift with `terraform refresh`/`import`.

**22. How do you roll back if there's a problem in Terraform?**
Revert to the last known-good config in Git and re-apply, or restore a previous state file version (if S3 versioning is enabled) and re-apply. Note Terraform rollback only re-applies old *config* — for destructive real-world changes (e.g., a dropped table), you still need resource-level backups like RDS snapshots.

**23. You created an LB via Terraform, then made manual updates — now you want to delete just the LB.**
`terraform state show` to confirm the resource address, then `terraform destroy -target=<resource_address>` to remove only that resource. Use `-target` carefully — it bypasses the full dependency graph, so verify nothing else depends on it first.

**24. How do you handle secrets in Terraform?**
Never hardcode them in `.tf`/`.tfvars`. Pull them at apply time from AWS Secrets Manager or SSM Parameter Store via data sources, mark sensitive variables with `sensitive = true`, and keep the state file encrypted (S3 with SSE) since secrets can end up in state.

**25. How do you pass secrets from AWS Secrets Manager to the pipeline?**
The pipeline (Jenkins/GitHub Actions) assumes an IAM role with read access, fetches the secret at runtime into an environment variable or injected file (never logged or committed), and Terraform reads it via `aws_secretsmanager_secret_version` data source.

**26. Do you commit tfvars to Git? How are pipeline parameters managed in Jenkins?**
Non-sensitive tfvars can be committed; sensitive values are never committed. They're injected at runtime as Jenkins credentials/environment variables and passed via `-var` flags or written into a gitignored tfvars file during the pipeline run.

**27. What is Docker?**
A platform for building, packaging, and running applications in isolated containers using OS-level virtualization — bundles code and dependencies into a portable image that runs consistently across environments.

**28. Difference between an image and a container?**
An image is a read-only, versioned template. A container is a running (or stopped) instance of that image with its own writable layer on top.

**29. What is a Helm chart?**
A packaged, templated collection of Kubernetes manifests with variables — lets you deploy, configure, and upgrade an application as one versioned unit instead of applying individual YAML files.

**30. How do you autoscale both nodes and pods under high traffic?**
Horizontal Pod Autoscaler (HPA) scales pod replicas based on CPU/memory/custom metrics; Cluster Autoscaler (or Karpenter) adds/removes worker nodes when pods can't be scheduled due to insufficient capacity. The two work together.

**31. Can you use Cluster Autoscaler?**
Yes — it watches for pods stuck Pending due to resource constraints and automatically provisions new nodes (or scales down underutilized ones), typically paired with HPA.

**32. How do you scale EC2 instances?**
Auto Scaling Groups with scaling policies — target tracking (e.g., on CPU or request count) for reactive scaling, or scheduled scaling for predictable traffic patterns.

**33. When do you use VPA (Vertical Pod Autoscaler)?**
When a workload's resource needs are unpredictable or change over time and you want Kubernetes to automatically right-size pod requests/limits instead of manually tuning them — good for single-replica or batch workloads. Generally not combined with HPA on the same metric, to avoid the two fighting each other.

**34. Have you upgraded an EKS cluster? What's the procedure?**
Yes — first check API/CRD deprecations for the target version, upgrade the control plane via console/CLI, then upgrade node groups one at a time (cordon → drain → replace), update core add-ons (CoreDNS, kube-proxy, VPC CNI) to compatible versions, and validate workloads after each step before moving to the next node group.
