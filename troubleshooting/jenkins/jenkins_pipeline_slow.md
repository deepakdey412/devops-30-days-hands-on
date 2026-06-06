# Jenkins Pipeline Taking Longer Than Usual – Finding the Bottleneck

## Quick Diagnosis Flow
```
Check stage timings → check agent load → check logs → optimize slow stage
```

---

## Common Causes & Fixes

**1. Slow or Overloaded Agent**
- Check: `top` / `htop` on agent node → CPU/RAM/Disk
- Check: `Manage Jenkins` → `Nodes` → agent response time
- Fix: Scale agents, reduce concurrent builds, or upgrade agent hardware

**2. Large Workspace / Slow Checkout**
- Check: Pipeline stage `Checkout` duration in Blue Ocean / Stage View
- Fix:
```groovy
// Use shallow clone
checkout scm: [$class: 'GitSCM', extensions: [[$class: 'CloneOption', shallow: true, depth: 1]]]
```

**3. Slow Docker Pull / Build**
- Check: Stage timing for Docker steps
- Fix: Use a local Docker registry / cache base images / use `--cache-from`

**4. No Parallelism (Sequential Stages)**
- Check: Jenkinsfile — are independent stages running sequentially?
- Fix: Use `parallel` blocks:
```groovy
parallel {
  stage('Test') { steps { sh 'run tests' } }
  stage('Lint') { steps { sh 'run lint' } }
}
```

**5. Waiting for External Services (APIs, DBs)**
- Check: Logs for timeout/wait messages in slow stages
- Fix: Mock external calls in tests, set proper timeouts

**6. Too Many/Large Artifacts Being Archived**
- Check: `Archive Artifacts` step duration
- Fix: Archive only necessary files, compress artifacts

**7. Plugin Overhead**
- Check: Disable unused plugins → rerun pipeline → compare times
- Fix: Remove or replace heavy plugins

**8. GC Pauses on Jenkins Master**
- Check: Jenkins logs for GC warnings
- Log: `GC overhead limit exceeded`
- Fix: Increase heap `JAVA_ARGS="-Xms1g -Xmx4g"` + tune GC settings

---

## Key Tools to Find Bottleneck
```
Blue Ocean UI        → visual stage-by-stage timing breakdown
Stage View Plugin    → per-stage duration history
Pipeline Timing      → compare current vs past build times
journalctl logs      → look for waits, retries, timeouts
Agent monitoring     → top / htop / df -h on agent
```

## 6-Step Checklist
```
1. Open Blue Ocean → identify slowest stage
2. Check agent CPU/RAM/Disk during build
3. Check for sequential stages that can be parallelized
4. Check Docker pull / build cache usage
5. Check external service call timeouts
6. Optimize → re-run → compare timing
```

---

> **Key Principle:** Use Blue Ocean stage view to pinpoint the slow stage first. Never optimize blindly.
