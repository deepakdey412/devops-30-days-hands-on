# Jenkins UI Inaccessible But Server Is Running – What to Check

## Quick Diagnosis Flow
```
Confirm process running → check port → check logs → check reverse proxy → fix
```

---

## Common Causes & Fixes

**1. Jenkins Process Not Actually Running**
- Check:
```bash
sudo systemctl status jenkins
ps aux | grep jenkins
```
- Fix:
```bash
sudo systemctl start jenkins
```

**2. Jenkins Listening on Wrong Port**
- Check:
```bash
sudo ss -tulpn | grep java
```
- Fix: Verify/set correct port in `/etc/default/jenkins`:
```bash
HTTP_PORT=8080
sudo systemctl restart jenkins
```

**3. Firewall Blocking Port 8080**
- Check:
```bash
sudo ufw status
sudo iptables -L -n | grep 8080
```
- Fix:
```bash
sudo ufw allow 8080/tcp
sudo ufw reload
```

**4. Reverse Proxy (Nginx/Apache) Misconfigured**
- Check: Nginx/Apache error logs
```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/apache2/error.log
```
- Log: `502 Bad Gateway` / `503 Service Unavailable`
- Fix: Verify proxy_pass points to correct Jenkins port:
```nginx
location / {
    proxy_pass http://localhost:8080;
}
```
Restart proxy:
```bash
sudo systemctl restart nginx
```

**5. Jenkins Still Starting Up (Loading)**
- Check: Jenkins logs for startup progress
```bash
journalctl -u jenkins -f
```
- Log: `Jenkins is fully up and running` — not yet appeared
- Fix: Wait for full startup, especially after plugin updates

**6. Jenkins Crashed / OOM During Startup**
- Check:
```bash
journalctl -u jenkins -f
dmesg -T | grep -i oom
```
- Fix: Increase heap, fix plugin issue, then restart

**7. SSL / HTTPS Certificate Error**
- Check: Browser shows `SSL_ERROR` or `NET::ERR_CERT`
- Fix: Renew SSL certificate or check keystore config in Jenkins

**8. Context Path Mismatch**
- Check: Jenkins configured with `--prefix=/jenkins` but accessed at `/`
- Fix: Use correct URL: `http://<server>:8080/jenkins`
  or remove prefix from `/etc/default/jenkins`

**9. Jenkins Bound to localhost Only**
- Check:
```bash
ss -tulpn | grep 8080    # shows 127.0.0.1:8080 instead of 0.0.0.0:8080
```
- Fix: Set listen address in `/etc/default/jenkins`:
```bash
JENKINS_LISTEN_ADDRESS=""    # empty = all interfaces
sudo systemctl restart jenkins
```

---

## 8-Step Checklist
```bash
systemctl status jenkins              # 1. service running?
ps aux | grep jenkins                 # 2. process exists?
ss -tulpn | grep 8080                 # 3. port listening?
curl -I http://localhost:8080         # 4. reachable locally?
ufw status / iptables -L             # 5. firewall rules?
tail -f /var/log/nginx/error.log      # 6. reverse proxy errors?
journalctl -u jenkins -f             # 7. Jenkins startup logs?
dmesg -T | grep -i oom               # 8. OOM crash?
```

---

> **Key Principle:** Always test `curl localhost:8080` first — if that works, the issue is network/proxy/firewall, not Jenkins itself.
