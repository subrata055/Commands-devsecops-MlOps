# DevOps Interview — KodeKloud Set — Prep Answers

---

### 1. Can you introduce yourself and tell us about your experience?
I'm a DevOps/SRE engineer with 4+ years of experience across cloud infrastructure, Kubernetes, and CI/CD automation. Currently at Navigator Software, where I manage AWS infrastructure, EKS clusters, and CI/CD pipelines for an insurance-domain client. Before that, at Unified Infotech I worked on CI/CD pipelines, SonarQube, and container security scanning with Trivy. My core strength is AWS + Kubernetes end-to-end: provisioning, pipeline design, monitoring, and cost optimization.

### 2. What certifications have you completed?
AWS Certified Solutions Architect and CKA (Certified Kubernetes Administrator), plus advanced DevOps training through IIT Madras via Intellipaat.

### 3. Why are you looking for a change now?
*(This needs to be your own honest reason — growth, scope, compensation, stability, etc. Don't let me guess it for you. Framing tip: keep it forward-looking and positive, never criticize your current employer. E.g. "I've grown a lot at my current org, but I'm looking for a role with larger scale/more ownership over architecture decisions" — fill in what's actually true for you.)*

### 4. What experience do you have with frontend technologies?
Be honest here — if it's minimal, say so briefly and pivot to what you do own: "My focus has been infra/platform, not frontend development directly, but I deploy and manage frontend apps (React/Angular, depending on project) — build pipelines, containerization, and serving them via Ingress/ALB — so I understand their deployment and performance needs even though I don't write frontend code."

### 5. What is AWS EKS and how do you work with it?
EKS is AWS's managed Kubernetes control plane — AWS handles the control plane (API server, etcd, scheduler) while I manage worker nodes and workloads. Day to day I provision/upgrade clusters, manage node groups (on-demand for prod, spot for dev/UAT), deploy via ArgoCD/Helm, and monitor with Prometheus/Grafana.

### 6. What is Aqua/AWS-VPC-CNI used for in EKS clusters?
*(I think this is "AWS VPC CNI" — the networking plugin, not "AI from Header." Confirm the exact term with the interviewer if unclear, but here's the likely answer:)*
The AWS VPC CNI plugin assigns each pod a real IP address from the VPC's subnet CIDR range, instead of an overlay network — so pods can communicate directly using native VPC networking, security groups, and routing, which simplifies integration with other AWS services.

### 7. What is the difference between security and network (as concepts)?
Networking is about connectivity — how traffic flows between resources (routing, subnets, load balancing). Security is about controlling and restricting that connectivity — who's allowed to talk to whom, encryption, authentication. In AWS terms: VPC/subnets/routing = networking; Security Groups/NACLs/IAM = security layered on top of that networking.

### 8. What is the difference between Security Groups and Network ACLs in AWS?
Security Groups are stateful and operate at the instance/ENI level — if you allow inbound traffic, the response is automatically allowed out. NACLs are stateless and operate at the subnet level — you must explicitly allow both inbound and outbound rules, and they support explicit deny rules, which Security Groups don't.

### 9. What is the difference between S3 Standard, Standard-IA, and One Zone-IA?
Standard is for frequently accessed data, stored redundantly across multiple AZs. Standard-IA is for infrequently accessed data — lower storage cost, but you pay a retrieval fee — still multi-AZ redundant. One Zone-IA is the same infrequent-access pricing model but stored in only a single AZ, so it's cheaper but has lower availability/durability if that AZ fails.

### 10. What is the difference between S3 Standard-IA and Glacier?
Standard-IA is for data you access occasionally but need with millisecond retrieval. Glacier is for archival data you rarely access — much cheaper storage, but retrieval takes minutes to hours (depending on tier: Instant, Flexible, Deep Archive) rather than being immediate.

### 11. When would you use an Application Load Balancer, and in which scenarios?
ALB is for HTTP/HTTPS traffic where you need Layer 7 features — path-based or host-based routing, SSL termination, and routing to different microservices/target groups based on URL. I use it for web applications and APIs where routing intelligence matters, e.g. our Ingress Controller setup in EKS.

### 12. What is the difference between ALB and NLB, and which OSI layers do they operate on?
ALB operates at Layer 7 (application layer) — understands HTTP/HTTPS, does content-based routing. NLB operates at Layer 4 (transport layer) — routes based on IP/port only, handles TCP/UDP, and is built for extreme performance and static IP support, not content awareness.

### 13. When should we use ALB versus NLB?
Use ALB when you need HTTP-aware routing — multiple services behind one load balancer, path/host rules, SSL termination. Use NLB when you need raw performance, low latency, static IPs, or non-HTTP protocols (like TCP-based databases or gRPC without HTTP routing needs).

### 14. If an Auto Scaling Group keeps rapidly launching and terminating instances, why, and how would you stabilize it?
This is usually a flapping health check or scaling policy issue — either the health check is too aggressive (marking healthy instances as unhealthy before they finish warming up) or the scaling policy's cooldown period is too short, causing scale-out and scale-in to fight each other. I'd check CloudWatch metrics/alarms triggering the scaling policy, increase the health check grace period, and add/adjust the cooldown period so the ASG doesn't react to short-lived spikes.

### 15. What is a Transit Gateway, and when would you use it?
A Transit Gateway is a central hub that connects multiple VPCs (and on-prem networks via VPN/Direct Connect) without needing a full mesh of individual VPC peering connections. I'd use it when there are many VPCs (e.g. per-environment or per-team VPCs) that all need to talk to each other or to a shared services VPC — it simplifies routing compared to managing dozens of peering connections.

### 16. What are the various kinds of services available in Kubernetes?
ClusterIP (internal-only), NodePort (exposes via node's IP and a static port), LoadBalancer (provisions a cloud load balancer, e.g. via ALB Controller), and ExternalName (maps a service to an external DNS name without proxying).

### 17. What is the smallest unit that contains containers in Kubernetes?
A Pod — it can hold one or more containers that share the same network namespace and storage volumes, and is the smallest deployable unit in Kubernetes.

### 18. What is etcd, and what role does it play?
etcd is the distributed key-value store that holds all cluster state — every object (pods, deployments, services, configmaps, secrets, etc.) is stored there. The API server reads/writes to etcd, and the scheduler/controllers watch it for changes. If etcd is lost or corrupted, the cluster loses its source of truth, which is why it's backed up regularly.

### 19. Do you know Telepresence, and how is it used?
*(Be honest if you haven't used it — brief answer plus concept is fine:)*
I haven't used it hands-on, but I know Telepresence lets you run a service locally on your machine while it behaves as if it's inside the Kubernetes cluster — intercepting traffic meant for that service so you can debug/develop against real cluster dependencies without deploying your local changes first.

### 20. What is state in Infrastructure as Code, and how do you manage it?
State is Terraform's record of what resources it has created and their current configuration — it maps your `.tf` code to real-world infrastructure so Terraform knows what to create, update, or destroy on the next apply. I manage it using a remote backend (e.g. S3 with DynamoDB for state locking) rather than local state files, so it's shared safely across a team and avoids conflicting concurrent applies.
