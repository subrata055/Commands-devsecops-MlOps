# DevOps Interview Prep — AMEX & Arrise Solutions

---

## AMEX (YOE ~3 yrs)

### 1. Difference between Docker and Kubernetes?
Docker packages and runs a single containerized application on one host. Kubernetes is an orchestrator that manages many containers across many hosts — scheduling, scaling, self-healing, service discovery, and rolling updates. Docker builds the box; Kubernetes runs the fleet.

### 2. How do you reduce downtime with deployments?
Use rolling updates (default in K8s) so old pods are only terminated after new ones pass readiness checks; set proper readiness/liveness probes and `maxUnavailable`/`maxSurge`; for riskier changes use blue-green or canary deployments (via Argo Rollouts or traffic-split) so you can catch issues before full rollout and roll back instantly.

### 3. What agents have you deployed?
In my environment: Prometheus node-exporter and Grafana agent for metrics, Fluentd/Fluent Bit as the logging agent shipping to a central log store, and the ALB Ingress Controller and cluster-autoscaler as cluster-management agents/controllers.

### 4. With 100 applications, how do you do log analysis?
Centralize logs — each pod's stdout/stderr is collected by a Fluent Bit/Fluentd DaemonSet and shipped to a central store like ELK/OpenSearch or CloudWatch Logs, tagged with pod/namespace/app labels. Then I query/filter by labels and use dashboards + alerting rules instead of checking 100 apps individually.

### 5. Difference between SRE and DevOps?
DevOps is the culture/practice of breaking down the dev-ops silo and automating the delivery pipeline. SRE is a specific implementation of that philosophy — applies software engineering to operations, with concrete practices like SLOs/error budgets, blameless postmortems, and treating toil reduction as an engineering problem. SRE is more metrics/reliability-driven; DevOps is broader (CI/CD, culture, automation).

### 6. Have you done on-premises to cloud migration? Challenges?
Yes — migrated an on-prem application to EKS using rolling cutover (deploy to EKS, validate, redirect traffic, then decommission on-prem). Main challenges: minimizing downtime during cutover, re-architecting persistent storage/database connectivity for cloud networking, and handling app configs that assumed static on-prem IPs.

### 7. How does endpoint authentication work in Kubernetes?
Every request to the API server is authenticated first (via client certs, bearer/service account tokens, or OIDC), then authorized via RBAC (Role/RoleBinding), then passed through admission controllers. For pod-to-AWS-service auth, we use IRSA (IAM Roles for Service Accounts) so pods assume scoped IAM roles without static credentials.

### 8. How did you troubleshoot a pod CrashLoopBackOff?
`kubectl describe pod` to check events, `kubectl logs <pod> --previous` to see why the last container exited. Common causes I've hit: app failing on missing env var/config, liveness probe too aggressive killing a slow-starting app, or OOMKilled from too-low memory limits — fix depends on which of those it is.

### 9. What is SLA and SLO?
SLA (Service Level Agreement) is the external, often contractual, promise to customers — e.g. "99.9% uptime or credits apply." SLO (Service Level Objective) is the internal target we engineer to, usually stricter than the SLA, so we breach the SLO internally before ever breaching the customer-facing SLA.

### 10. Which agent have you worked with for a customer/your company?
For monitoring: Prometheus + Grafana stack; for logging: Fluent Bit shipping to CloudWatch/OpenSearch; for security scanning: Trivy as an agent in the CI pipeline.

### 11. Tell me the cloud architecture you've worked on.
AWS-based: EKS cluster running microservices split across prod/UAT/dev namespaces, ALB Ingress Controller for external traffic, RDS for the database, Redis for caching, S3 for static assets, CI/CD via GitHub Actions/Jenkins building images pushed to ECR, deployed via ArgoCD (GitOps), monitored with Prometheus/Grafana.

### 12. Explain a production issue you've faced.
Spot instances in the prod EKS node group caused intermittent slowness when AWS reclaimed capacity. I diagnosed it via Grafana (pod evictions/rescheduling spikes correlating with node terminations), then moved prod node groups to on-demand while keeping dev/UAT on spot to control cost — eliminated the slowness with a small cost tradeoff.

---

## Arrise Solutions (Exp ~7 yrs)

### 1. Explain three-tier architecture.
Presentation tier (frontend/UI), application/logic tier (backend/API servers processing business logic), and data tier (database). Each tier is typically isolated in its own subnet/security boundary — e.g. web tier in a public subnet, app and DB tiers in private subnets — so only necessary traffic flows between layers.

### 2. Difference between ALB and NLB (in depth)?
ALB (Application Load Balancer) operates at Layer 7 (HTTP/HTTPS) — supports path/host-based routing, SSL termination, WebSocket. NLB (Network Load Balancer) operates at Layer 4 (TCP/UDP) — ultra-low latency, handles millions of requests/sec, preserves client source IP, and can have a static IP per AZ. Use ALB for web apps needing routing rules; use NLB for raw TCP performance, static IP requirements, or non-HTTP protocols.

### 3. How do you connect a VPC in AWS to a VPC in IBM Cloud?
Set up a Site-to-Site VPN (IPsec tunnel) between an AWS Virtual Private Gateway/Transit Gateway and IBM Cloud's VPN gateway, or use a dedicated interconnect (AWS Direct Connect + IBM Cloud Direct Link via a shared colocation) for private, non-internet connectivity. Route tables on both sides are updated to route traffic through the tunnel/interconnect.

### 4. Difference between public and private subnet?
A public subnet has a route to an Internet Gateway, so resources with public IPs are directly internet-reachable. A private subnet has no direct route to an Internet Gateway — outbound internet access (if needed) goes through a NAT Gateway, and it's not reachable from the internet inbound.

### 5. How do you connect your private subnet to the internet?
Route the private subnet's outbound traffic through a NAT Gateway (placed in a public subnet) — the private subnet's route table sends `0.0.0.0/0` traffic to the NAT Gateway, which then forwards it via the Internet Gateway. This allows outbound-only access; nothing from the internet can initiate a connection back in.

### 6. Does a NAT Gateway run in a public or private subnet?
Public subnet — it needs a route to the Internet Gateway itself to forward traffic on behalf of private subnet resources.

### 7. Kubernetes architecture?
Control plane: API server (entry point for all requests), etcd (cluster state store), scheduler (assigns pods to nodes), controller manager (reconciles desired vs actual state). Worker nodes: kubelet (manages pod lifecycle on the node), kube-proxy (handles networking/service routing), and the container runtime.

### 8. CoreDNS in Kubernetes?
CoreDNS is the cluster's internal DNS server — it resolves service names (`<service>.<namespace>.svc.cluster.local`) to ClusterIPs, enabling service discovery so pods can reach each other by name instead of hardcoded IPs.

### 9. Purpose of CNI?
CNI (Container Network Interface) is the plugin standard that provisions pod networking — assigns each pod an IP, sets up routing so pods can communicate across nodes, and (with plugins like Calico) enforces NetworkPolicies. Without a CNI plugin, pods have no network connectivity.

### 10. How does kube-proxy communicate with nodes?
kube-proxy runs as a daemon on every node and watches the API server for Service/Endpoint changes, then programs the node's networking rules (iptables or IPVS) so traffic to a Service's ClusterIP gets load-balanced to the correct backend pod — it doesn't "communicate with nodes" directly, it configures local networking rules on each node based on cluster state.

### 11. Purpose of the scheduler in Kubernetes?
Watches for newly created pods with no assigned node, then selects the best-fit node based on resource requests/limits, affinity/anti-affinity rules, taints/tolerations, and constraints — then binds the pod to that node.

### 12. Layers in Docker?
Each instruction in a Dockerfile (FROM, RUN, COPY, etc.) creates a read-only image layer, cached and stacked on top of each other. At runtime, Docker adds a thin writable container layer on top — this layering enables image caching/reuse and smaller incremental builds.

### 13. Difference between using a VM vs Docker?
A VM virtualizes hardware and runs a full guest OS (kernel + all) via a hypervisor — heavier, slower to boot, more isolated. Docker containers share the host OS kernel and only isolate the process/filesystem — much lighter, start in seconds, but slightly less isolation than a VM.

### 14. Types of storage drivers in Docker?
Common ones: overlay2 (default on modern Linux, most efficient), aufs, devicemapper, btrfs, zfs, and vfs (simplest, no copy-on-write, used mainly for testing). overlay2 is what you'll use in virtually all production setups today.

### 15. Types of networking in Docker (explain in detail)?
- **bridge** (default): containers get a private internal network, NAT'd to the host — used for standalone containers.
- **host**: container shares the host's network namespace directly — no isolation, no NAT, best performance.
- **overlay**: spans multiple Docker hosts (used in Swarm) for multi-host container communication.
- **macvlan**: assigns a container its own MAC/IP on the physical network, appearing as a real device on the LAN.
- **none**: no networking at all, fully isolated.

### 16. Does Docker have a kernel in place?
No — Docker containers don't have their own kernel; they share the host machine's kernel. This is why a Linux container can't run natively on a Windows kernel without a compatibility layer (like WSL2/Hyper-V).

### 17. cname and namespace in Docker?
In Docker, "namespace" refers to Linux kernel namespaces (PID, network, mount, UTS, IPC, user) that give each container its isolated view of processes, network, filesystem, etc. — this is the core isolation mechanism, distinct from Kubernetes namespaces. (If asked about "CNAME" specifically, that's a DNS record type, not a Docker-native concept — clarify which they mean before answering.)

### 18. Which network is used to isolate communication between two containers?
The default bridge network already isolates containers from the host network, but for isolating specific containers from each other, create a custom user-defined bridge network — containers not attached to it can't reach containers that are, since Docker's embedded DNS and network isolation only allow communication within the same custom network.

### 19. How do you check a Linux process?
`ps aux` (or `ps -ef`) lists all running processes; `top`/`htop` for a live, interactive view with resource usage; `pgrep <name>` to find a process by name.

### 20. Booting in Linux — what happens?
BIOS/UEFI POST → bootloader (GRUB) loads the kernel → kernel initializes hardware and mounts the initial root filesystem (initramfs) → kernel hands off to `init`/systemd (PID 1) → systemd starts services in order per target/runlevel → login prompt.

### 21. How do you check the load of a Linux machine?
`uptime` or `top`/`htop` shows load average (1/5/15 min). Compare the load average to the number of CPU cores — a load of 4 on a 4-core machine means it's fully utilized; higher means processes are queued waiting for CPU.

### 22. While rebooting a Linux machine, what stages/layers get restarted?
Everything: kernel reloads, all hardware re-initializes, all running processes are killed and systemd restarts all enabled services fresh, network interfaces re-initialize, and any in-memory state (caches, temp mounts) is lost — it's a full stack restart, not a partial one.

### 23. Kernel logs are stored under which directory?
Traditionally `/var/log/kern.log` (Debian/Ubuntu) or viewable via `dmesg`/`journalctl -k` on systemd systems, which read from the kernel ring buffer rather than a flat file directly.

### 24. How do you kill a running process?
`kill <PID>` sends SIGTERM (graceful shutdown); `kill -9 <PID>` sends SIGKILL (force kill, no cleanup). Can also use `pkill <name>` to kill by process name instead of looking up the PID first.

### 25. States of a Linux process?
Running (R), Sleeping — interruptible (S) or uninterruptible (D), Stopped (T), Zombie (Z, finished but not reaped by parent), and Dead. `ps aux` shows these in the STAT column.

### 26. When you type google.com in a browser, what happens at the backend?
Browser checks DNS cache, then queries DNS resolver → recursive lookup through root → TLD → authoritative nameserver to get the IP. Browser opens a TCP connection to that IP, performs a TLS handshake (cert validation, key exchange) if HTTPS, sends an HTTP GET request, server responds with HTML, and the browser parses/renders it — fetching additional assets (CSS/JS/images) along the way.

### 27. When you type the `top` command, what components are displayed?
Header: load average, uptime, number of users, task counts by state, CPU usage breakdown (user/system/idle/wait), memory and swap usage. Below that: per-process table (PID, user, CPU%, memory%, state, command).

### 28. CloudFront?
AWS's CDN — caches content at edge locations globally close to users, reducing latency for static/dynamic content, integrates with S3/ALB as origin, supports SSL, and can front an application to absorb traffic spikes and reduce load on origin servers.

### 29. Client and remote machine — how do certs communicate between them?
This is the SSL/TLS handshake: client requests a secure connection, server sends its certificate (containing its public key, signed by a CA), client verifies the cert against trusted CAs, then client and server negotiate a shared symmetric session key (via asymmetric key exchange) used to encrypt the rest of the communication — asymmetric crypto only sets up the connection; the actual data transfer uses fast symmetric encryption.

### 30. How does SSL work?
TLS handshake: client sends supported cipher suites → server responds with its certificate and chosen cipher → client validates the certificate chain against a trusted CA → client and server perform a key exchange (e.g. Diffie-Hellman) to derive a shared session key → all further traffic is encrypted with that symmetric session key, giving both confidentiality and integrity.
