# DevOps Interview — Prep Answers, Set 2

---

## UST (3-5 yrs)

### 1. Something exists on the cloud but isn't in Terraform — how do you bring it in?
Use `terraform import` to bring the existing resource under Terraform's state, then write the matching resource block in code so `terraform plan` shows no diff. For many resources at once, tools like `terraformer` can generate the HCL automatically, which I'd then review and clean up.
**Follow-up: What if the imported resource's config doesn't match what you write in HCL?**
`terraform plan` will show a diff — I'd adjust the HCL to match actual reality first (avoid drift-fixing on the first apply), then make further changes afterward.

### 2. `terraform apply` is recreating all resources — what's the likely cause?
Usually one of: (1) state file is missing/corrupted/pointing to the wrong backend, so Terraform thinks nothing exists yet, (2) a resource identifier or key attribute changed forcing replacement, or (3) someone ran `terraform apply` from a different state/workspace than the one actually deployed. First thing I'd check is `terraform state list` against what's really running.
**Follow-up: How do you prevent this in a team setting?**
Remote state (S3 + DynamoDB lock, or Terraform Cloud) so everyone shares one state file and can't apply concurrently or from stale local state.

### 3. How can AI assist in cloud infrastructure monitoring?
AI/ML can do anomaly detection on metrics (catching unusual patterns before static thresholds trigger), predictive alerting for capacity issues, log correlation to speed up root-cause analysis, and auto-summarizing incidents. AWS DevOps Guru or CloudWatch anomaly detection are direct examples I'd point to.

### 4. How can AI assist developers in increasing productivity?
Code completion and boilerplate generation (Copilot-style), auto-generating tests, explaining unfamiliar code/errors quickly, and generating IaC or CI/CD YAML from a plain description — reduces time spent on repetitive writing so developers focus on logic and design.

### 5. A Python program is failing due to memory issues — what could cause it?
Common causes: loading a large dataset entirely into memory instead of streaming/chunking, a memory leak from objects not being released (growing lists/caches, unclosed file handles), recursive calls without proper base cases, or an undersized container/pod memory limit for the workload.
**Follow-up: How would you debug it?**
Use `tracemalloc` or a memory profiler (`memory_profiler`) to find what's growing, check container memory limits vs actual usage in Grafana/CloudWatch, and check for OOMKilled events if it's running in Kubernetes.

### 6. A CI pipeline takes 45 minutes — how do you optimize it?
Parallelize independent stages (tests, lint, scans) instead of running sequentially, cache dependencies (npm/pip/Docker layers) between runs, use a smaller/faster base image, skip unnecessary re-builds with path-based triggers, and only run the full suite on merge to main (lighter checks on PR).
**Follow-up: Which change would you try first?**
Dependency/Docker layer caching — usually the single biggest win for the least effort.

### 7. Terraform code — EC2 instance with `instance_type` and `region` variables
```hcl
variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0" # example AMI, region-specific
  instance_type = var.instance_type

  tags = {
    Name = "app-server"
  }
}
```

### 8. Need to create 50 instances in one go — how in Terraform?
Use `count` or `for_each` on the resource block:
```hcl
resource "aws_instance" "app_server" {
  count         = 50
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = var.instance_type

  tags = {
    Name = "app-server-${count.index}"
  }
}
```
`for_each` over a map/set is preferable when instances need distinct, named configs (avoids reordering issues that `count` can cause).

### 9. Someone deleted the Terraform state file locally — what now?
If using remote state (S3), nothing lost — local deletion doesn't affect it. If it was truly local-only and lost: check for a `.tfstate.backup` file first; if that's gone too, either re-import every resource with `terraform import`, or restore an older version if using a versioned S3 bucket. This is exactly why remote state with versioning is standard practice.

### 10. A production instance is failing — possible causes?
Resource exhaustion (CPU/memory/disk), a bad deployment/config change, dependency failure (DB, external API down), network/security group misconfiguration, underlying AWS hardware/AZ issue, or an unhandled application exception under load. I'd check CloudWatch/Grafana metrics, recent deploys, and logs, in that order.

### 11. Disaster recovery — users can't access the application. What do you do?
First confirm scope (one AZ, one region, or full outage) via health checks and monitoring. If it's regional, fail over to the DR region/standby per the documented runbook (DNS failover via Route 53, promote standby RDS, etc.). Communicate status to stakeholders immediately, then do root-cause analysis after service is restored, not during.
**Follow-up: What's the difference between RTO and RPO, and how do they affect your DR design?**
RTO (Recovery Time Objective) is how fast you must be back up; RPO (Recovery Point Objective) is how much data loss is acceptable. Lower RTO/RPO needs pilot-light or hot-standby DR (expensive); higher tolerance allows backup-and-restore (cheaper, slower).

### 12. Sudden traffic spike — how do you troubleshoot?
Check if auto-scaling is keeping up (HPA/ASG metrics), check if it's legitimate traffic vs a bot/DDoS pattern, check downstream dependencies (DB connections, rate limits) for bottlenecks, and check error rates/latency in Grafana. Scale out immediately if legitimate; rate-limit or block at WAF/CloudFront if malicious.

### 13. Credentials are visible in CI/CD pipeline logs — what do you do?
Immediately rotate/revoke the exposed credential — assume it's compromised the moment it's visible, don't just remove it from logs. Then scrub the logs (or restrict access), fix the pipeline to use masked secrets/environment variables properly (never `echo` a secret), and add a secrets-scanning step (like `trufflehog`) going forward.

### 14. Explain Blue-Green deployment.
Two identical production environments — Blue (current live) and Green (new version). Traffic is routed to Blue while Green is deployed and tested; once verified, the router/load balancer switches all traffic to Green instantly. Blue stays idle as an instant rollback target if something goes wrong.

---

## Turing (Cloud Engineer)

### 1. DB failover happens (connection switches A→B) while a user is writing data — how do you manage that?
The write in-flight during failover will typically fail or time out — the application needs retry logic with idempotency (so a retried write doesn't duplicate data) and should surface a "please retry" state rather than silently losing the write. Using a failover-aware connection pool/driver (e.g. RDS Proxy) reduces the window where this happens.
**Follow-up: How does RDS Proxy help here specifically?**
It maintains the connection pool and handles failover transparently, cutting failover time from ~60-120 seconds (native) down to seconds, reducing how many in-flight requests are actually affected.

### 2. Lambda cold start — what causes it and how do you reduce it?
Cold start happens when Lambda spins up a new execution environment (no warm instance available) — init time depends on runtime, package size, and VPC attachment (ENI creation is a big contributor). Reduce it by keeping deployment packages small, using Provisioned Concurrency for latency-sensitive functions, avoiding VPC unless required, and choosing faster-cold-start runtimes.

### 3. AWS CDK commands you've used
`cdk init` (scaffold a project), `cdk synth` (generate CloudFormation template from code), `cdk diff` (show changes vs deployed stack), `cdk deploy` (deploy the stack), `cdk destroy` (tear it down).
*(Be honest about depth here — if it isn't deep experience, say "I know the core workflow; haven't run it in a large production setup.")*

### 4. How do you implement Terraform in a CD pipeline?
Pipeline stages: `terraform fmt` + `validate` → `terraform plan` (output saved as an artifact) → manual approval gate for prod → `terraform apply` using the approved plan file. State stored remotely (S3 + DynamoDB lock) so the pipeline runner and any human are working against the same state.
**Follow-up: Why save the plan as an artifact instead of re-running plan before apply?**
Ensures what gets approved is exactly what gets applied — re-running plan risks drift between approval and execution.

### 5. 10 developers committing to Git — how do you remove developer 10's specific check-in?
If not yet widely pulled: `git revert <commit-hash>` is safest (creates a new commit undoing the changes, preserves history, no force-push needed). If it must be fully erased from history (rare, riskier): interactive rebase to drop the commit — only viable if nobody else has already pulled that history.
**Follow-up: Why prefer revert over rebase/force-push in a shared branch?**
Revert doesn't rewrite history, so it's safe on a branch others are actively pulling from; force-pushing rewritten history can cause conflicts and lost work for the whole team.

### 6. Someone manually changed EC2 config that was created via Terraform — how do you fix it?
Run `terraform plan` — it shows the drift as a diff. Then either `terraform apply` to force it back to the code-defined state (if the manual change was unwanted), or update the Terraform code to match the new desired state and apply (if the manual change should be kept). Never leave it unreconciled, since the next apply could revert it unexpectedly.

### 7. Payment gateway app in Lambda intermittently fails connecting to an external API — how do you cross-check and fix it, without breaking payments?
Check CloudWatch Logs/X-Ray traces for the failure pattern (timeout vs connection refused vs DNS issue) and correlate with the provider's status page. Add retry logic with exponential backoff and a circuit breaker for transient failures, with a sane timeout so Lambda doesn't hang. Since it's payments — ensure retries are idempotent (idempotency key) so a retried request can't double-charge.
**Follow-up: How do you make sure a retried payment request isn't processed twice?**
Pass an idempotency key (unique per transaction) to the payment provider — most gateways (Stripe, etc.) support this natively and return the original result instead of reprocessing.

### 8. Purpose of Blue-Green deployment, and how do you switch back?
Purpose: zero-downtime releases with an instant rollback path — the new version (Green) is fully tested before it takes real traffic. To switch back, redirect the load balancer/router back to Blue (left running unchanged) — no redeploy needed, so rollback is near-instant.

### 9. Script to check if an external API is reachable before starting a request
```bash
#!/bin/bash
API_URL="https://api.example.com/health"
TIMEOUT=5

if curl -sf --max-time "$TIMEOUT" -o /dev/null "$API_URL"; then
  echo "API is reachable. Proceeding with request."
  # actual request logic here
else
  echo "API is NOT reachable. Aborting request."
  exit 1
fi
```
Python equivalent: `requests.get(url, timeout=5)` wrapped in try/except, with a retry decorator (e.g. `tenacity`) for the common production pattern.
