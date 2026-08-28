# DevOps Interview Prep — Aspire & Belcan

---

## ASPIRE (3-4 YOE round)

### 1. Difference between ReplicaSet and DaemonSet?
A ReplicaSet ensures a specified *number* of identical pod replicas are running, scheduled wherever the scheduler decides. A DaemonSet ensures exactly *one* copy of a pod runs on every (or selected) node — used for node-level agents like log collectors, monitoring agents, or CNI plugins.

### 2. Difference between PV and PVC in Kubernetes?
A PersistentVolume (PV) is the actual storage resource in the cluster (provisioned by admin or dynamically via StorageClass). A PersistentVolumeClaim (PVC) is a pod's *request* for storage — Kubernetes binds a PVC to a matching PV. PV = supply, PVC = demand.

### 3. Difference between git pull and git fetch?
`git fetch` downloads commits/refs from the remote but doesn't touch your working branch. `git pull` does a fetch *and* immediately merges (or rebases) those changes into your current branch — it's fetch + merge in one step.

### 4. What is git stash and git stash pop?
`git stash` temporarily saves uncommitted changes (staged + unstaged) and reverts your working directory to clean, useful for switching branches without committing half-done work. `git stash pop` reapplies the most recent stash and removes it from the stash list.

### 5. Difference between NACL and Security Groups?
Security Groups are **stateful** and operate at the instance/ENI level — allow rules only (return traffic auto-allowed). NACLs are **stateless** and operate at the subnet level — support both allow and deny rules, and you must explicitly allow return traffic.

### 6. What is `terraform fmt` used for?
It auto-formats `.tf` files to Terraform's canonical style (indentation, alignment) — keeps code consistent across a team, doesn't change logic.

### 7. What is `terraform import` used for?
It brings an existing, manually-created cloud resource under Terraform management by mapping it to a resource block in your state file — without recreating the resource. Useful for adopting IaC on infra that already exists.

### 8. What is a Provisioner vs a Provider in Terraform?
A **Provider** is the plugin that lets Terraform talk to a platform's API (AWS, Azure, GCP) to create/manage resources. A **Provisioner** runs scripts or commands on a resource after creation/destruction (e.g. `remote-exec`, `local-exec`) — used sparingly, mostly for bootstrapping.

### 9. What is CRR in S3?
Cross-Region Replication — automatically replicates objects from a source bucket to a destination bucket in a different AWS region, for disaster recovery, compliance, or latency reduction.

### 10. In which cases do 503 errors occur in DevOps context?
Common causes: backend/target instances failing health checks (ALB has no healthy targets), service overloaded/out of capacity, pod crashlooping so no ready endpoints behind the K8s Service, or a deployment rolling out with insufficient ready replicas. First thing I check: target group health in ALB or pod readiness in the cluster.

### 11. Different types of triggers in AWS Lambda?
Common ones: API Gateway (HTTP requests), S3 events (object created/deleted), CloudWatch Events/EventBridge (scheduled/cron or event-based), SQS/SNS (queue/topic messages), DynamoDB Streams, and direct invocation via SDK/CLI.

### 12. NAT Gateway vs NAT Instance?
NAT Gateway is a fully managed AWS service — highly available (per-AZ), auto-scaled, no patching, but costs more. NAT Instance is a self-managed EC2 instance running NAT software — cheaper, but you manage patching, scaling, and it's a single point of failure unless you build HA yourself.

### 13. How to find and remove orphan resources in Kubernetes?
Look for resources with no owner references or unused by any workload — e.g. PVs stuck in "Released" state, ConfigMaps/Secrets not mounted anywhere, unused Services/Ingresses. I'd use `kubectl get <resource> -A` combined with `kubectl describe` to check references, or tools like `kube-resource-report`/`popeye` to automate detection, then delete after confirming nothing depends on them.

### 14. What is Sticky Session in ALB?
Also called session affinity — ALB uses a cookie to route all requests from the same client to the *same* backend target for the duration of a session, instead of load-balancing each request independently. Useful when an app stores session state locally on the instance rather than in a shared store like Redis.

---

## BELCAN (9 YOE round)

### 1. Write your Jenkins pipeline
```groovy
pipeline {
    agent any
    environment {
        DOCKER_REGISTRY = 'myregistry.io'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }
    stages {
        stage('Checkout') {
            steps { git branch: 'main', url: 'https://github.com/org/repo.git' }
        }
        stage('Build & Test') {
            steps { sh 'mvn clean package' }
        }
        stage('Docker Build & Push') {
            steps {
                sh "docker build -t $DOCKER_REGISTRY/app:$IMAGE_TAG ."
                sh "docker push $DOCKER_REGISTRY/app:$IMAGE_TAG"
            }
        }
        stage('Deploy') {
            steps { sh "kubectl set image deployment/app app=$DOCKER_REGISTRY/app:$IMAGE_TAG" }
        }
    }
    post {
        success { echo 'Pipeline succeeded' }
        failure { echo 'Pipeline failed' }
        always { cleanWs() }
    }
}
```
Say out loud: "Declarative pipeline — agent, environment variables, then stages for checkout/build/test/dockerize/deploy, with a post block for cleanup and notifications."

### 2. Purpose of agent, post, and environment blocks?
`agent` defines *where* the pipeline/stage runs (any node, specific label, or a container). `environment` sets variables/credentials available throughout the pipeline or a stage. `post` defines actions to run after stages complete, based on outcome — `success`, `failure`, `always`, `unstable` — typically used for notifications, cleanup, or archiving artifacts.

### 3. How do you fully back up Jenkins (jobs, config, auth)?
Back up the `$JENKINS_HOME` directory entirely — it contains job configs (`jobs/`), global config (`config.xml`), plugins, credentials store, and user/auth data. In practice: automate periodic tar/zip of `$JENKINS_HOME` to S3, or use the ThinBackup / Jenkins Configuration as Code (JCasC) plugin for structured, versionable backups.

### 4. What are the ways to trigger a Jenkins pipeline?
Manual (Build Now), SCM polling (`pollSCM`), webhooks from GitHub/GitLab on push/PR, scheduled/cron (`triggers { cron() }`), upstream/downstream job triggers, and via remote API trigger (curl with a token).

### 5. Give 5 Jenkins jobs view-only access to other users — how?
Enable Role-Based Access Control via the **Role-based Authorization Strategy** plugin, create a role scoped to those 5 jobs (by name pattern/regex) with only `Read`/`View` permissions, then assign that role to the relevant users/group — no build, configure, or delete rights.

### 6. How many types of Load Balancers in AWS, and what do they do?
Three: **Application Load Balancer (ALB)** — Layer 7, HTTP/HTTPS, path/host-based routing. **Network Load Balancer (NLB)** — Layer 4, ultra-high performance/low latency, handles TCP/UDP, static IP support. **Gateway Load Balancer (GWLB)** — Layer 3, used to deploy/scale third-party virtual appliances (firewalls, IDS/IPS) transparently in front of traffic.

### 7. Difference between Elastic IP and Public IP in AWS?
A Public IP is auto-assigned when an instance launches (in a public subnet) and is **released** when the instance stops/terminates. An Elastic IP is a **static** IP you allocate and own — it stays reserved to your account and can be re-attached to another instance, so it survives stop/start.

### 8. Daily-use Git commands and what they do?
`git status` (check working tree state), `git add .` (stage changes), `git commit -m "msg"` (commit staged changes), `git pull` (fetch + merge from remote), `git push` (push local commits to remote), `git branch`/`git checkout -b` (list/create branches), `git log --oneline` (view history), `git diff` (see unstaged changes), `git merge`/`git rebase` (integrate branches), `git stash` (shelve changes temporarily).

### 9. You have a local repo, changed one file, need to push to remote — what commands?
```
git status
git add <file>
git commit -m "description of change"
git pull --rebase origin main   # sync with remote first, avoid conflicts
git push origin main
```

### 10. Brief me about Git Stash
`git stash` saves your uncommitted changes (tracked, modified files — staged and unstaged) onto a stack and reverts the working directory to match HEAD, so you can switch branches or pull cleanly. `git stash list` shows saved stashes, `git stash pop` reapplies the latest and removes it from the stack, `git stash apply` reapplies without removing it — useful if you want to apply the same stash to multiple branches.

### 11. What is the Terraform state file?
`terraform.tfstate` is a JSON file that maps your Terraform configuration to real-world resource IDs — it's how Terraform knows what already exists, detects drift, and computes what needs to change on the next apply. In team settings, it should be stored remotely (e.g. S3 + DynamoDB for locking) rather than locally, to avoid conflicts and enable collaboration.

### 12. A few Terraform commands and what they do?
`terraform init` — initializes the working directory, downloads providers/modules. `terraform plan` — shows what changes will be made without applying them. `terraform apply` — applies the changes to reach the desired state. `terraform destroy` — tears down managed infrastructure. `terraform validate` — checks syntax/config validity. `terraform state list` — lists resources tracked in state.
