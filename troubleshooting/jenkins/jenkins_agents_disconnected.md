# Jenkins Agents Disconnected – Troubleshooting

## Quick Diagnosis Flow
```
Check agent status (UI) → check logs → check network/SSH → fix → reconnect
```

---

## Common Causes & Fixes

**1. Network Connectivity Issue**
- Check: Ping agent from master
```bash
ping <agent-ip>
ssh jenkins@<agent-ip>
```
- Fix: Fix firewall rules, VPN, or network routing

**2. SSH Key / Credential Issue**
- Check: `Manage Jenkins` → `Nodes` → agent → `Log` → SSH errors
- Log: `Auth fail` / `Connection refused` / `Permission denied`
- Fix: Re-add correct SSH private key in Jenkins credentials

**3. Java Not Found / Wrong Version on Agent**
- Check: Agent log → `java not found` or version mismatch
- Fix:
```bash
sudo apt install openjdk-17-jdk    # on agent machine
java -version                       # verify
```

**4. Agent Process Crashed / Not Running**
- Check: On agent machine:
```bash
ps aux | grep jenkins
```
- Fix: Restart agent process
```bash
# For JNLP agent
java -jar agent.jar -url http://<jenkins-url> -secret <secret> -name <agent-name>
```

**5. Disk Full on Agent**
- Check:
```bash
df -h    # on agent machine
```
- Log: `No space left on device`
- Fix: Clean workspace, remove old builds/artifacts/Docker images

**6. Agent Workspace Permissions Issue**
- Check: Jenkins agent log for permission errors
- Log: `Permission denied` on workspace path
- Fix:
```bash
sudo chown -R jenkins:jenkins /var/lib/jenkins/
```

**7. Firewall Blocking Agent Port (50000 JNLP)**
- Check:
```bash
sudo ss -tulpn | grep 50000
```
- Fix: Open port 50000 on master firewall for JNLP agents

**8. Master-Agent Clock Skew**
- Check: Compare time on master vs agent
```bash
date    # run on both master and agent
```
- Fix:
```bash
sudo timedatectl set-ntp true    # sync NTP on agent
```

---

## Reconnect Agent (Step-by-Step)
```
UI Method:
Manage Jenkins → Nodes → click agent → Launch Agent / Reconnect

Manual JNLP:
java -jar agent.jar -url http://<jenkins>:8080 -secret <secret> -name <name>

SSH Agent:
Jenkins re-launches automatically if SSH credentials and connectivity are correct
```

## 8-Step Checklist
```bash
ping <agent-ip>                        # 1. network reachable?
ssh jenkins@<agent-ip>                 # 2. SSH works?
ps aux | grep jenkins                  # 3. agent process running?
java -version                          # 4. correct Java on agent?
df -h                                  # 5. disk space ok?
ss -tulpn | grep 50000                 # 6. JNLP port open?
date                                   # 7. clock in sync?
Manage Jenkins → Nodes → agent → Log   # 8. read agent logs
```

---

> **Key Principle:** Always check the agent log in Jenkins UI first — it shows the exact disconnection reason.
