# Infosys Interview Prep — All Rounds

Answers are 1-4 lines, answer-first. Follow-ups are marked → practice those too, interviewers chain into them naturally.

---

## Set 1

**1. Introduce yourself**
DevOps Engineer with 4+ years' experience in AWS, Kubernetes (EKS), and CI/CD automation. Currently at Navigator Software managing infra and deployments for an insurance-domain client — AWS account, EKS clusters, CI/CD pipelines, and databases. AWS Certified Solutions Architect and CKA certified.

**2. Git commands used day to day**
`git clone`, `git pull`, `git checkout -b`, `git add/commit/push`, `git merge`, `git rebase`, `git stash`, `git log --oneline`, `git cherry-pick` for hotfixes, `git revert` to undo a bad prod commit safely.

**3. Write a sample Dockerfile**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
USER node
CMD ["node", "server.js"]
```
→ *Follow-up: "Why alpine?"* — Smaller base image, faster pulls, smaller attack surface.

**4. Write a sample Terraform resource file**
```hcl
resource "aws_instance" "app_server" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.medium"
  subnet_id     = var.private_subnet_id
  tags = {
    Name        = "app-server"
    Environment = var.environment
  }
}
```
→ *Follow-up: "Where would you store the state?"* — Remote backend, S3 with DynamoDB table for state locking.

**5. Difference between git rebase and git merge**
Merge creates a new commit joining two branch histories, preserving both — safe for shared branches. Rebase replays your commits on top of the target branch, creating a linear history — cleaner, but rewrites commit hashes so it's risky on shared/public branches.
→ *Follow-up: "Which do you use before raising a PR?"* — Rebase locally to keep history clean, merge (not rebase) once it's a shared/public branch.

**6. Difference between CMD and ENTRYPOINT**
CMD provides default arguments that can be overridden entirely at `docker run`. ENTRYPOINT sets a fixed executable that always runs, and any CMD or run-time args just get appended to it — used when you want the container to behave like a fixed command.

**7. Explain Prometheus and Grafana**
Prometheus is a time-series monitoring system — it scrapes metrics (CPU, memory, pod status) from targets via exporters at set intervals and stores them. Grafana is the visualization layer — it queries Prometheus (or other data sources) with PromQL and renders dashboards and alerts.

**8. Approach if pod.yaml deployment failed**
First `kubectl apply` with `--dry-run` or `kubectl describe pod` to see the exact error (bad image, missing ConfigMap, resource limits, syntax). Check `kubectl get events` for scheduling failures, then fix and reapply. If it's a live rollout, `kubectl rollout status` and `kubectl rollout undo` if needed.

**9. Explain blue-green deployment**
Two identical environments (blue = current live, green = new version). Deploy the new version to green, test it fully, then switch traffic (via load balancer/Ingress) from blue to green in one shot. If issues arise, switch back to blue instantly — near-zero downtime and instant rollback.
→ *Follow-up: "Blue-green vs canary?"* — Blue-green switches all traffic at once; canary shifts a small % of traffic gradually to catch issues before full rollout.

**10. Explain Kubernetes architecture**
Control plane (API server, scheduler, controller manager, etcd) manages cluster state and scheduling decisions. Worker nodes run kubelet (talks to API server), kube-proxy (networking), and the container runtime, hosting the actual pods.

**11. Commands used in Kubernetes**
`kubectl get/describe/logs`, `kubectl apply -f`, `kubectl exec -it`, `kubectl rollout status/undo`, `kubectl scale`, `kubectl drain/cordon`, `kubectl top pod/node`, `kubectl port-forward` for local debugging.

**12. App crashed and you can't exec into the pod — approach**
If the container keeps restarting I can't get a live shell, so I check `kubectl logs <pod> --previous` for the last run's logs before it crashed, and `kubectl describe pod` for events (OOMKilled, failed probes, image pull errors). If needed, I temporarily override the container command (`sleep infinity`) via a debug deployment to get a shell without the app running.

**13. Explain your project pipeline**
GitHub → Trivy filesystem scan → SonarQube code quality/vulnerability scan → Docker build → Trivy image scan → push to ECR/Docker Hub → ArgoCD syncs the new image to EKS via GitOps, Helm for templating in some services.

**14. Have you worked on production deployment activity?**
Yes — I handle production EKS deployments and monitoring directly, including node upgrades, rollbacks, and incident response for the client-facing insurance application.

**15. How frequently do you deploy to production?**
Depends on the service — feature releases go out a few times a week via ArgoCD after passing UAT, hotfixes go out same-day when needed.

---

## Set 2

**1. Introduction** — same as Set 1, Q1.

**2. Current company/project related questions**
Navigator Software, insurance-domain client. I own the AWS account, EKS clusters, CI/CD pipelines, and databases for the main project, plus onboard new projects onto EKS as they come in.

**3. Daily tasks/activities** — same as Set 1 day-to-day answer.

**4. What is Prometheus, Grafana, Loki**
Prometheus collects and stores metrics. Grafana visualizes metrics from Prometheus (and other sources) as dashboards. Loki is Grafana's log aggregation system — like Prometheus but for logs instead of metrics, queried with LogQL.

**5. What is Kibana**
The visualization layer of the ELK stack — queries and visualizes log data stored in Elasticsearch, similar in role to Grafana but purpose-built for Elasticsearch indices.

**6. How does Prometheus collect metrics**
Pull-based — it scrapes `/metrics` HTTP endpoints on targets at a configured interval, either apps that expose Prometheus-format metrics natively or via exporters (node-exporter for host metrics, kube-state-metrics for K8s object state).

**7. How is Prometheus set up**
Typically via the `kube-prometheus-stack` Helm chart in-cluster — deploys Prometheus server, Alertmanager, node-exporter, and kube-state-metrics together, configured with scrape targets via ServiceMonitors.

**8. How is Kibana set up**
Deployed alongside Elasticsearch (and usually Filebeat/Logstash to ship logs in) — Kibana connects to the Elasticsearch cluster, and you define index patterns in Kibana to query and visualize the ingested log indices.

**9. What is a logrotate job and how does it work**
A scheduled job (cron-based) that rotates log files once they hit a size/age threshold — renames the current log, compresses old ones, and deletes logs past a retention period, so disks don't fill up from unbounded log growth.

**10. What is Jenkins, Ansible**
Jenkins is a CI/CD automation server — runs build/test/deploy pipelines defined in Jenkinsfiles, triggered by code commits. Ansible is a configuration management/automation tool — agentless, uses YAML playbooks over SSH to configure servers, install packages, or push app deployments.

**11. What is Terraform, how do you use it, what resources have you provisioned**
Terraform is an Infrastructure-as-Code tool for declaratively provisioning cloud resources. I've used it mainly for VPCs, EKS clusters, and RDS instances in test/dev environments, using reusable modules parameterized per environment.

**12. What are Deployments, DaemonSets, StatefulSets**
Deployment manages stateless, interchangeable pod replicas with rolling updates. DaemonSet runs exactly one pod per node — used for node-level agents like log collectors or monitoring exporters. StatefulSet manages pods needing stable identity/storage — like databases — with ordered, predictable pod names and persistent volumes per pod.

**13. Basic Kubernetes commands** — same as Set 1, Q11.

**14. What is Docker, how do you use it, any Dockerfile you've written**
Docker packages an app with its dependencies into a portable container image. I write Dockerfiles for each microservice — multi-stage builds to keep images small, non-root user, only production dependencies in the final layer.

**15. Data sources for Grafana, Kibana**
Grafana: Prometheus, Loki, CloudWatch, InfluxDB, Elasticsearch. Kibana: Elasticsearch indices only — it's purpose-built as Elasticsearch's UI.

**16. How is traffic routed inside Kubernetes clusters**
kube-proxy programs iptables/IPVS rules so a Service's ClusterIP load-balances across matching pod endpoints. For external traffic, Ingress rules route by host/path to the right Service, which then routes to healthy pods via that same mechanism.

**17. ELB, Ingress questions**
ELB (AWS's load balancer) sits outside the cluster and directs external traffic in. Ingress is the in-cluster routing layer — the ALB Ingress Controller provisions and configures an ALB automatically based on Ingress resource rules (host/path routing, SSL).

**18. How do you receive alerts, how is it set up**
Alertmanager (paired with Prometheus) evaluates alert rules and routes firing alerts to Slack/email/PagerDuty based on severity and routing rules I define — e.g. pod crash-looping or high memory usage triggers a Slack alert to the on-call channel.

**19. What is a pod**
The smallest deployable unit in Kubernetes — one or more tightly coupled containers that share network namespace and storage, scheduled together on the same node.

**20. What are indices/index in Kibana**
An index is Elasticsearch's way of grouping related log documents (like a table) — Kibana index patterns point at these (e.g. `app-logs-*`) so you can search and visualize across time-based log indices.

**21. Cronjobs**
A Kubernetes object that runs a Job on a schedule (cron syntax) — I've used them for scheduled tasks like DB backups, cleanup scripts, or report generation.

**22. PaaS questions**
PaaS (like Elastic Beanstalk, App Runner) abstracts away infra management — you deploy code/containers and the platform handles scaling, patching, and load balancing. Trade-off is less control versus IaaS/Kubernetes, but faster to ship for simpler apps.

**23. How do you handle disk, CPU alerts**
Alert thresholds set in Prometheus/Alertmanager (e.g. disk >85%, CPU >80% sustained). On disk alerts I check for log/cache bloat and clean up or expand the volume; on CPU I check if it's a genuine load spike (scale via HPA) or a runaway process/memory leak needing a fix.

**24. What Kubernetes issues have you worked on**
CrashLoopBackOff from misconfigured probes, OOMKilled pods from under-set memory limits, node upgrade compatibility issues, spot-instance capacity causing pod evictions in prod (moved prod to on-demand).

**25. Pod/node down — how do you troubleshoot/monitor**
Grafana/Prometheus alerts flag it first. `kubectl get nodes`/`get pods -o wide` to confirm, `kubectl describe` for events, check node conditions (disk pressure, memory pressure, not-ready). If a node is down, K8s reschedules pods automatically if capacity allows; I check cluster autoscaler logs if it doesn't.

---

## Set 3 (YOE: 3 yrs)

**1. Day to day activities** — same as Set 1.

**2. How do you reduce Docker image size**
Multi-stage builds (only copy final artifacts to the runtime image), use alpine/slim base images, combine RUN commands to reduce layers, add a `.dockerignore`, remove build tools/cache from the final image.

**3. What is HPA and how do you implement it**
Horizontal Pod Autoscaler automatically scales pod replica count based on metrics (CPU/memory, or custom metrics). Implemented via `kubectl autoscale` or a HorizontalPodAutoscaler manifest specifying target CPU utilization and min/max replicas — requires resource requests set on the pods for it to calculate against.

**4. Your branching strategy**
Git Flow-style — `main` for production, `develop` for integration, feature branches off `develop`, hotfix branches off `main` for urgent prod fixes, merged back via PR with review.

**5. What is pod affinity**
A scheduling rule that tells Kubernetes to place pods on the same node (or same zone) as other pods matching a label — used to co-locate pods that benefit from proximity (low latency). Anti-affinity does the opposite — spreads pods apart for high availability.

**6. Team size** — [fill with your actual number].

**7. How many pods do you manage** — ~150 pods across ~8-10 microservices (from your resume/earlier answer).

**8. Explain K8s architecture** — same as Set 1, Q10.

**9. What is a security group, default traffic rule**
A virtual firewall at the instance/ENI level in AWS, stateful, controlling inbound/outbound traffic by rules. Default: all outbound traffic is allowed, all inbound traffic is denied unless explicitly allowed.

**10. One task/tool you built from scratch**
[New story — pick one, e.g.:] I set up the Prometheus + Grafana monitoring stack from scratch for the project — nothing existed before, so I deployed kube-prometheus-stack, configured ServiceMonitors for our services, built dashboards for pod health/latency/error rate, and set up Alertmanager routing to Slack for on-call alerts.

**11. Difficulties building a Docker image**
Bloated image size from unnecessary layers/dependencies (fixed with multi-stage builds), and dependency version mismatches between local dev and CI build environment — solved by pinning versions in the Dockerfile instead of relying on `latest`.

**12. Why is Terraform used**
Declarative, version-controlled infrastructure — instead of manually clicking through AWS console, infra changes go through code review, are reproducible across environments, and drift can be detected via `terraform plan`.

**13. Terraform modules you use** — VPC, EKS, RDS modules, parameterized per environment (dev/UAT/prod).

**14. What do you work on in K8s** — Deployments, Services, Ingress, ConfigMaps/Secrets, HPA, namespaces, RBAC, troubleshooting crash loops and resource issues.

**15. Tools used in your project** — Jenkins/GitHub Actions, ArgoCD, Helm, Terraform, Prometheus/Grafana, SonarQube, Trivy, EKS, RDS, Redis.

**16. Overview of your client** — Insurance-domain client (not banking) — customer-facing web application plus internal office tooling, hosted on EKS.

**17. How do you set up a Prometheus dashboard**
Define the PromQL queries for the metrics I want (pod CPU/memory, request rate, error rate), build panels in Grafana pointing at the Prometheus data source, arrange into a dashboard, and set alert thresholds on the panels that need paging.

**18. How is data fetched to Prometheus** — same as Set 2, Q6 (pull-based scraping).

**19. Alerts set up on Grafana** — pod restart count spikes, memory/CPU thresholds, HTTP error rate (5xx) spikes, pod not-ready for >X minutes.

**20. Python scripting experience**
[Answer honestly based on your actual level — if light: "Basic scripting for automation tasks like log parsing and simple AWS SDK (boto3) scripts for cleanup jobs, not deep application development."]

---

## Set 4 (Exp: 5+, Role: SRE)

**1. What is SLI, SLA, SLO, Error Budget**
SLI is the actual measured metric (e.g. request success rate). SLO is the internal target for that SLI (e.g. 99.9% success). SLA is the external, often contractual, commitment to customers (usually looser than the SLO). Error Budget is the allowed amount of failure within the SLO (100% - SLO) — how much you can "spend" on risk/deploys before breaching it.

**2. Difference between monitoring and observability**
Monitoring tells you *that* something is wrong via predefined metrics/alerts. Observability lets you ask *why* — using metrics, logs, and traces together to debug issues you didn't anticipate in advance.

**3. Users complain about latency — how does monitoring help you find and fix it**
Check Grafana for latency percentiles (p50/p95/p99) and correlate with the time window reported, check if it's app-level (slow DB queries, high CPU) or infra-level (pod resource throttling, network). Drill into traces/logs for the slow requests, check downstream dependency latency, then act — scale, optimize the query, or fix the bottleneck.

**4. What is Chaos Engineering**
Deliberately injecting failures (killing pods, adding network latency, simulating AZ outages) into a system in a controlled way to verify it degrades gracefully and recovers as expected, rather than discovering weaknesses during a real incident.

**5. AWS services used** — EKS, EC2, RDS, S3, ALB/ELB, IAM, VPC, CloudWatch, Route53, ECR.

**6. How do you make cloud infrastructure more secure**
Least-privilege IAM policies, security groups scoped tightly, encryption at rest/in transit, private subnets for backend resources, regular vulnerability scanning (Trivy/SonarQube), and MFA + no long-lived credentials where avoidable.

**7. How to secure an S3 bucket**
Block public access at the account/bucket level, use bucket policies scoped to specific roles, enable encryption (SSE-S3/KMS), enable versioning and access logging, and use IAM roles rather than embedding keys.

**8. Updating private-subnet instances without direct internet access**
Route outbound traffic through a NAT Gateway in the public subnet — private instances use it to reach the internet (e.g., package repos) for updates without being directly reachable from outside. For patch management specifically, I'd also consider AWS Systems Manager (SSM) Patch Manager, which doesn't need outbound internet on the instance at all.

**9. Ansible modules used**
`yum`/`apt` for packages, `copy`/`template` for config files, `service`/`systemd` for service management, `user` for account management, `shell`/`command` for ad-hoc tasks.
→ *(Adjust to your actual experience — say honestly if this is limited.)*

**10. Terraform experience** — same as Set 3, Q12/13.

**11. CI/CD tool used** — Jenkins and GitHub Actions for CI, ArgoCD for CD.

**12. Explain the CD pipeline you built, steps and tools**
GitHub → Trivy scan → SonarQube scan → Docker build → Trivy image scan → push to ECR → ArgoCD auto-syncs the new manifest/image to EKS. All CD is GitOps-driven — no manual `kubectl apply` to prod.

**13. Managing K8s cluster — Helm/CLI/Rancher/ArgoCD**
Primarily ArgoCD for GitOps-based deployment management, Helm for templating some services, and `kubectl` directly for troubleshooting/ad-hoc operations. No Rancher experience.

**14. Pod in CrashLoopBackOff — possible causes**
Application crashing on startup (bad config/missing env var), failing readiness/liveness probe, OOMKilled from too-low memory limits, missing dependency (DB not reachable), or a bad image/entrypoint. I'd check `kubectl logs --previous` and `kubectl describe pod` first to narrow it down.
→ *Follow-up: "How do you fix an OOMKilled pod?"* — Check actual memory usage via Grafana/`kubectl top`, raise the memory limit if it's genuinely under-provisioned, or fix a memory leak if usage climbs unbounded over time.

**15. Python experience** — same as Set 3, Q20, be honest about level.

**16. Monitoring experience — tools, what you did**
Prometheus + Grafana for metrics and dashboards, Alertmanager for routing alerts to Slack, ELK/Loki for logs. Built dashboards for pod health, latency, and error rates, and set alert thresholds for proactive incident response rather than reactive firefighting.

**17. Team management experience** — [answer based on your actual experience; if none, say so plainly rather than inventing it].

**18. Experience creating client proposals** — [answer honestly; if none: "Not directly — that's usually handled by leads/managers, but I provide the technical input/estimates that go into them."]

---

## New "real problem I fixed" story (not spot/RI — use this for Set 3 Q10 or any open-ended "tell me a problem you solved")

**Problem:** Pods were repeatedly hitting CrashLoopBackOff / getting OOMKilled during peak traffic, causing intermittent 5xx errors for users.
**Diagnosis:** Grafana memory graphs showed pod memory climbing steadily until hitting the configured limit, then getting killed and restarted — classic under-provisioned resource limits combined with a service handling more load than originally sized for.
**Fix:** Right-sized memory requests/limits based on actual observed usage (not guesswork), and added a HorizontalPodAutoscaler on CPU so the service scales out horizontally under load instead of single pods getting overwhelmed.
**Result:** Crash-loop incidents dropped to zero after the change, and p95 latency during peak hours improved since traffic was spread across more replicas.

This is a good one to keep in your back pocket — it's specific, has a clear diagnosis step (shows monitoring skill), and a measurable result.
