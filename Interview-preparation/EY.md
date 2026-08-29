# E&Y Interview Prep — Answers + Likely Follow-ups

Note: no transcript this time, so these are model answers to prepare from — adapt wording to your actual project details.

---

## Set 1

### 1.1 Introduction
I'm a DevOps engineer with 4+ years of experience, currently at Navigator Software working on an insurance-domain platform. I manage AWS infra, EKS clusters, CI/CD pipelines (GitHub Actions/Jenkins + ArgoCD), monitoring with Prometheus/Grafana, and cost optimization. Before this, I worked at Unified Infotech on CI/CD, SonarQube, and security scanning (Trivy).
**Follow-up:** *"What's your strongest area — Kubernetes, CI/CD, or cloud cost?"* → Pick one honestly and have a 20-second story ready.

### 1.2 Explain current project
It's an insurance-domain application deployed on EKS — I own the AWS account, CI/CD pipelines, cluster operations, and databases end-to-end. Pipeline: GitHub → Trivy/SonarQube scans → build → image scan → ECR/Docker Hub → ArgoCD deploys to EKS. ~150 pods, 8-10 microservices, monitored via Prometheus/Grafana.
**Follow-up:** *"What's the trickiest problem you've solved on this project?"* → Have your spot-instance / RI cost-saving story ready.

### 1.3 Kubernetes — Deployments, Services, ConfigMaps
A **Deployment** manages a ReplicaSet of pods, handles rolling updates and rollback. A **Service** gives pods a stable network identity (ClusterIP for internal, NodePort/LoadBalancer for external) since pod IPs change. A **ConfigMap** stores non-sensitive config (env vars, config files) separately from the image, so config changes don't require rebuilding the image.
**Follow-up:** *"How do you roll back a bad deployment?"* → `kubectl rollout undo deployment/<name>`, or in ArgoCD, sync back to the previous Git commit.

### 1.4 How to integrate Grafana with Prometheus
Prometheus scrapes metrics from targets (via exporters/ServiceMonitors) and stores them as time-series data. In Grafana, you add Prometheus as a data source (its HTTP endpoint), then build dashboards using PromQL queries against that data source. In EKS I typically use kube-prometheus-stack (Helm chart) which wires both up together with pre-built dashboards.
**Follow-up:** *"Write a sample PromQL query."* → e.g. `rate(http_requests_total[5m])` for request rate over 5 minutes.

### 1.5 Terraform
I've used Terraform for provisioning VPC, EKS, and RDS via reusable modules, parameterized per environment (dev/UAT/prod) using variables and separate `.tfvars` files. More exposure at smaller/test-environment scale than large multi-team codebases.
**Follow-up:** *"What's Terraform state, and how do you manage it in a team?"* → State tracks real infra vs. code; in teams, store it remotely (S3 + DynamoDB lock) so multiple people don't corrupt it with concurrent applies.

### 1.6 Service Mesh
A service mesh (e.g. Istio, Linkerd) adds a sidecar proxy to each pod to handle service-to-service traffic — giving you mTLS encryption, retries/timeouts, traffic splitting (canary), and observability (latency, error rates) without changing application code.
**Follow-up:** *"Have you used one in production?"* → Answer honestly; if not, say "I understand the concept and use-case but haven't run one in production — most of my traffic control has been via Ingress/ALB rules directly."

### 1.7 Pod Disruption Budget
A PDB defines the minimum number/percentage of pods that must stay available during voluntary disruptions like node drains or cluster upgrades — so Kubernetes won't evict too many pods of the same app at once and cause an outage.
**Follow-up:** *"How does this differ from a HorizontalPodAutoscaler?"* → HPA scales pod count based on load; PDB limits how many pods can be *taken down* during maintenance — different problems entirely.

### 1.8 Git Squash
Squashing combines multiple commits into one before merging — used to keep the main branch history clean (e.g. collapsing 10 "fix typo" commits into a single meaningful commit) via `git rebase -i` and marking commits as `squash`.
**Follow-up:** *"When would you NOT squash?"* → When you want to preserve granular history for debugging (`git bisect`) on a shared long-lived branch.

### 1.9 Git Rebase
Rebase replays your branch's commits on top of another branch's latest commit, creating a linear history (vs. merge, which creates a merge commit). Command: `git rebase main` while on your feature branch. Rewrites commit history, so avoid rebasing commits already pushed/shared with others.
**Follow-up:** *"Rebase vs merge — when do you use which?"* → Rebase for cleaning up your own local feature branch before opening a PR; merge for combining branches that others depend on, to avoid rewriting shared history.

### 1.10 Purpose of Docker
Docker packages an application with its dependencies and runtime into a single portable image, so it runs identically across dev, test, and prod — eliminating "works on my machine" issues, and enabling fast, consistent deployment via containers on any Docker-compatible host or orchestrator like Kubernetes.
**Follow-up:** *"Difference between an image and a container?"* → Image is the static, immutable template; container is a running instance of that image.

---

## Set 2

### 2.1 Explain the Kubernetes architecture and how it works
Control plane (API server, etcd, scheduler, controller manager) manages cluster state; worker nodes run the kubelet, kube-proxy, and container runtime to actually run pods. You declare desired state via manifests to the API server, etcd stores it, the scheduler places pods on nodes, and controllers continuously reconcile actual state to match desired state.
**Follow-up:** *"What does etcd store, and what happens if it's unavailable?"* → Stores all cluster state (objects, configs, secrets); if etcd is down, the cluster can't accept new changes, though already-running pods keep running.

### 2.2 What is a Deployment in Kubernetes?
A higher-level object that manages ReplicaSets, which manage Pods — giving you declarative updates, rolling deployments, and easy rollback, rather than managing pods manually.
**Follow-up:** *"How do you do a rolling update with zero downtime?"* → Set `maxUnavailable`/`maxSurge` in the Deployment strategy so old pods are replaced gradually while new ones pass readiness checks first.

### 2.3 What is a Service in Kubernetes?
A stable network abstraction over a set of pods (selected by labels), so other components don't need to track individual pod IPs, which change as pods are recreated. Types: ClusterIP (internal), NodePort, LoadBalancer, ExternalName.
**Follow-up:** *"How does a Service know which pods to send traffic to?"* → Label selectors — the Service targets pods matching specific labels, and Endpoints/EndpointSlices track their current IPs.

### 2.4 How does Pod-to-Pod communication work?
Every pod gets its own cluster-internal IP; pods communicate directly over this flat network (no NAT between pods) via the CNI plugin (e.g. VPC CNI on EKS). For pods to find each other reliably despite IP changes, they typically go through a Service using cluster DNS (`service.namespace.svc.cluster.local`).
**Follow-up:** *"What CNI have you used, and why does it matter?"* → AWS VPC CNI on EKS — assigns pods real VPC IPs, which matters for direct integration with AWS networking/security groups.

### 2.5 What is Git Rebase?
*(Same as 1.9 — reuse that answer.)*

### 2.6 Explain your current project
*(Same as 1.2 — reuse, but tailor detail to the flow of the conversation so it doesn't sound copy-pasted.)*

### 2.7 What is a Pod Disruption Budget?
*(Same as 1.7.)*

### 2.8 What is the purpose of Docker?
*(Same as 1.10.)*

### 2.9 What is CrashLoopBackOff in Kubernetes?
It means a pod's container keeps crashing and Kubernetes keeps restarting it with an increasing backoff delay. Common causes: application error on startup, misconfigured env vars/secrets, failing liveness probe, or missing dependency. I'd check `kubectl describe pod` and `kubectl logs --previous` to find the root cause.
**Follow-up:** *"How do you debug this in production quickly?"* → Check recent deploys/config changes first (most common cause), then logs, then resource limits (OOMKilled shows here too).

### 2.10 Have you deployed both applications and infrastructure? What's your main tech stack?
Yes — both. Infra: AWS (EKS, VPC, RDS, EC2), provisioned partly via Terraform. Applications: containerized services deployed via CI/CD (GitHub Actions/Jenkins) and GitOps (ArgoCD) onto EKS, mainly supporting Python/Angular-based services in my current project.
**Follow-up:** *"Which do you enjoy more — infra or app deployment?"* → Answer honestly with a reason; shows self-awareness.

### 2.11 For Java applications, what tool do you use to build them?
Maven (or Gradle) — Maven compiles the code, runs tests, and packages it into a JAR/WAR using `mvn clean install`, pulling dependencies from a repository like Nexus/Maven Central as defined in `pom.xml`.
**Follow-up:** *"Have you configured a `pom.xml` yourself?"* → Answer honestly — if you've mainly consumed builds set up by developers, say so and pivot to what you *do* own (the pipeline stage that calls Maven).

### 2.12 Have you worked on Jenkins as CI/CD, or others like GitLab?
Primarily Jenkins and GitHub Actions for CI; deployment handled via ArgoCD (GitOps). I haven't used GitLab CI in production but understand its pipeline model is conceptually similar (`.gitlab-ci.yml` vs Jenkinsfile).

### 2.13 What source code management tool have you used?
GitHub, primarily — for source control, branch protection, PR review, and as the GitOps source of truth that ArgoCD syncs from.

### 2.14 Syntax/command to deploy an application using Helm Charts
`helm install <release-name> <chart-path-or-repo> -f values.yaml -n <namespace>` for first install; `helm upgrade <release-name> <chart> -f values.yaml` to update; `helm rollback <release-name> <revision>` to revert.
**Follow-up:** *"What's the difference between a Chart and a Release?"* → Chart is the packaged template definition; Release is a specific deployed instance of that chart with a given set of values.

### 2.15 How do you manage concurrent builds in Jenkins without degrading performance?
Use multiple Jenkins agents/executors so builds run in parallel rather than queuing on one node, set per-job concurrency limits (`disableConcurrentBuilds()` where builds shouldn't overlap, e.g. deploy jobs), and scale agents dynamically (e.g. Kubernetes-based Jenkins agents that spin up/down per build).
**Follow-up:** *"Have you used Jenkins on Kubernetes (dynamic agents)?"* → Answer honestly based on your real experience.

### 2.16 Difference between Declarative and Scripted pipelines
Declarative uses a structured, opinionated syntax (`pipeline { stages { ... } }`) that's easier to read/maintain and has built-in error handling. Scripted uses raw Groovy (`node { stage(...) }`), giving more flexibility but requiring more Groovy knowledge and being harder to maintain. Most teams default to Declarative now unless they need Scripted's flexibility for complex logic.

### 2.17 Artifact repositories (Nexus/Artifactory) — where do you store dependencies?
Yes, used Nexus for storing build artifacts and as a proxy/cache for Maven/npm dependencies, and Docker Hub/ECR for container images specifically. Nexus centralizes versioned artifacts so builds are reproducible and don't hit public repos every time.
**Follow-up:** *"Why use a private artifact repo instead of pulling straight from Maven Central/npm?"* → Speed (caching), reliability (no public repo outages breaking your build), and security (scan/control what versions are allowed).

### 2.18 What happens internally when you run a Maven build — how does it fetch dependencies?
Maven reads `pom.xml`, resolves the dependency tree, checks the local `.m2` repo cache first; if not found, fetches from the configured remote repository (Nexus/Maven Central) as defined in `settings.xml`/`pom.xml`, caches it locally, then compiles, runs tests, and packages the artifact.

### 2.19 Security tool integrations in your pipelines
Yes — SonarQube for static code analysis/code quality gates, Trivy for filesystem and container image vulnerability scanning, run at build time before the image is pushed, so vulnerable images never reach the registry.
**Follow-up:** *"What happens if a scan fails — does it block the pipeline?"* → Yes, quality/security gate failures should fail the build so vulnerable code doesn't get deployed.

### 2.20 What is Rolling Strategy and Canary-based deployment?
Rolling update replaces old pods with new ones gradually (controlled by maxSurge/maxUnavailable) with no full downtime, but all traffic eventually goes to the new version. Canary deployment releases the new version to a small subset of traffic first (e.g. 5-10%), monitors it, and gradually shifts more traffic if it's healthy — reducing blast radius of a bad release.
**Follow-up:** *"How would you implement canary in Kubernetes?"* → Via a service mesh (Istio traffic splitting) or tools like Argo Rollouts, which natively support canary/weighted traffic shifting.

### 2.21 What is Hash-based deployment?
Not a standard/common Kubernetes deployment term — likely referring to deployments tagged/tracked by a Git commit hash (image tag = commit SHA) rather than a version number, ensuring traceability of exactly which code is running. Worth clarifying with the interviewer what they mean if asked live.
**Follow-up:** if pressed, tie it back to immutable image tagging: "We tag images with the Git commit SHA so every deployed version is traceable back to exact source code."

### 2.22 What is a Persistent Volume in Kubernetes?
Cluster-level storage resource that exists independently of pod lifecycle — so data survives pod restarts/rescheduling. A **PersistentVolumeClaim** is how a pod requests storage; it binds to a PV (dynamically via a StorageClass, or statically pre-provisioned).
**Follow-up:** *"What access modes does a PV support?"* → ReadWriteOnce (single node), ReadOnlyMany, ReadWriteMany (multiple nodes, needs backing storage like EFS).

### 2.23 What is a ConfigMap in Kubernetes?
*(Same as 1.3.)*

### 2.24 What is a Service Mesh and how does it work?
*(Same as 1.6.)*

### 2.25 What observability tools have you used, and what metrics do you monitor?
Prometheus for metrics collection and Grafana for dashboards/visualization; monitor pod/node CPU & memory, pod restart counts, request latency/error rate, and cluster health (node status, PVC usage). For logs, I check via kubectl/ArgoCD; alerting is set up on Grafana for threshold breaches.
**Follow-up:** *"Have you set up alerting (Alertmanager)?"* → Answer based on real experience — if you've mainly *responded* to alerts rather than configured Alertmanager rules yourself, say that honestly.
