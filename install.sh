#!/usr/bin/env bash
# ============================================================
# Opennote8-Paji — Openclaw Auto Installer
# รันหลัง Termux ลง Ubuntu เสร็จ
#
# ครอบคลุม:
#   Step 2 — ติดตั้ง Termux packages
#   Step 3 — เปิด sshd + ตั้งรหัสผ่าน openclaw
#   Step 4 — ติดตั้ง Ubuntu (proot-distro) + Node.js v22
#   Step 5 — ติดตั้ง Openclaw (retry อัตโนมัติถ้า fail)
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${CYAN}▶ $1${NC}"; }
ok()   { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
err()  { echo -e "${RED}✗ $1${NC}"; }

# ─────────────────────────────────────────────────────────────
# STEP 2: ติดตั้ง Termux packages
# ─────────────────────────────────────────────────────────────
log "STEP 2: อัปเดต Termux + ติดตั้ง packages..."

pkg update -y && pkg upgrade -y

pkg install -y proot-distro git nodejs openssh tmux nano wget curl build-essential python proot
pkg install -y iproute2 cloudflared screen

ok "STEP 2 เสร็จ"

# ─────────────────────────────────────────────────────────────
# STEP 3: เปิด sshd + ตั้งรหัสผ่าน openclaw
# ─────────────────────────────────────────────────────────────
log "STEP 3: เปิด sshd + ตั้งรหัสผ่าน..."

# เปิด sshd
sshd 2>/dev/null || true
ok "sshd เปิดแล้ว"

# ตั้งรหัสผ่าน openclaw แบบ non-interactive
echo "openclaw" | passwd --stdin 2>/dev/null || \
  echo -e "openclaw\nopenclaw" | passwd 2>/dev/null || \
  warn "ตั้งรหัสผ่านด้วยตัวเองด้วยคำสั่ง: passwd"

ok "STEP 3 เสร็จ — รหัสผ่าน: openclaw"
echo ""
echo -e "  ${CYAN}SSH Info:${NC}"
echo -e "  user:     ${YELLOW}$(whoami)${NC}"
echo -e "  IP:       ${YELLOW}$(ifconfig 2>/dev/null | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}' | head -1)${NC}"
echo -e "  port:     ${YELLOW}8022${NC}"
echo -e "  password: ${YELLOW}openclaw${NC}"
echo ""

# ─────────────────────────────────────────────────────────────
# STEP 4: ติดตั้ง Ubuntu + Node.js v22 ข้างใน
# ─────────────────────────────────────────────────────────────
log "STEP 4: ติดตั้ง Ubuntu (proot-distro)..."

proot-distro install ubuntu 2>/dev/null || warn "Ubuntu อาจติดตั้งไปแล้ว"

ok "Ubuntu พร้อม — เข้าไปตั้งค่าข้างใน..."

# รัน commands ข้างใน Ubuntu ทั้งหมดในครั้งเดียว
proot-distro login ubuntu -- bash -c '
set -e

echo "--- ตั้ง timezone Asia/Bangkok ---"
ln -sf /usr/share/zoneinfo/Asia/Bangkok /etc/localtime
echo "Asia/Bangkok" > /etc/timezone

echo "--- apt update + install deps ---"
apt update -y && apt upgrade -y
apt install -y curl git build-essential procps file socat python3 make g++ libopus-dev libffi-dev

echo "--- ติดตั้ง Node.js v22 ---"
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

echo "--- ตรวจ Node version ---"
node -v
npm -v
'

ok "STEP 4 เสร็จ — Ubuntu + Node.js v22 พร้อม"

# ─────────────────────────────────────────────────────────────
# STEP 5: ติดตั้ง Openclaw (retry อัตโนมัติ)
# ─────────────────────────────────────────────────────────────
log "STEP 5: ติดตั้ง Openclaw ใน Ubuntu..."

MAX_RETRY=10

proot-distro login ubuntu -- bash -c '
set -e

echo "--- Config NPM timeout ---"
npm config delete proxy
npm config delete https-proxy
npm config set fetch-retry-mintimeout 20000
npm config set fetch-retry-maxtimeout 120000
npm config set fetch-timeout 600000

MAX_RETRY=10
attempt=1

while [ $attempt -le $MAX_RETRY ]; do
  echo "--- ติดตั้ง Openclaw (ครั้งที่ $attempt/$MAX_RETRY) ---"
  if npm install -g openclaw@latest \
      --registry=https://registry.yarnpkg.com/ \
      --unsafe-perm=true \
      --ignore-scripts; then
    echo "✓ Openclaw ติดตั้งสำเร็จ!"
    break
  else
    echo "⚠ ล้มเหลว (EAI_AGAIN?) — รอ 5 วินาที แล้วลองใหม่..."
    sleep 5
    attempt=$((attempt + 1))
  fi
done

if [ $attempt -gt $MAX_RETRY ]; then
  echo "✗ ติดตั้งไม่สำเร็จหลัง $MAX_RETRY ครั้ง กรุณารันใหม่"
  exit 1
fi
'

ok "STEP 5 เสร็จ — Openclaw ติดตั้งสำเร็จ 🎉"

DEVICE_IP=$(ifconfig 2>/dev/null | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
DEVICE_USER=$(whoami)

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ ติดตั้ง Openclaw เสร็จสมบูรณ์!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}SSH จากคอม:${NC}"
echo -e "  ${YELLOW}ssh ${DEVICE_USER}@${DEVICE_IP} -p 8022${NC}"
echo -e "  password: ${YELLOW}openclaw${NC}"
echo ""
echo -e "  ${CYAN}เข้า Ubuntu:${NC}"
echo -e "  ${YELLOW}proot-distro login ubuntu${NC}"
echo ""

# รอ 3 วิ แล้วเข้า Ubuntu เลย
echo -e "${CYAN}▶ เข้า Ubuntu อัตโนมัติใน 3 วินาที... (Ctrl+C เพื่อยกเลิก)${NC}"
sleep 3
proot-distro login ubuntu
