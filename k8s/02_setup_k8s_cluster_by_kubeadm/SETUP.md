# ⚡ Kubernetes Cluster Setup — kubeadm (Copy-Paste Ready)

> Ubuntu 22.04 / 24.04 · Kubernetes v1.31 · containerd · Calico CNI

---

## 🗺️ Flow — Who Runs What

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   STEP 1 ──► Run  01-all-nodes.sh   on MASTER           │
│   STEP 2 ──► Run  01-all-nodes.sh   on WORKER-1         │
│   STEP 3 ──► Run  01-all-nodes.sh   on WORKER-2         │
│                          │                              │
│                          ▼                              │
│   STEP 4 ──► Run  02-master-init.sh  on MASTER ONLY     │
│                          │                              │
│                (prints a "join" command)                │
│                          │                              │
│                          ▼                              │
│   STEP 5 ──► Paste that join cmd on WORKER-1 & WORKER-2 │
│                          │                              │
│                          ▼                              │
│   STEP 6 ──► kubectl get nodes  →  all show "Ready" ✅  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 📦 What You Need

| Node     | Min RAM | Min CPU | IP (example) |
| -------- | ------- | ------- | ------------ |
| master   | 2 GB    | 2       | 192.168.1.10 |
| worker-1 | 2 GB    | 2       | 192.168.1.11 |
| worker-2 | 2 GB    | 2       | 192.168.1.12 |

> OS: Ubuntu 22.04 or 24.04 with `sudo` / root access

---

## 🟡 STEP 1–3 · `01-all-nodes.sh` → Run on EVERY node

```sh
#!/bin/bash
# ✅ Run this on: MASTER + ALL WORKER NODES
set -euo pipefail

swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay && modprobe br_netfilter

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system > /dev/null

apt-get update -qq
apt-get install -y -qq apt-transport-https ca-certificates curl gpg containerd

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl restart containerd && systemctl enable containerd

mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update -qq
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable --now kubelet

echo "✅ Node ready!"
```

---

## 🔵 STEP 4 · `02-master-init.sh` → Run on MASTER ONLY

> Script auto-detects your master IP. No changes needed.

```sh
#!/bin/bash
# ✅ Run this on: MASTER NODE ONLY
set -euo pipefail

MASTER_IP="$(hostname -I | awk '{print $1}')"   # auto-detect, or hardcode your IP

kubeadm init \
  --apiserver-advertise-address="$MASTER_IP" \
  --pod-network-cidr=192.168.0.0/16 \
  --cri-socket=unix:///var/run/containerd/containerd.sock

# kubectl access
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME="$(eval echo ~$REAL_USER)"
mkdir -p "$USER_HOME/.kube"
cp /etc/kubernetes/admin.conf "$USER_HOME/.kube/config"
chown "$(id -u $REAL_USER):$(id -g $REAL_USER)" "$USER_HOME/.kube/config"

# Install Calico CNI
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo ""
echo "━━━━━━ COPY THIS JOIN COMMAND FOR YOUR WORKERS ━━━━━━"
kubeadm token create --print-join-command
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

---

## 🟢 STEP 5 · Join Workers

Copy the `kubeadm join ...` command printed by the master script and run it on each worker:

```bash
# Example (your token & hash will be different):
sudo kubeadm join 192.168.1.10:6443 \
  --token abcdef.1234567890abcdef \
  --discovery-token-ca-cert-hash sha256:xxxxxxxx...
```

> Lost the join command? Run this on master to regenerate:
>
> ```bash
> kubeadm token create --print-join-command
> ```

---

## ✅ STEP 6 · Verify

```bash
kubectl get nodes -o wide
# NAME        STATUS   ROLES           VERSION
# master      Ready    control-plane   v1.31.x
# worker-1    Ready    <none>          v1.31.x
# worker-2    Ready    <none>          v1.31.x

kubectl get pods -A   # all pods should be Running
```

---

## 🆘 Quick Fixes

| Problem               | Fix                                                       |
| --------------------- | --------------------------------------------------------- |
| Node stuck `NotReady` | `kubectl get pods -n kube-system` — wait for calico pods  |
| `kubeadm init` fails  | `kubeadm reset` then re-run                               |
| Can't run kubectl     | Make sure you ran the `cp admin.conf ~/.kube/config` step |
| Workers can't join    | Check firewall — port `6443` must be open on master       |
| Swap error            | `swapoff -a` and retry                                    |
