#!/bin/bash

# ==============================================================================
# ==============================================================================

set -e # Exit immediately if a command fails

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (sudo)"
  exit
fi

echo "=== 🕷️ Starting Spidy Network Optimization (Hybrid) ==="

# ==============================================================================
# 1. PREPARATION
# ==============================================================================
echo "[-] Installing dependencies..."
pacman -S --needed --noconfirm powerdns-recursor bind-tools nftables

# Unlock resolv.conf if locked
if lsattr /etc/resolv.conf 2>/dev/null | grep -q "i"; then
    chattr -i /etc/resolv.conf
fi

# ==============================================================================
# 2. SYSTEMD-RESOLVED (The Fallback)
# ==============================================================================
echo "[-] Configuring Systemd-Resolved (Fallback)..."

# CRITICAL FIX: Unmask the service so it can actually start
systemctl unmask systemd-resolved 2>/dev/null || true

# Apply Spidy Tweaks for Systemd-Resolved
cat <<EOF > /etc/systemd/resolved.conf
[Resolve]
# Quad9 ECS (Primary) + Cloudflare (Secondary)
DNS=9.9.9.11 149.112.112.11 1.1.1.1
# Fallback if primary fails
FallbackDNS=1.1.1.1 1.0.0.1
# Optimization Flags
DNSSEC=allow-downgrade
DNSOverTLS=no
Cache=yes-scaling
DNSStubListener=yes
ReadEtcHosts=yes
MulticastDNS=no
LLMNR=no
EOF

echo "    -> Restarting Systemd-Resolved..."
systemctl enable --now systemd-resolved
systemctl restart systemd-resolved

# ==============================================================================
# 3. POWERDNS RECURSOR (The Primary)
# ==============================================================================
echo "[-] Configuring PowerDNS Recursor (Primary)..."

# Cleanup old configs
rm -f /etc/powerdns/recursor.conf
[ -f /etc/powerdns/recursor.yml ] && mv /etc/powerdns/recursor.yml /etc/powerdns/recursor.yml.bak

# Write YAML Config (v5)
# Binding strictly to 127.0.0.1 to avoid conflict with Systemd (127.0.0.53)
cat <<EOF > /etc/powerdns/recursor.yml
incoming:
  listen:
    - 127.0.0.1:53
  allow_from:
    - 127.0.0.0/8

recursor:
  threads: 2
  forward_zones_recurse:
    - zone: "."
      forwarders:
        - 9.9.9.11
        - 149.112.112.11
        - 1.1.1.1

dnssec:
  validation: validate

cache:
  max_entries: 500000
  packet_ttl: 3600
EOF

chmod 644 /etc/powerdns/recursor.yml
echo "    -> Restarting PowerDNS..."
systemctl restart pdns-recursor

# ==============================================================================
# 4. DNS RESOLVER (Hybrid Setup)
# ==============================================================================
echo "[-] Configuring Resolv.conf with Fallback..."

rm -f /etc/resolv.conf
cat <<EOF > /etc/resolv.conf
# Spidy Hybrid DNS
# 1. Try PowerDNS (Localhost) - The caching beast
nameserver 127.0.0.1
# 2. If PowerDNS dies, use Systemd-Resolved (Stub)
nameserver 127.0.0.53
# 3. Timeout: If PDNS doesn't answer in 1s, switch to Systemd
options edns0 trust-ad timeout:1 attempts:1
EOF

# Lock file so NetworkManager doesn't ruin it
chattr +i /etc/resolv.conf

# NetworkManager: Keep 'dns=none' so it respects our manual resolv.conf
mkdir -p /etc/NetworkManager/conf.d
cat <<EOF > /etc/NetworkManager/conf.d/00-spidy-dns.conf
[main]
dns=none
systemd-resolved=false
EOF
systemctl restart NetworkManager

# ==============================================================================
# 5. FIREWALL (NFTABLES)
# ==============================================================================
echo "[-] Configuring Firewall (nftables)..."

cat <<EOF > /etc/nftables.conf
#!/usr/sbin/nft -f
flush ruleset
table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        iifname "lo" accept
        ct state established,related accept
        iifname { "virbr0", "docker0", "podman0", "waydroid0" } accept
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept
        
        # Services (SSH, Web)
        tcp dport { 22, 80, 443, 8080 } accept
        
        # KDE Connect / Local Sync
        udp dport { 1714-1764 } accept
        tcp dport { 1714-1764 } accept
    }
    chain forward { type filter hook forward priority 0; policy drop; }
    chain output { type filter hook output priority 0; policy accept; }
}
EOF
systemctl enable --now nftables

# ==============================================================================
# 6. KERNEL TUNING (STRICT LOW LATENCY / <50Mbps)
# ==============================================================================
echo "[-] Applying Strict Sysctl Rules (Low Buffer/Latency)..."

rm -f /etc/sysctl.d/99-cachyos-net-opt.conf

cat <<EOF > /etc/sysctl.d/99-spidy-net-opt.conf
# --- Queueing & Congestion ---
# CAKE is mandatory for avoiding lag on slow connections
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr

# --- Buffer Sizes (REDUCED) ---
# 2.5MB is mathematically ideal for 50Mbps. Prevents queue buildup.
net.core.rmem_default = 65536
net.core.wmem_default = 65536
net.core.rmem_max = 2621440
net.core.wmem_max = 2621440

# --- Backlog (REDUCED) ---
net.core.netdev_max_backlog = 1000
net.core.netdev_budget = 300

# --- TCP Memory Auto-Tuning (Tighter Limits) ---
net.ipv4.tcp_rmem = 4096 87380 2621440
net.ipv4.tcp_wmem = 4096 65536 2621440

# --- Gaming / Responsiveness Flags ---
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_moderate_rcvbuf = 1

# --- UDP Optimization (Gaming) ---
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192

# --- Security & Reliability ---
net.ipv4.tcp_rfc1337 = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.core.bpf_jit_harden = 1
net.ipv4.ip_forward = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
EOF

sysctl --system > /dev/null

# ==============================================================================
# 7. VERIFICATION
# ==============================================================================
echo "=== 🕷️ Optimization Complete ==="
echo "1. Primary DNS: PowerDNS (127.0.0.1)"
echo "2. Fallback DNS: Systemd-Resolved (127.0.0.53)"

echo "Testing Primary (PDNS)..."
if dig google.com +short @127.0.0.1 | grep -q "[0-9]"; then
    echo "✅ PowerDNS is working."
else
    echo "⚠️ PowerDNS failed (check logs). System should fallback automatically."
fi

echo "Testing Fallback (Resolved)..."
if dig google.com +short @127.0.0.53 | grep -q "[0-9]"; then
    echo "✅ Systemd-Resolved is working."
else
    echo "❌ Systemd-Resolved failed."
fi