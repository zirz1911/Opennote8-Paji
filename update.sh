#!/usr/bin/env bash
# ============================================================
# Opennote8-Paji — Openclaw Updater
# รันใน Termux เพื่ออัปเดตเครื่องที่ติดตั้งไปแล้ว
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

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─────────────────────────────────────────────────────────────
# ดึง update ล่าสุดจาก repo
# ─────────────────────────────────────────────────────────────
log "ดึง update จาก GitHub..."
git -C "$REPO_DIR" pull origin main 2>/dev/null || warn "git pull ไม่สำเร็จ (ข้ามได้)"
ok "Repo อัปเดตแล้ว"

# ─────────────────────────────────────────────────────────────
# อัปเดต Termux ~/.bashrc
# ─────────────────────────────────────────────────────────────
log "อัปเดต Termux ~/.bashrc..."
cp "${REPO_DIR}/bashrc.termux.1.txt" ~/.bashrc
ok "Termux ~/.bashrc อัปเดตแล้ว"

# ─────────────────────────────────────────────────────────────
# อัปเดต Ubuntu ~/.bashrc
# ─────────────────────────────────────────────────────────────
log "อัปเดต Ubuntu ~/.bashrc..."
proot-distro login ubuntu -- bash -c "cp '${REPO_DIR}/bashrc.ubuntu.1.txt' ~/.bashrc"
ok "Ubuntu ~/.bashrc อัปเดตแล้ว"

# ─────────────────────────────────────────────────────────────
# Restart sshd
# ─────────────────────────────────────────────────────────────
log "Restart sshd..."
pkill sshd 2>/dev/null || true
sleep 1
sshd 2>/dev/null && ok "sshd เปิดแล้ว" || warn "sshd ไม่สามารถเปิดได้"

# ─────────────────────────────────────────────────────────────
# แสดง SSH info
# ─────────────────────────────────────────────────────────────
DEVICE_IP=$(ip route get 1 2>/dev/null | grep -oP 'src \K\S+' | head -1)
DEVICE_USER=$(whoami)

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ อัปเดตเสร็จสมบูรณ์!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}SSH จากคอม:${NC}"
echo -e "  ${YELLOW}ssh ${DEVICE_USER}@${DEVICE_IP} -p 8022${NC}"
echo -e "  password: ${YELLOW}openclaw${NC}"
echo ""
