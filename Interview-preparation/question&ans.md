1. Tell me about yourself. 

Ans: "I'm a DevOps engineer with about 5-6 years of experience, currently at Navigator Software in Kolkata. I work across AWS and Azure — Kubernetes, CI/CD, Terraform. I migrated 15+ microservices to EKS with zero downtime, we're running at 99.95% uptime, and I cut deployment failures by 60% and deployment time by 35% by rebuilding our CI/CD with Jenkins, GitHub Actions, and ArgoCD. I also worked on NavAI, our in-house AI project, handling the deployment side. I'm AWS Certified Solutions Architect and CKA certified, and I care a lot about cost — I saved us $136K a year through Reserved Instances and Savings Plans." 

2. Tell me your day-to-day activity. 

Ans: "Mornings start with checking Grafana and CloudWatch for anything that fired overnight. Then it's a mix of reviewing Terraform/Helm PRs, working on whatever pipeline or infra ticket is active, troubleshooting Kubernetes issues if something's off, and running security scans through Trivy and SonarQube as part of CI. Once a week I do a client call to walk through infra status. Roughly it's 40% building/improving infra, 30% troubleshooting, 20% security, and the rest mentoring." 


3. How many projects have you deployed to production? 

Ans: "Around 15-20+ across my roles — the 15+ microservices migration to EKS is the biggest chunk at my current job, plus 10+ applications each at my previous two roles." 

4. What stacks and languages have you used to deploy applications? 

Ans: "Mostly Docker and Kubernetes on EKS and AKS. I've deployed Python and Java-based microservices, and a React application. For scripting it's Python and Bash, some PowerShell and Groovy for Jenkins. IaC is all Terraform and CloudFormation." 

5. Have you worked with stacks beyond .NET, Angular, Python — like React or AI apps? 


Ans: "Yes — I've deployed a React application, and I worked on NavAI, our internal AI project at Navigator. From an infra side, both come down to the same fundamentals: containerize, put it behind CI/CD, monitor it — the app layer changes but the deployment discipline doesn't." 

6. What was your role in deploying the AI project?
Ans: "On NavAI, I handled the deployment and infrastructure side — containerizing the service, setting up the CI/CD pipeline, and making sure it ran reliably in production with proper monitoring in place, the same way I do for our other microservices."

7. Have you deployed custom applications outside those stacks, like PHP?
Ans: "No, I haven't worked on a PHP application specifically. Most of my deployment work has been on containerized microservices and a React app. I'd approach PHP the same way — containerize it and put it behind the same pipeline — but I don't have hands-on PHP experience yet."

8. How would you handle multiple PHP apps needing different PHP versions on the same EC2 instance?
Ans: "I'd isolate each app so the PHP versions don't clash. My default would be to containerize each app — one Docker image per app pinned to its own PHP version, running side by side on the instance. If containers weren't an option, I'd use PHP-FPM with separate pools, each pointing to a different PHP version, and route traffic to the right pool through Nginx server blocks. Since everything else I run is container-first, that's the direction I'd lean."

9. Have you configured auto scaling and load balancers?
Ans: "Yes — Kubernetes HPA on EKS and AKS based on CPU/memory, and AWS Application Load Balancers and ELBs for services on EC2 and EKS, including target group health checks and routing."

10. What is stickiness in a load balancer?
Ans: "It means the load balancer keeps sending a client's requests to the same backend server for the length of a session, usually via a cookie. It matters when an app stores session data locally on the server instead of a shared store like Redis."

11. What is round-robin load balancing?
Ans: "It's an algorithm that distributes requests evenly and sequentially across all backend servers — one after another, then back to the start. Simple, and works well when all servers have similar capacity."

12. Have you configured CloudFront?
Ans: "Yes — setting up distributions in front of S3 or ALB origins, configuring cache behaviors and TTLs, attaching ACM certificates for HTTPS, and using origin access control to keep S3 locked down so it's only reachable through CloudFront."


13. Introduce yourself and describe your current DevOps responsibilities.
Ans: "I'm Subrata, a DevOps Engineer at Navigator Software with about 5-6 years of experience. My core responsibilities right now are managing our Kubernetes clusters on EKS and AKS, building and maintaining CI/CD pipelines with Jenkins, GitHub Actions, and ArgoCD, writing and maintaining our Terraform infrastructure, and owning observability through Prometheus, Grafana, and CloudWatch. I also handle security integration in the pipeline — Trivy and SonarQube scans — and mentor two junior engineers on Kubernetes and Terraform."

14. Where's your current office, and are you willing to relocate to Bangalore?
Ans: "I'm currently based in Kolkata, working on-site at Navigator Software." Whether you're open to relocating is genuinely your call — tell me and I'll give you the exact line to say, but a safe honest default is: "Yes, I'm open to relocating to Bangalore for the right opportunity."

15. Have you created production infrastructure using Terraform?
Ans: "Yes — I use Terraform to provision and manage our EKS and AKS clusters, along with supporting resources like VPCs, IAM roles, RDS, and networking, across dev, UAT, and production."

16. How is your Terraform repo structured across dev, UAT, and production?
Ans: "We use separate directories per environment — dev/, uat/, prod/ — each with its own backend config and .tfvars file, but they all pull from a shared modules/ directory so the actual resource logic stays consistent across environments and we're not duplicating code."

17. How are Terraform deployments executed — pipeline or manual?
Ans: "Through a pipeline. terraform plan runs automatically on a PR, someone reviews the plan output, and apply runs after approval — for prod specifically we have a manual approval gate before apply runs, dev and UAT are more automated."

18. What files are in the Terraform dev folder?
Ans: "Typically main.tf, variables.tf, outputs.tf, provider.tf, backend.tf for remote state config, and a dev.tfvars file with environment-specific values."

19. Roughly how many AWS resources have you created with Terraform in dev?
Ans: This one only you know exactly — but a reasonable ballpark to say is something like "in the range of 50-100+ resources, covering EKS, VPC, IAM, security groups, RDS, and S3." Adjust to your real number if you have it.

20. One Terraform file or multiple?
Ans: "Multiple, split by resource type or service — networking, compute, IAM, database — rather than one big file. Keeps it easier to review and reduces merge conflicts."

21. Do you use Terraform modules?
Ans: "Yes, for anything reusable — VPC, EKS, IAM roles, RDS — so we're not rewriting the same resource blocks across environments."

22. What does an EC2 Terraform module contain?
Ans: "The instance resource itself, a security group resource, an IAM role and instance profile, key pair reference, user data script for bootstrapping, and then variables and outputs so the module can be reused with different instance types, AMIs, or subnets."

23. Custom modules or public ones?
Ans: "A mix — for core infra like EKS and VPC we mostly write custom modules so they match our exact standards and tagging conventions, but for simpler, well-solved things we'll sometimes reference the public Terraform Registry modules to save time."

24. Do you create UAT resources directly with resource blocks rather than modules?
Ans: "For most things we use modules, but for one-off or UAT-specific resources — something that doesn't need to be reused elsewhere — we'll just write a direct resource block instead of building a whole module for it."

25. How does Trivy scan images and find vulnerabilities?
Ans: "Trivy scans the image layers and inspects installed OS packages and application dependencies, then checks them against known CVE databases. It flags vulnerabilities with severity ratings — critical, high, medium, low — and we gate our pipeline so builds with critical/high findings fail before they reach production."

26. Have you used ArgoCD to deploy to EKS?
Ans: "Yes, ArgoCD is our GitOps deployment tool for EKS — it watches our manifest repo and syncs the cluster state to match what's defined in Git."

27. How do you update the image tag in the ArgoCD repo?
Ans: "The CI pipeline builds and pushes the image, then updates the image tag in the corresponding values.yaml or Kustomize overlay in the GitOps repo — usually via a pipeline step that commits the change. ArgoCD then picks up that Git change and syncs it to the cluster automatically."

28. Is ArgoCD deployed inside the EKS cluster?
Ans: "Yes, it runs as a workload inside the cluster itself, in its own argocd namespace."

29. How do you create ArgoCD Application Projects?
Ans: "Through a YAML manifest defining the AppProject — source repos it's allowed to pull from, destination clusters/namespaces, and RBAC roles for who can sync or manage apps within that project."


30. Is an ArgoCD Application defined in YAML or created via CLI?
Ans: "YAML — we keep it declarative and stored in Git so it's version-controlled and consistent with our GitOps approach, even though the CLI and UI can also create one."

31. Are you familiar with the App-of-Apps pattern?
Ans: "Yes — it's a parent ArgoCD Application whose only job is to manage a set of child Application manifests. It's useful for bootstrapping an entire environment or a group of related apps in one sync instead of managing each one individually."

32. How many ArgoCD applications are in dev?
Ans: "We're running somewhere around 10-15 ArgoCD applications in dev, roughly mapping to our microservices."

33. Which Kubernetes manifests and objects have you worked with?
Ans: "Deployments, Services, Ingress, ConfigMaps, Secrets, StatefulSets, HPA, PersistentVolumes and Claims, Namespaces, and RBAC objects like Roles and RoleBindings."

34. How do Helm charts work in Kubernetes?
Ans: "A Helm chart packages a set of Kubernetes manifests as templates, with a values.yaml file supplying the configurable parameters. helm install or helm upgrade renders those templates with the given values and applies them to the cluster, and Helm tracks each install as a release so you can roll back to a previous version if something breaks."

35. How does Kubernetes Ingress route traffic?
Ans: "An Ingress resource defines routing rules — which host or path maps to which backend Service. An Ingress controller, like the AWS Load Balancer Controller or NGINX, watches for these Ingress resources and actually implements the routing, provisioning a load balancer and configuring it to match those rules."

36. How does the AWS Load Balancer Controller work?
Ans: "It runs as a controller inside the cluster, watching Ingress and Service resources that are annotated for it. When it sees one, it automatically provisions and configures the actual AWS ALB or NLB, sets up target groups, and keeps them in sync with pod endpoints as they scale up or down."

37. How did you configure HTTPS for an ALB?
Ans: "I attached an ACM certificate to the HTTPS listener on port 443, set up a redirect rule from port 80 to 443 so all traffic gets forced to HTTPS, and picked a security policy that enforces modern TLS versions."

38. What's the traffic flow for the current application?
Ans: This depends on your actual setup — a typical flow to describe: "Client request hits Route53, goes to CloudFront if we're using it, then to the ALB, which routes based on Ingress rules through the AWS Load Balancer Controller to the target pods in EKS." Confirm this matches what you actually run.

39. Is AWS WAF included in the traffic flow?
Ans: "Yes, we attach WAF to the ALB (or CloudFront) with managed rule sets for common exploits — SQL injection, XSS — plus rate-based rules to throttle abusive traffic before it reaches the app." Only say this if it's true for your setup — if you're not using WAF, it's fine to say so and mention it's something you'd recommend adding.

40. How is authentication managed?
Ans: "For AWS access from within the cluster, we use IRSA — IAM Roles for Service Accounts — so pods get scoped AWS permissions without static credentials. Application-level auth is handled separately through the app's own OAuth/JWT flow, and secrets like DB credentials or API keys are pulled from AWS Secrets Manager or Parameter Store rather than hardcoded."

41. What Kubernetes security hardening have you applied?
Ans: "RBAC with least-privilege access, network policies to restrict pod-to-pod traffic, running containers as non-root with Pod Security Standards enforced, setting resource requests/limits to prevent noisy-neighbor issues, disabling auto-mounted service account tokens where not needed, and gating deployments on image vulnerability scans before they reach the cluster."

42. What Dockerfile security hardening have you implemented?
Ans: "Using minimal base images — Alpine or distroless where possible — multi-stage builds so build tools don't ship in the final image, pinning specific versions instead of latest, running as a non-root user, not baking in any secrets, and stripping out unnecessary packages to shrink the attack surface."

43. How do you run a Docker container as a non-root user?
Ans: "In the Dockerfile, I create a dedicated user and group with RUN groupadd -r appgroup && useradd -r -g appgroup appuser, make sure the app's files are owned by that user, and then set USER appuser before the container's entrypoint runs — so the process never runs as root."

