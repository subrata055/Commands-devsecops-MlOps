# Accenture + Akamai Interview — Prep Answers

Same format: 1-4 line spoken answer, then code/command where the question needs it, with output. For coding questions, walk through the logic out loud line-by-line — that's what they're actually scoring.

---

## Accenture

### 1. Python: monitor a directory and print names of new files added every minute
Poll the directory every 60 seconds, compare current filenames to the previous snapshot, and print anything new.

```python
import os
import time

def monitor_directory(path, interval=60):
    seen = set(os.listdir(path))
    while True:
        time.sleep(interval)
        current = set(os.listdir(path))
        new_files = current - seen
        if new_files:
            print(f"New files: {new_files}")
        seen = current

# monitor_directory("/path/to/watch")
```
**Say out loud:** "I keep a set of known filenames, sleep for the interval, take a new snapshot, and the set difference gives me anything added. For production I'd use the `watchdog` library instead of polling — it uses OS-level file system events so it's instant and lighter on CPU."

### 2. Set vs List in Python (follow-up to above)
- **List**: ordered, allows duplicates, indexable (`list[0]`), mutable.
- **Set**: unordered, no duplicates, not indexable, faster membership checks (`in`) — O(1) vs O(n) for a list.
- I used a `set` above specifically because I only care about "is this filename new" — fast lookup, and duplicates are meaningless here.

### 3. SQL: customers with more than 3 orders in the last 90 days
```sql
SELECT c.customer_name
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(o.order_id) > 3;
```
**Say out loud:** "Join Customers to Orders, filter to the last 90 days, group by customer, and use HAVING (not WHERE) since I'm filtering on an aggregate — count of orders."

### 4. Python: return job IDs where status is "FAILED"
```python
logs = [
    {"job_id": 101, "status": "SUCCESS", "timestamp": "2025-06-10T10:00:00"},
    {"job_id": 102, "status": "FAILED",  "timestamp": "2025-06-10T10:05:00"},
    {"job_id": 103, "status": "FAILED",  "timestamp": "2025-06-10T10:10:00"},
    {"job_id": 104, "status": "SUCCESS", "timestamp": "2025-06-10T10:15:00"},
]

def failed_job_ids(logs):
    return [log["job_id"] for log in logs if log["status"] == "FAILED"]

print(failed_job_ids(logs))
# Output: [102, 103]
```
**Say out loud:** "Simple list comprehension — filter the list of dicts where status equals FAILED, extract just the job_id."

### 5. What is CI/CD? (briefly)
CI (Continuous Integration) is automatically building and testing code every time it's pushed, so integration issues are caught early. CD (Continuous Delivery/Deployment) automatically ships that validated build to staging or production. Together they let teams release smaller changes, faster, with less manual risk.

### 6. Kubernetes architecture and components
**Control Plane** (the brain): API Server (front door for all requests), etcd (key-value store holding cluster state), Scheduler (decides which node a pod runs on), Controller Manager (reconciles desired vs actual state — e.g. restarts failed pods).
**Worker Node**: Kubelet (talks to API server, manages containers on that node), Kube-proxy (handles networking/service routing), Container Runtime (containerd/Docker — actually runs the containers).
**Say out loud:** "Control plane decides *what should happen*, worker nodes actually *run* it — kubelet on each node is the agent that makes reality match what the control plane wants."

---

## Akamai

### 7. IPv4 vs IPv6
IPv4 is 32-bit (e.g. `192.168.1.1`), ~4.3 billion addresses, exhausted globally. IPv6 is 128-bit (e.g. `2001:db8::1`), astronomically larger address space, built-in support for better security (IPSec) and no need for NAT.

### 8. IPv4 address starts from
`0.0.0.0` — the full valid range is `0.0.0.0` to `255.255.255.255`, though `0.0.0.0/8` and a few other blocks are reserved, not usable for hosts.

### 9. Script to validate an IPv4 address
```python
import socket

def is_valid_ipv4(ip):
    try:
        socket.inet_aton(ip)
        return ip.count('.') == 3
    except socket.error:
        return False

print(is_valid_ipv4("192.168.1.1"))  # True
print(is_valid_ipv4("999.1.1.1"))    # False
```
**Say out loud:** "I use `socket.inet_aton` to validate — I add the dot-count check because `inet_aton` alone loosely accepts malformed strings like '192.168.1'."

### 10. Unix command: find all files larger than 1 GB
```bash
find / -type f -size +1G
```
**Say out loud:** "`-type f` restricts to files, `-size +1G` means strictly greater than 1 gigabyte."

### 11. Unix command: find "ERROR" in a txt file, case-insensitive
```bash
grep -i "ERROR" file.txt
```
**Say out loud:** "`-i` makes it case-insensitive, so it matches ERROR, error, Error, etc."

### 12. Logging into a Linux machine for the first time — process
Get the IP/hostname and credentials (or SSH key) from the provisioning team, connect via `ssh user@host` (or `ssh -i key.pem user@host` for key-based), verify the host fingerprint prompt, then immediately change the default password and harden access (disable root login, set up key-based auth if not already).

### 13. Unable to access a Linux machine — what would you do
Check basics first: is it a network issue (`ping`, `telnet host 22`) or an auth issue? Then check security group/firewall rules allow port 22 from my IP, check the instance/service is actually running (via cloud console), check SSH service status if I have another access path (e.g. console/serial access), and check my key/credentials are correct.

### 14. `5/2` and `5//2` in Python
`5/2` → `2.5` (true division, always returns float). `5//2` → `2` (floor division, rounds down to nearest integer).

### 15. `a = [0]`, `b = {0}` — what do `a[0]` and `b[0]` return?
`a[0]` → `0` (lists are indexable). `b[0]` → **TypeError: 'set' object is not subscriptable** — `{0}` is a set (not a dict), and sets have no order or index, so they can't be indexed.

### 16. How to check firewall protection
On Linux: `sudo iptables -L -n` (or `ufw status` on Ubuntu with UFW). On cloud infra: check Security Groups (AWS) or NSGs (Azure) for allowed inbound/outbound rules. To test from outside: `nc -zv host port` or `telnet host port` to confirm a port is actually reachable.

### 17. OSI Model
7 layers, bottom to top: **Physical** (cables, signals) → **Data Link** (MAC addresses, switches) → **Network** (IP addressing, routing) → **Transport** (TCP/UDP, ports) → **Session** (connection management) → **Presentation** (encryption/encoding) → **Application** (HTTP, DNS — what the user interacts with).

### 18. Difference between Public and Private Hosted Zones (Route 53)
A **public hosted zone** manages DNS records resolvable from the public internet (e.g. your website's domain). A **private hosted zone** manages DNS only within one or more specified VPCs — used for internal service discovery that shouldn't be exposed externally.

### 19. How to create a Kustomize file
Create a `kustomization.yaml` in your manifests folder listing the base resources and any patches/overlays:
```yaml
resources:
  - deployment.yaml
  - service.yaml

patches:
  - path: patch-replica-count.yaml
```
Then apply with `kubectl apply -k .` — Kustomize overlays let you reuse the same base manifests across dev/UAT/prod with environment-specific patches, without templating.

### 20. Difference between CMD and ENTRYPOINT (Docker)
`ENTRYPOINT` defines the fixed command that always runs when the container starts. `CMD` provides default *arguments* to that command (or a default command if no ENTRYPOINT is set) — and `CMD` can be overridden at `docker run` time, while `ENTRYPOINT` normally can't (without `--entrypoint`). Common pattern: `ENTRYPOINT ["python", "app.py"]` with `CMD ["--debug"]` as the overridable default flag.
