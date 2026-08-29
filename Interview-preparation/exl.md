# EXL Service — DevOps Interview Prep (5 YOE round)

This round expects more architecture/design depth than the last one. Where a topic is outside your direct hands-on experience, the answer is written to show you understand the concept and can reason about trade-offs — say it plainly as "conceptual understanding, haven't run it in production" rather than pretending deep hands-on. That honesty reads better than overreach at senior level.

---

**1. Design the complete application architecture for onboarding a 5M+ user customer, as Solution Architect.**
Multi-AZ VPC with public/private subnets, ALB/API Gateway in front of an EKS cluster running microservices across namespaces, RDS (Multi-AZ) or Aurora for the primary DB, ElastiCache/Redis for session/caching, S3+CloudFront for static assets, autoscaling (HPA + Cluster Autoscaler/Karpenter) to handle load, and WAF + Shield for security. I'd start with capacity planning (expected RPS, data volume) before picking instance sizes and DB tier.
*Follow-up: "How would you handle a traffic spike 10x above normal?"* → Pre-warmed autoscaling policies, read replicas for DB, CDN caching for static/semi-static content, and rate limiting at the API Gateway/WAF layer.

**2. Explain your complete CI/CD pipeline from commit to production.**
Commit triggers GitHub Actions/Jenkins → Trivy filesystem scan + SonarQube code quality scan → build Docker image → Trivy image scan → push to ECR/Docker Hub → update the image tag in the GitOps manifest repo → ArgoCD detects the change and syncs it to the target namespace/cluster → automated smoke tests / health checks confirm the rollout.
*Follow-up: "What happens if SonarQube fails the quality gate?"* → Pipeline fails and blocks the build from proceeding — no image gets pushed until the developer fixes the flagged issues.

**3. Explain your Git branching strategy and how you deploy from different branches to different environments.**
I use a trunk-based/Gitflow hybrid: `develop` → auto-deploys to Dev, `release/*` or `staging` branch → deploys to UAT, `main` → deploys to Production, usually gated by a manual approval or PR merge. Each branch maps to a specific environment's manifest path/values file that ArgoCD watches.
*Follow-up: "How do you handle a hotfix that needs to skip the normal flow?"* → Branch off `main` as `hotfix/*`, fix, PR-review, merge directly to `main` and cherry-pick back into `develop` so branches don't drift.

**4. If Git is the source of truth, why do we need ArgoCD instead of deploying directly via CI/CD with Helm/kubectl?**
Because CI/CD is push-based and one-shot — once it applies the manifest, it isn't watching for drift. ArgoCD is pull-based and continuously reconciles: if someone manually changes something in the cluster, ArgoCD detects and reverts the drift back to match Git. It also gives visual diff/sync status and easy rollback by reverting a commit, which a plain `kubectl apply` step doesn't.

**5. Explain the complete request flow for www.ingress.com until it reaches the pod.**
DNS resolves the domain to the ALB (via Route53) → ALB (provisioned by the ALB Ingress Controller based on the Ingress resource) terminates SSL and matches host/path rules → forwards to the correct Kubernetes Service (ClusterIP) → kube-proxy/iptables rules route to one of the healthy pod endpoints selected via the Service's label selector → pod handles the request.

**6. Expose an application internally without using LoadBalancer or NodePort.**
Use a ClusterIP service — it's internal-only by default and reachable via DNS (`service.namespace.svc.cluster.local`) from other pods in the cluster. If it needs to be reachable from outside the cluster but still privately, I'd use an internal ALB via Ingress (annotated `internal`) rather than exposing it publicly.

**7. Pods in different namespaces can communicate by default — how do you block that? Where do you implement the NetworkPolicy?**
Apply a default-deny-all NetworkPolicy in each namespace (`podSelector: {}`, no ingress/egress rules), which blocks all traffic, then add explicit allow rules using `namespaceSelector`/`podSelector` labels for only the traffic that should be permitted. The NetworkPolicy resource is created in the namespace whose *incoming* traffic you're restricting.

**8. Implement a Canary deployment (10% of users) through your CI/CD pipeline.**
Use Argo Rollouts (extends ArgoCD) instead of a plain Deployment — define a Rollout resource with canary steps: e.g. `setWeight: 10`, pause, then `setWeight: 50`, pause, then `100`. The pipeline builds/pushes the new image as usual; ArgoCD/Argo Rollouts handles the traffic-split via the Ingress/ALB weighted target groups.
*Follow-up: "What if you don't have Argo Rollouts — how else?"* → Manually run two Deployments (stable + canary) behind one Service, scale canary replicas to represent ~10% of total pod count, and use Ingress annotations for weighted routing if the controller supports it (e.g. ALB weighted target groups, or NGINX canary annotations).

**9. How do you verify the 10% canary is healthy before proceeding to 100%?**
Monitor error rate, p95/p99 latency, and CPU/memory of canary pods vs. baseline in Grafana/Prometheus over a defined bake time (e.g. 10-15 min), plus application-level metrics like HTTP 5xx rate and business KPIs if available. Argo Rollouts can automate this with an `AnalysisTemplate` that queries Prometheus and auto-aborts the rollout if error rate crosses a threshold.

**10. Do you run Terraform locally or via CI/CD? Explain the workflow.**
Via CI/CD — local `terraform apply` isn't safe for shared infra. Workflow: PR triggers `terraform plan` in the pipeline, plan output posted as a PR comment for review, on merge to main the pipeline runs `terraform apply` using a remote backend (S3 + DynamoDB for state/locking), with credentials via OIDC role assumption rather than static keys.

**11. Two engineers work on the same Terraform code — how do you prevent conflicts / handle state locking or drift?**
Remote state in S3 with DynamoDB for state locking — so a second `apply` is blocked while one is in progress. For code conflicts, standard PR review process; for drift detection, scheduled `terraform plan` runs (e.g. nightly) that alert if the live infra has diverged from code.

**12. Draw/explain your Terraform repo structure — how do dev/qa/prod consume shared modules like VPC?**
```
terraform/
  modules/
    vpc/
    eks/
    rds/
  environments/
    dev/     -> main.tf calls modules/vpc,eks with dev.tfvars
    qa/      -> calls same modules with qa.tfvars
    prod/    -> calls same modules with prod.tfvars
```
Each environment folder has its own state file and `.tfvars`, but all call the *same* versioned modules — so a fix to the VPC module rolls out consistently, only variable values (CIDR, instance size, replica count) differ per environment.

**13. Two VPCs with overlapping CIDR ranges need to communicate — Transit Gateway not allowed. Alternative?**
Overlapping CIDRs rule out VPC Peering and Transit Gateway too (both require non-overlapping ranges). The real fix: re-IP one VPC if at all possible. If not, use a NAT/proxy layer — e.g. PrivateLink (VPC endpoint services) to expose specific services without needing route-level connectivity, since PrivateLink works at the ENI/service level and isn't blocked by CIDR overlap.
*Follow-up: "Why does PrivateLink avoid the CIDR overlap problem?"* → Because it doesn't route between the two VPCs' IP spaces at all — the consumer VPC gets a local ENI with its own IP that forwards to the service, so there's no cross-VPC routing table conflict.

**14. Have you worked on Disaster Recovery? Explain RTO, RPO, failover, traffic redirection.**
RTO (Recovery Time Objective) = how fast you must be back up; RPO (Recovery Point Objective) = how much data loss is acceptable. My DR approach: cross-region RDS read replica (promotable on failure) or automated snapshots, EKS manifests/Helm charts kept region-agnostic so a standby cluster can be spun up via IaC, and Route53 health checks with failover routing policy to redirect traffic to the DR region automatically.
*(If you haven't run an actual DR drill, say so honestly: "I've designed for it — replicas, IaC, Route53 failover — but haven't executed a full live failover drill yet.")*

**15. Explain Rolling Update, Blue-Green, and Canary deployment strategies.**
Rolling Update: replace old pods with new ones gradually, no separate environment needed, some risk since bad rollout affects live traffic incrementally. Blue-Green: run two full identical environments, switch traffic all at once when green is verified — instant rollback but double the infra cost. Canary: route a small % of traffic to the new version first, monitor, then gradually increase — safest but most complex to set up.

**16. For a mission-critical production app, which deployment strategy would you choose and why?**
Canary — because it limits blast radius to a small percentage of real users while giving real production signal (unlike Blue-Green, which validates in a separate environment that may not perfectly mirror live traffic patterns). Rolling update is riskier for mission-critical since a bad version can spread before detection.

**17. Have you worked on Databricks pipelines? Explain your experience.**
Honest answer: no hands-on Databricks experience. I know it's a managed Spark platform for big data/ML pipelines with notebooks, Delta Lake for reliable data lakes, and job orchestration — but I haven't operated it in production. Happy to ramp up given my Kubernetes/pipeline background.

**18. What do you know about Apache Hadoop and its ecosystem?**
Conceptual knowledge: HDFS for distributed storage, MapReduce/YARN for distributed processing, with Hive for SQL-on-Hadoop and Spark largely having replaced MapReduce for performance. I haven't administered a Hadoop cluster myself — my big-data-adjacent exposure has been more around RDS/Redis than Hadoop.

**19. Which EC2 instance types have you used, and why?**
`t3`/`t3a` (burstable, general-purpose, cheap) for dev/UAT workloads; `m5`/`m6i` (balanced compute/memory) for steady-state production app nodes; `r5` (memory-optimized) where I've had memory-heavy workloads like caching or DB nodes. Chosen based on the CPU:memory ratio the workload actually needs, verified via CloudWatch metrics rather than guessing.

**20. Difference between Git Merge and Git Rebase.**
Merge creates a new merge commit that ties two branch histories together, preserving full history but making the log messier. Rebase replays your commits on top of the target branch, producing a linear, cleaner history — but rewrites commit hashes, so it's risky on shared/public branches (only rebase local/feature branches, never `main`).

**21. Give a real-world use case of AWS Lambda.**
Automated response to S3 events — e.g. a Lambda triggered when a file lands in an S3 bucket, which validates/processes it and writes results to RDS or triggers a downstream notification (SNS/SQS). Also used it for lightweight scheduled cleanup jobs (via EventBridge) instead of running a dedicated EC2/cron server for infrequent tasks.

**22. Where do you store CI/CD secrets (pipeline credentials)?**
GitHub Actions Secrets / Jenkins Credentials Store for pipeline-level secrets (registry creds, cloud keys), and prefer OIDC role assumption over long-lived static AWS keys where possible so nothing sensitive is stored long-term at all.

**23. Where do you store application configuration and secrets?**
Non-sensitive config → Kubernetes ConfigMaps. Sensitive values (DB passwords, API keys) → Kubernetes Secrets, ideally backed by an external secrets manager (AWS Secrets Manager or HashiCorp Vault via the External Secrets Operator) rather than raw base64 Secrets, so rotation and audit are centralized.

**24. A developer accidentally commits AWS credentials to Git — what's your incident response?**
Immediately rotate/revoke the exposed key in IAM (don't wait to clean history first — the key is compromised the moment it's pushed, even to a private repo). Then check CloudTrail for any unauthorized activity using that key. Then remove it from Git history (`git filter-repo`/BFG) and force-push, and finally add a pre-commit secret scanner (like `gitleaks` or `truffleHog`) to prevent recurrence.
*Follow-up: "Why revoke before cleaning history?"* → Because the key is already compromised the second it's pushed — anyone who cloned/viewed it has it, regardless of what you do to history afterward. Revocation is the only step that actually stops damage.

**25. What metrics do you monitor using Prometheus?**
Pod/node CPU and memory usage, pod restart counts, HTTP request rate/latency/error rate (via app metrics or Istio if used), disk usage, and cluster-level metrics like node readiness and pending pods (scheduling issues).

**26. What dashboards and alerts have you configured in Grafana?**
Dashboards: cluster overview (node/pod health), per-application latency & error rate, and cost/resource-utilization view. Alerts: pod CrashLoopBackOff, high memory/CPU (>80% sustained), and HTTP 5xx rate above threshold — routed to Slack/email.

**27. What monitoring agents have you installed in your environment?**
Prometheus Node Exporter (host metrics), kube-state-metrics (Kubernetes object state), and the Prometheus operator's scrape configs for app-level metrics; Fluent Bit/CloudWatch agent for log shipping.

**28. How do you perform infra cost optimization using monitoring/observability tools?**
Use Grafana/CloudWatch to spot consistently underutilized nodes or over-provisioned pods (requests set far above actual usage) and right-size them; identify idle resources (unused EBS volumes, unattached EIPs) via AWS Cost Explorer; and use these signals to move suitable workloads to spot instances or reserved/savings-plan pricing where usage is predictable.

---

## New "real production issue" story (not spot/RI — use or adapt with your real specifics)

**Problem:** One of our backend microservices started getting OOMKilled repeatedly during peak traffic, causing intermittent 502s from the ALB.
**Diagnosis:** Grafana showed memory climbing steadily until the pod hit its memory limit and got killed by the kubelet — a classic memory leak/undersized limit pattern, confirmed via `kubectl describe pod` showing `OOMKilled` in the last termination reason.
**Fix:** Short-term, increased the memory limit/request to stop the immediate crash-looping and restore stability. Root-cause side, worked with the dev team to profile the app and found an unbounded in-memory cache that wasn't evicting old entries — they added a TTL/max-size eviction policy.
**Result:** Pod restarts dropped from several times a day to zero, and 502 error rate on that service went to near-zero during peak hours.

Use this shape (symptom → data-driven diagnosis → immediate fix → root cause fix → measurable result) for any "tell me about a production issue" question — it's the structure interviewers are actually grading, not just the specific tool.
