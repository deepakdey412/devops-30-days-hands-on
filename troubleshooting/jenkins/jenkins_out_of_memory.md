# Jenkins Showing "Out Of Memory" Errors – Steps to Take

## Quick Diagnosis Flow
```
Confirm OOM → check heap/GC logs → increase memory → optimize → restart
```

---

## Common Causes & Fixes

**1. JVM Heap Too Small**
- Check:
```bash
ps aux | grep jenkins    # see current -Xmx value
```
- Log: `java.lang.OutOfMemoryError: Java heap space`
- Fix: Increase heap in `/etc/default/jenkins` or service file:
```bash
JAVA_ARGS="-Xms1g -Xmx4g"
sudo systemctl restart jenkins
```

**2. Too Many Concurrent Builds**
- Check: Jenkins UI → Build Queue + active executors
- Fix: Limit concurrent builds per job → `Throttle Concurrent Builds` plugin

**3. Build History Accumulation**
- Check: `du -sh /var/lib/jenkins/jobs/*/builds/`
- Fix: Set build retention in job config:
```
Discard old builds → Keep max 10 builds / 30 days
```

**4. Memory Leak in Plugin**
- Check: Jenkins logs for repeated GC warnings before OOM
- Log: `GC overhead limit exceeded`
- Fix: Identify and disable recently added/updated plugins one by one

**5. Large Build Artifacts Loaded in Memory**
- Check: Jobs archiving very large files or loading huge logs
- Fix: Stream logs instead of loading entirely, reduce artifact size

**6. PermGen / Metaspace Exhaustion (older JVMs)**
- Log: `OutOfMemoryError: PermGen space` / `Metaspace`
- Fix:
```bash
JAVA_ARGS="-Xmx4g -XX:MaxMetaspaceSize=512m"
```

**7. OS-Level Memory Full (OOM Killer)**
- Check:
```bash
dmesg -T | grep -i oom
free -h
```
- Log: `Out of memory: Kill process (java)`
- Fix: Add swap space or upgrade server RAM

---

## Add Swap Space (Quick Fix)
```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## Enable GC Logging (for diagnosis)
```bash
JAVA_ARGS="-Xmx4g -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/var/log/jenkins/gc.log"
```

## 7-Step Checklist
```bash
free -h                            # 1. system memory
dmesg -T | grep -i oom             # 2. OOM kill events
journalctl -u jenkins -f           # 3. Jenkins OOM logs
ps aux | grep jenkins              # 4. current heap settings
du -sh /var/lib/jenkins/jobs/*/builds/  # 5. build history size
# 6. increase -Xmx in JAVA_ARGS
sudo systemctl restart jenkins     # 7. restart
```

---

> **Key Principle:** OOM is usually heap size + too many builds + no retention policy. Fix all three together.
