# Jenkins Webhook Not Triggering Builds After GitHub Commit – Debugging

## Quick Diagnosis Flow
```
Check GitHub delivery logs → check Jenkins URL reachable → check job config → fix → test
```

---

## Common Causes & Fixes

**1. Webhook Not Configured in GitHub**
- Check: GitHub Repo → `Settings` → `Webhooks` → verify webhook URL exists
- Fix: Add webhook:
```
URL: http://<jenkins-url>/github-webhook/
Content type: application/json
Events: Just the push event (or as needed)
```

**2. Jenkins URL Not Publicly Reachable**
- Check: GitHub webhook → `Recent Deliveries` → response code
- Response: `Connection refused` / `Timeout` / `Failed to connect`
- Fix: Ensure Jenkins is accessible from internet or use ngrok for local testing:
```bash
ngrok http 8080
```

**3. Wrong Webhook URL**
- Check: GitHub → `Settings` → `Webhooks` → Payload URL
- Common mistake: Missing trailing slash or wrong path
- Fix:
```
Correct:   http://<jenkins>/github-webhook/
Wrong:     http://<jenkins>/github-webhook  (missing slash)
```

**4. Job Not Configured to Use GitHub Trigger**
- Check: Job Config → `Build Triggers` → `GitHub hook trigger for GITScm polling` — is it checked?
- Fix: Enable the checkbox and save job config

**5. GitHub Plugin Not Installed / Misconfigured**
- Check: `Manage Jenkins` → `Plugin Manager` → search `GitHub`
- Fix: Install/update `GitHub plugin`
- Also check: `Manage Jenkins` → `Configure System` → `GitHub Servers` → valid credentials

**6. Firewall Blocking GitHub IPs**
- Check: GitHub webhook delivery → non-200 response
- Fix: Allow GitHub webhook IP ranges in firewall:
```bash
# GitHub meta API for current IPs
curl https://api.github.com/meta | grep hooks
```

**7. CSRF Protection Blocking Webhook**
- Check: Jenkins logs for `403 Forbidden` on webhook endpoint
- Log: `No valid crumb was included`
- Fix: `Manage Jenkins` → `Configure Global Security` → enable `GitHub webhook` exception or disable CSRF for webhook endpoint

**8. SSL Certificate Issue (HTTPS Jenkins)**
- Check: GitHub delivery → SSL error
- Log: `SSL certificate problem`
- Fix: Use valid SSL cert or configure GitHub to skip SSL verify (not recommended for prod)

---

## Debug Step-by-Step
```
Step 1: GitHub → Repo → Settings → Webhooks → Recent Deliveries
        → Check response code (must be 200)

Step 2: Redeliver webhook manually from GitHub UI
        → Watch Jenkins logs: journalctl -u jenkins -f

Step 3: Test Jenkins URL reachable from outside
        curl -I http://<jenkins-url>/github-webhook/

Step 4: Verify job trigger checkbox is enabled

Step 5: Check Jenkins GitHub plugin config + credentials
```

## 6-Step Checklist
```
1. GitHub → Webhooks → Recent Deliveries → check response code
2. curl -I http://<jenkins>/github-webhook/   # reachability
3. Job Config → Build Triggers → GitHub hook trigger ✓ checked?
4. Manage Jenkins → Plugins → GitHub plugin installed?
5. journalctl -u jenkins -f                   # watch on redeliver
6. Check firewall allows GitHub IP ranges
```

---

> **Key Principle:** GitHub webhook `Recent Deliveries` tab is your best friend — it shows exact request, response, and error.
