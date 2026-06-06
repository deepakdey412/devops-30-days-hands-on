# Jenkins Job Stuck in Queue – Troubleshooting

## Quick Diagnosis Flow

```
Check queue reason (UI/logs) → check agents → check resources → fix → re-run job
```

---

## Common Causes & Fixes

**1. No Available Agents / Executors**

- Check: Jenkins UI → `Manage Jenkins` → `Nodes` → see executor count
- Log: `Waiting for next available executor`
- Fix: Add more agents, increase executor count, or free up busy agents

**2. Label Mismatch**

- Check: Job config → `Restrict where this project can be run` → verify label exists on an agent
- Log: `There are no nodes with the label 'xyz'`
- Fix: Correct the label in job config or add the label to an agent

**3. All Agents Offline**

- Check: Jenkins UI → `Manage Jenkins` → `Nodes` → agent status
- Log: `All nodes of label 'x' are offline`
- Fix: Restart offline agents or reconnect them

**4. Agent Disconnected / Not Responding**

- Check: Agent logs in Jenkins UI → `Manage Jenkins` → `Nodes` → click agent
- Fix: Restart the agent process or re-launch via SSH/JNLP

**5. Executor Count Set to Zero**

- Check: `Manage Jenkins` → `Nodes` → click agent → check `# of executors`
- Fix: Set executors to a value ≥ 1

**6. Build Throttle / Concurrency Limit**

- Check: Job config → `Throttle Concurrent Builds` plugin settings
- Fix: Increase max concurrent builds or remove throttle restriction

**7. Upstream Job Dependency (Build After)**

- Check: Job config → `Build Triggers` → upstream job status
- Log: `Waiting for upstream job to complete`
- Fix: Complete or abort the blocking upstream job

**8. Locked Shared Resource**

- Check: `Lockable Resources` plugin → check if resource is held by another build
- Fix: Release the locked resource or abort the holding build

**9. Waiting for Offline Node (Specific Node Assigned)**

- Check: Job is tied to a specific offline node
- Fix: Bring node online or change job config to `Any` agent

**10. Jenkins Master Overloaded**

- Check: `top` / `htop` on master → CPU/RAM at limit
- Fix: Reduce load, add agents, or upgrade master resources

---

## 8-Step Checklist

```bash
# 1. Check queue reason
Jenkins UI → Build Queue → hover over job → read reason

# 2. Check agent/node status
Manage Jenkins → Nodes → verify online + executors > 0

# 3. Check label match
Job Config → label == Agent label?

# 4. Check executor availability
Manage Jenkins → Nodes → # of executors in use vs total

# 5. Check lockable resources
Lockable Resources → any resource held?

# 6. Check upstream jobs
Job Config → Build Triggers → upstream job running/blocked?

# 7. Check throttle settings
Job Config → Throttle Concurrent Builds → limits set?

# 8. Check master load
top / htop → CPU and RAM on Jenkins master
```

---

> **Key Principle:** Always read the queue reason tooltip in Jenkins UI first — it directly tells you why the job is waiting.
