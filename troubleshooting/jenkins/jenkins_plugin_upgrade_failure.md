# Jenkins Build Failing After Plugin Upgrade – Investigation

## Quick Diagnosis Flow
```
Check logs → identify plugin → rollback → verify → restart
```

---

## Common Causes & Fixes

**1. Plugin Incompatibility with Jenkins Version**
- Check: `Manage Jenkins` → `Plugin Manager` → `Installed` → check plugin version
- Log: `Plugin X requires Jenkins version Y`
- Fix: Downgrade plugin or upgrade Jenkins to required version

**2. Plugin Dependency Conflict**
- Check: `journalctl -u jenkins -f` or Jenkins logs
- Log: `Failed to load: Plugin X depends on Plugin Y`
- Fix: Install/update the missing dependency plugin

**3. Corrupted Plugin File**
- Check: `ls -lh /var/lib/jenkins/plugins/` → look for incomplete `.jpi` files
- Log: `Failed Loading Plugin` / `IOException`
- Fix:
```bash
cd /var/lib/jenkins/plugins/
mv broken-plugin.jpi broken-plugin.jpi.bak
sudo systemctl restart jenkins
```

**4. API / Method Change in New Plugin Version**
- Check: Build console output for `NoSuchMethodError` or `ClassNotFoundException`
- Log: `NoSuchMethodError` / `AbstractMethodError`
- Fix: Rollback plugin to previous version via Plugin Manager → `Installed` → `Downgrade`

**5. Pipeline Syntax Breaking Change**
- Check: Jenkinsfile console output
- Log: `WorkflowScript: unexpected token` / step not recognized
- Fix: Update Jenkinsfile syntax to match new plugin API

**6. Plugin Config Reset After Upgrade**
- Check: Job config or global config for missing values
- Fix: Reconfigure plugin settings under `Manage Jenkins` → `Configure System`

---

## Rollback a Plugin (Step-by-Step)
```bash
# Option 1: Via Jenkins UI
Manage Jenkins → Plugin Manager → Installed → find plugin → Downgrade

# Option 2: Manual rollback
cd /var/lib/jenkins/plugins/
mv plugin-name.jpi plugin-name.jpi.bak        # disable upgraded version
# copy old .jpi from backup or download from plugins.jenkins.io
sudo systemctl restart jenkins
```

## 6-Step Checklist
```
1. journalctl -u jenkins -f          # check logs for errors
2. Note which plugin was upgraded     # correlate with failure time
3. Check plugin dependencies          # Manage Jenkins → Plugin Manager
4. Check console output of failed job # look for method/class errors
5. Rollback plugin to previous version
6. Restart Jenkins + re-run build
```

---

> **Key Principle:** Always upgrade plugins one at a time in staging before production. Use `Pin` to lock stable plugin versions.
