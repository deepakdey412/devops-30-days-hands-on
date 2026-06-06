# Jenkins Service Keeps Restarting – Troubleshooting

## Quick Diagnosis Flow

```
systemctl status jenkins → journalctl -u jenkins -f → check resources → fix → restart
```

---

## Common Causes & Fixes

**1. OOM (Out of Memory)**

- Check: `dmesg -T | grep -i oom` / `free -h`
- Log: `Out of memory: Kill process (java)`
- Fix: Set `JAVA_ARGS="-Xms1g -Xmx4g"` in Jenkins config

**2. Disk Full**

- Check: `df -h` / `du -sh /var/lib/jenkins/*`
- Log: `No space left on device`
- Fix: `docker system prune -a` + delete old artifacts/logs/workspaces

**3. Java Version Mismatch**

- Check: `java -version`
- Log: `UnsupportedClassVersionError`
- Fix: `sudo apt install openjdk-17-jdk`

**4. Corrupted Plugin**

- Check: `journalctl -u jenkins -f`
- Log: `Failed Loading Plugin` / `Plugin dependency error`
- Fix: `mv /var/lib/jenkins/plugins/plugin.jpi plugin.jpi.bak`

**5. Port Conflict (8080)**

- Check: `sudo ss -tulpn | grep 8080`
- Log: `Address already in use`
- Fix: `sudo lsof -i :8080` → kill process or change Jenkins port

**6. Config Corruption**

- Log: `Failed to initialize Jenkins` / `Cannot load config.xml`
- Fix: Restore backup config, validate XML

**7. CPU Exhaustion**

- Check: `top` / `htop` → CPU at 100%
- Fix: Stop unnecessary jobs, optimize pipelines, scale agents

**8. Bad Service Config**

- Log: `Failed with result 'exit-code'`
- Fix: `systemctl cat jenkins` → fix → `systemctl daemon-reload`

---

## 8-Step Checklist

```bash
systemctl status jenkins          # 1. service state
journalctl -u jenkins -f          # 2. logs
free -h                           # 3. memory
df -h                             # 4. disk
java -version                     # 5. java
ss -tulpn | grep 8080             # 6. port
dmesg -T | grep -i oom            # 7. OOM events
systemctl restart jenkins         # 8. restart after fix
```

---

> **Key Principle:** Always follow logs → metrics → root cause. Never assume.
