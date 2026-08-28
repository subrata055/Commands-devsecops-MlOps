# DevOps Interview — Prep Answers (Set 2)

Same format: 1-4 line answer, plus likely follow-up questions to be ready for.

---

### 1. What is AWS Lambda and how do you design a serverless application?
Lambda runs code in response to events without managing servers — you pay per invocation/duration, it auto-scales, and has a max execution time (15 min). For a serverless app I'd combine Lambda with API Gateway (HTTP trigger), DynamoDB or RDS Proxy for data, S3 for storage, and EventBridge/SQS for async event-driven flows between functions.
**Follow-up:** *"How do you handle cold starts?"* → Keep functions small/lightweight, use provisioned concurrency for latency-sensitive paths, avoid heavy SDK init in the handler.
**Follow-up:** *"How does Lambda connect to a VPC/RDS?"* → Attach the Lambda to the VPC with an ENI in a private subnet, use RDS Proxy to avoid connection exhaustion since Lambda scales concurrently.

### 2. What is the difference between `terraform plan` and `terraform apply`?
`plan` shows a dry-run — what will change, add, or destroy — without touching real infrastructure. `apply` executes those changes against actual cloud resources and updates the state file.
**Follow-up:** *"What is the Terraform state file and why does it matter?"* → It tracks the mapping between your config and real-world resources; without it Terraform can't know what already exists, so it's usually stored remotely (S3 + DynamoDB lock) for team use.

### 3. What are your roles and responsibilities in your current project?
I manage the AWS account, EKS cluster, and CI/CD pipelines for an insurance-domain application — from monitoring (Prometheus/Grafana) to deployments (ArgoCD/Helm) to cost optimization and troubleshooting production issues. I also handle infra for new incoming projects — dev/UAT setup and initial deployment to EKS.
**Follow-up:** *"What's something you improved on your own initiative?"* → Have a concrete example ready (e.g. the spot-instance or Reserved Instance cost story) — this question is basically inviting you to repeat it.

### 4. Can you explain your end-to-end project?
An insurance-domain web application: frontend and backend deployed on EKS, with Redis and RDS for data. Code flows from GitHub through Jenkins/GitHub Actions CI (Trivy + SonarQube scans, build, image scan) to ECR/Docker Hub, then ArgoCD deploys to EKS following GitOps. I own the AWS infra, cluster operations, and cost management side of it.
**Follow-up:** *"What's the biggest technical challenge you faced on it?"* → Use the spot-instance-in-prod story or the microservices migration story — pick whichever fits the flow of conversation.

### 5. What AWS resources have you created using Terraform, and how do you promote a read replica to primary?
I've provisioned VPCs, EKS clusters, and RDS instances via Terraform modules. To promote a read replica to primary in Terraform, you remove the `replicate_source_db` attribute from the replica's resource block (or set it to null) and apply — this triggers RDS to promote it; you then need to update any dependent configs (like app connection strings) since the replica becomes an independent, writable instance.
**Follow-up:** *"Does Terraform handle this without downtime?"* → The promotion itself is an AWS-managed operation (a few minutes), but Terraform state must be updated afterward to reflect the resource is no longer a replica; you'd plan for a brief write-cutover window.

### 6. In Terraform, which parameter/code change makes a read replica the primary?
Remove (or set to `null`) the `replicate_source_db` argument in the `aws_db_instance` resource for that replica, then run `terraform apply`. This detaches it from the source and promotes it to a standalone primary instance.

### 7. What is a 3-tier architecture?
Three separated layers: **presentation** (frontend/web tier, public-facing), **application** (business logic/API tier, private), and **data** (database tier, most restricted, usually private subnet with no direct internet access). Each tier scales and is secured independently.

### 8. Which components/resources are required to build a 3-tier architecture using Terraform?
VPC with public and private subnets across AZs, an Internet Gateway (public tier) and NAT Gateway (private tier outbound access), an ALB in the public subnet routing to app-tier EC2/ASG or EKS in private subnets, security groups per tier, and RDS in the most restricted private subnet with its own security group allowing access only from the app tier.
**Follow-up:** *"How would you secure traffic between tiers?"* → Security groups referencing each other (e.g. DB SG only allows inbound from App SG, not from a CIDR range) rather than open IP ranges.

### 9. If RDS is in a private subnet, how do you access it securely without a public tool like MySQL Workbench?
Use an SSH bastion host / jump box in the public subnet with port-forwarding (`ssh -L 3306:rds-endpoint:3306`), or use AWS Systems Manager Session Manager port forwarding (no bastion, no open SSH port needed) to tunnel into the private subnet and connect locally.
**Follow-up:** *"Which do you prefer and why?"* → SSM Session Manager — no inbound ports to manage, no bastion host to patch/secure, and access is IAM-controlled and logged in CloudTrail.

### 10. Explain your end-to-end CI/CD pipeline in your current project.
GitHub push triggers the pipeline → Trivy filesystem scan → SonarQube code quality/vulnerability scan → build the Docker image → Trivy image scan → push to ECR/Docker Hub → ArgoCD detects the new image/manifest change and syncs it to the EKS cluster via GitOps.

### 11. Explain a simple CI/CD pipeline in short.
Code push → build → test → package (Docker image) → deploy. CI covers build/test/package (catching issues early), CD covers getting that artifact automatically into an environment, whether that's continuous delivery (manual approval gate) or continuous deployment (fully automatic).

### 12. Show a sample Jenkins CI/CD pipeline code.
```groovy
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps { git branch: 'main', url: 'https://github.com/org/repo.git' }
        }
        stage('Build') {
            steps { sh 'docker build -t myapp:${BUILD_NUMBER} .' }
        }
        stage('Scan') {
            steps { sh 'trivy image myapp:${BUILD_NUMBER}' }
        }
        stage('Push') {
            steps { sh 'docker push myrepo/myapp:${BUILD_NUMBER}' }
        }
        stage('Deploy') {
            steps { sh 'kubectl set image deployment/myapp myapp=myrepo/myapp:${BUILD_NUMBER}' }
        }
    }
}
```
**Follow-up:** *"How do you store credentials in Jenkins?"* → Jenkins Credentials Store, referenced in the pipeline via `withCredentials`/credential IDs — never hardcoded in the Jenkinsfile.

### 13. Will a standalone Jenkins server setup work, and what should you consider?
Yes, it works for small setups, but consider: single point of failure (no HA), limited scaling since all builds run on one machine, security (patching Jenkins itself, plugin vulnerabilities), and backup of the Jenkins home directory/config. For production scale, I'd move to a controller + multiple agent nodes (static or dynamic/Kubernetes agents) instead.

### 14. Explain what an application pipeline is.
The full automated path an application takes from code commit to running in production — build, test, security scan, package, deploy, and often post-deploy verification — with each stage gating the next so only validated code moves forward.

### 15. How many ways can you trigger a Jenkins pipeline?
Several: **SCM webhook** (push/PR triggers build), **polling SCM** (Jenkins checks for changes on a schedule), **scheduled/cron** builds, **manual trigger** (Build Now), **upstream/downstream job triggers** (one pipeline triggers another), and **API trigger** (via Jenkins REST API/CLI).

### 16. Explain components in 3-tier architecture
*(Same as Q7 — presentation/app/data tiers.)* If asked again in the same interview, add the AWS mapping: presentation = ALB + frontend (S3/CloudFront or EC2/EKS pods), application = backend API on EC2/EKS in private subnet, data = RDS/database in the most restricted private subnet.

### 17. Explain Kubernetes architecture
Control plane (API server, scheduler, controller manager, etcd) manages cluster state and scheduling decisions; worker nodes run the actual workloads via kubelet (talks to API server, manages pods) and kube-proxy (handles networking/service routing), with the container runtime executing containers inside pods.
**Follow-up:** *"What does etcd store?"* → The entire cluster state — all objects, configs, and secrets — as a key-value store; it's the source of truth the API server reads/writes to.

### 18. How does a private subnet connect with the outside world?
Via a NAT Gateway placed in a public subnet — instances in the private subnet route outbound traffic (e.g. package updates, API calls) through the NAT Gateway, which has a public IP, so they get outbound internet access without being directly reachable from the internet.

### 19. What is the difference between NACL and Security Groups?
Security Groups are **stateful** and operate at the instance/ENI level — allow rules only (return traffic is automatically allowed). NACLs are **stateless** and operate at the subnet level — support both allow and deny rules, and you must explicitly allow return traffic too.

### 20. What is the purpose of a NAT Gateway?
Lets resources in a private subnet initiate outbound internet traffic (updates, external API calls) while blocking any inbound connections initiated from the internet — private resources stay unreachable from outside, but can still reach out.

### 21. Explain how to write a Dockerfile.
Start with a base image (`FROM`), set a working directory (`WORKDIR`), copy dependency files and install them first for layer caching (`COPY package.json`, `RUN npm install`), then copy the rest of the source (`COPY . .`), expose the port (`EXPOSE`), and define the startup command (`CMD` or `ENTRYPOINT`). Use multi-stage builds to keep the final image small.
**Follow-up:** *"Why use multi-stage builds?"* → Build dependencies/tools stay in the build stage; only the compiled artifact gets copied into a slim final image, cutting image size and attack surface.

### 22. From where is the image pulled when you use `docker pull image`?
By default, from Docker Hub (`docker.io`) unless the image name includes a different registry prefix (e.g. `myregistry.azurecr.io/image` or an ECR URL) — Docker resolves the registry from the image name itself.

### 23. How is the image pulled from a private repository?
Authenticate first with `docker login <registry>` (or for ECR, `aws ecr get-login-password | docker login`), which stores credentials locally; then `docker pull` uses those stored credentials to authorize the pull. In Kubernetes, this is done via an `imagePullSecret` referenced in the pod spec.

### 24. What is Ingress in Kubernetes?
An API object that defines HTTP/HTTPS routing rules (host/path → backend service) into the cluster from outside. It needs an Ingress Controller (like ALB Controller or NGINX) running in the cluster to actually read those rules and configure the real load balancer/proxy.

### 25. Explain CI/CD pipeline and its stages
**CI:** code checkout → build → unit tests → static/security scan (SonarQube, Trivy) → package as artifact/image.
**CD:** push artifact to registry → deploy to target environment (dev/UAT/prod) → smoke/integration tests → (optional) manual approval gate for prod → rollback capability if it fails.
