# SRE Interview Prep — CMT & Commonwealth Bank

---

# SET 1 — CMT (SRE, 4-5 yrs)

### 1. Which AWS services have you used?
EC2, EKS, ECR, S3, RDS, VPC, IAM, ALB/NLB, CloudWatch, Route 53, ECS/Fargate (if applicable), Auto Scaling Groups, and Reserved/Spot instances for cost management. Group them by category (compute, networking, storage, monitoring) when you say it — sounds more organized than a flat list.
*Follow-up: "Which of these do you use most day-to-day?" → Say EC2/EKS + CloudWatch, since that's your actual daily work per your transcript.*

### 2. Design a highly available, fault-tolerant system in AWS
Multi-AZ deployment across at least 2-3 Availability Zones, Auto Scaling Group behind an ALB for compute, Multi-AZ RDS with a read replica, S3 for static/durable storage, Route 53 for DNS failover/health checks, and CloudWatch alarms driving auto-recovery. For fault tolerance specifically: no single point of failure at any layer — LB, compute, and DB all span AZs.
*Follow-up: "What if a whole region goes down?" → Cross-region replication (RDS read replica or S3 CRR) plus Route 53 failover routing to a standby region.*

### 3. What is DNS?
DNS translates human-readable domain names (google.com) into IP addresses that computers use to route traffic — it's a distributed, hierarchical lookup system (root → TLD → authoritative nameservers).

### 4. What is TCP and UDP?
TCP is connection-oriented, reliable, ordered delivery with handshake and retransmission — used where correctness matters (HTTP, databases). UDP is connectionless, faster, no delivery guarantee — used where speed matters more than reliability (DNS queries, video streaming, gaming).

### 5. What is IPv4 and IPv6?
IPv4 is the 32-bit addressing scheme (e.g. 192.168.1.1), giving ~4.3 billion addresses — largely exhausted. IPv6 is 128-bit (e.g. 2001:db8::1), designed to solve address exhaustion with a vastly larger space, plus built-in features like simplified auto-configuration.

### 6. What is PID?
Process ID — a unique identifier the Linux kernel assigns to every running process, used to monitor, signal, or kill that specific process (e.g. `kill -9 <PID>`).

### 7. How would you troubleshoot a Linux system that's down? (with commands)
Check if it's reachable: `ping`, `ssh`. If reachable, check load and resources: `top`/`htop`, `uptime`, `free -m`, `df -h`. Check what's failing: `systemctl status <service>`, `journalctl -xe`, `dmesg | tail`. Check network: `netstat -tulnp` or `ss -tulnp`. Check disk/logs: `tail -f /var/log/syslog`. Narrate this as a sequence, not a list — shows you triage methodically rather than randomly running commands.
*Follow-up: "What if SSH itself isn't responding?" → Check via cloud provider's serial/console access (EC2 Instance Connect / System Log), and check security group/network ACL rules first since that's the most common cause.*

### 8. Which production incidents have you attended — explain
Use your two real ones: spot-instance-caused prod slowness (root cause: spot capacity unavailability → fix: moved prod to on-demand) and the $10K/month EC2 database cost issue (root cause: over-provisioned on-demand → fix: Reserved Instance, saved ~$2.5K/month). State root cause → impact → fix → prevention for each.

### 9. Architecture of Kubernetes
Control plane (API server, etcd, scheduler, controller manager) manages cluster state; worker nodes run kubelet, kube-proxy, and the container runtime, hosting your actual pods. The API server is the single entry point — all components (including kubectl) talk to it, and etcd stores the cluster's desired state.
*Follow-up: "What happens if etcd goes down?" → No new scheduling/API writes can happen — existing pods keep running (kubelet doesn't depend on etcd directly), but the cluster can't self-heal or take new actions until etcd recovers.*

### 10. Terraform structure
Typical structure: `main.tf` (resources), `variables.tf` (input variables), `outputs.tf` (outputs), `terraform.tfvars` (variable values per environment), and a `modules/` directory for reusable components (VPC, EKS, RDS modules). State is stored remotely (S3 + DynamoDB lock) for team use.

### 11. How would you maintain high availability in ECS+Fargate or EKS?
Run multiple tasks/pods across multiple AZs, use an ALB for traffic distribution and health checks, set up auto-scaling (Fargate service auto-scaling or Cluster Autoscaler/HPA for EKS), and use readiness/liveness probes so unhealthy instances are automatically removed from rotation.

### 12. Difference between ALB and NLB — when to use each
ALB operates at Layer 7 (HTTP/HTTPS) — supports path/host-based routing, good for microservices and web apps. NLB operates at Layer 4 (TCP/UDP) — ultra-low latency, static IP support, handles millions of requests/sec, used for high-throughput or non-HTTP traffic (e.g. gaming, IoT, gRPC) or when you need a fixed IP.

### 13. Which metrics are used to monitor high availability of a webserver/app server?
Uptime/availability %, request latency (p50/p95/p99), error rate (4xx/5xx), throughput (requests/sec), and health check pass/fail status from the load balancer.

### 14. Did you use any automation in your daily work?
Yes — CI/CD pipelines auto-scan, build, and deploy via GitHub Actions/Jenkins + ArgoCD, Grafana alerting auto-notifies on threshold breaches, and EKS node upgrades use AWS's automated drain/update when safe to do so.

### 15. What metrics monitor EC2 CPU/memory in AWS?
CPUUtilization is a native CloudWatch metric. Memory isn't tracked by default — you need the CloudWatch Agent installed to push custom memory (`mem_used_percent`) and disk metrics.
*Follow-up: "Why doesn't CloudWatch track memory by default?" → Because AWS can't see inside the OS without an agent — CPU/network/disk-IO are hypervisor-visible, memory usage is not.*

### 16. If there's a slowness issue in a decoupled system (SQS), how would you handle it?
Check queue depth (`ApproximateNumberOfMessagesVisible`) — if it's growing, consumers aren't keeping up, so scale consumers or increase Lambda/ECS concurrency. Also check `ApproximateAgeOfOldestMessage` for backlog age, and consumer-side errors/throttling (e.g. downstream DB is the actual bottleneck, not SQS itself).

### 17. Best practices to keep systems highly available
Multi-AZ/multi-region redundancy, auto-scaling based on real metrics, health checks with automatic failover, no single point of failure, regular chaos/failover testing, proper monitoring+alerting, and infrastructure-as-code so recovery is repeatable, not manual.

---

# SET 2 — Commonwealth Bank (Principal SRE, 4-5 yrs)

### 1. What is observability architecture? Explain it.
It's the combination of three pillars — metrics, logs, and traces — collected, correlated, and visualized together so you can understand system behavior from the outside, including states you didn't predict in advance. Architecture typically: instrumentation (OpenTelemetry/agents) → collection/aggregation → storage (Prometheus, Loki, Tempo/Jaeger) → visualization/alerting (Grafana).
*Follow-up: "How do you correlate a log with a trace?" → Trace IDs/span IDs get injected into log lines, so you can jump from a log entry directly to the full distributed trace for that request.*

### 2. What is DNS? What happens in the background when you type google.com?
Browser checks its local cache, then OS cache, then queries a DNS resolver → resolver queries root nameserver → TLD (.com) nameserver → authoritative nameserver for google.com, which returns the IP. Browser then opens a TCP connection to that IP and starts the HTTP(S) request/TLS handshake.

### 3. Difference between observability and monitoring?
Monitoring tells you *when* something known is wrong (predefined dashboards/alerts for known failure modes). Observability lets you ask *new* questions about *unknown* problems, using raw data (metrics, logs, traces) you didn't necessarily anticipate needing — monitoring is a subset/application of observability.

### 4. We have logs — why do we need traces?
Logs tell you what happened at one point in one service, but in a microservices system a single request crosses many services — logs alone can't show you the request's full path or where time was actually spent. A trace stitches those individual log points together into one timeline across services, showing exactly where latency or failure occurred.

### 5. How are SLA and SLO set in an application — from a business perspective, not the formula?
Start from what the business/customer actually tolerates — e.g. "checkout must work 99.9% of the time or we lose revenue and trust." That tolerance becomes the SLO (internal target, stricter). The SLA is the external, often contractual promise to the customer, usually looser than the SLO so you have buffer before breaching a contract. It's a negotiation between reliability cost and business risk, not a pure engineering number.
*Follow-up: "Who should decide the SLO — engineering or business?" → Both, jointly — engineering informs what's achievable/cost, business informs what's actually needed for customer trust and revenue.*

### 6. How do you decide SLIs in an application?
Pick the metrics that reflect actual user experience for that service — e.g. for an API: request success rate and latency; for a queue-based system: processing delay. The SLI should measure what the customer feels, not just what's easy to collect.

### 7. Explain metrics, logs, and traces — including tools used
Metrics: numeric time-series data (CPU%, request rate, error rate) — Prometheus + Grafana. Logs: discrete timestamped event records — I've used the ELK stack / Grafana Loki. Traces: end-to-end request path across services with timing per hop — Jaeger or OpenTelemetry-based tracing, visualized in Grafana Tempo.

### 8. How does observability help maintain reliability?
It shortens time-to-detect and time-to-diagnose — instead of guessing during an incident, you can trace exactly which service/dependency is failing and why, reducing MTTR. It also surfaces slow degradation (rising latency, growing error rate) before it becomes a full outage, enabling proactive fixes.

---

## General notes for both rounds
- These are more senior/SRE-titled (Principal SRE, CMT) than your last transcript — expect deeper "why" follow-ups on every answer. Don't just define terms; be ready to say *why it matters* or *when it breaks*.
- Where you genuinely haven't used a tool/technique (e.g. tracing tools, OTel), it's fine to say "I understand the concept and its purpose but haven't implemented it hands-on" — that's more credible than guessing.
