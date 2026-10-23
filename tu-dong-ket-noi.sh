#!/bin/bash
# Chay tren may Linux: bash tu-dong-ket-noi.sh
# Log nam cung thu muc: ket-noi-log.txt

set +e
cd "$HOME" || exit 1
LOG="$HOME/ket-noi-log.txt"
: > "$LOG"

log() {
  printf '%s\n' "$*" | tee -a "$LOG"
}

run() {
  log ""
  log "----- $* -----"
  "$@" >>"$LOG" 2>&1
  code=$?
  if [ "$code" -eq 0 ]; then
    log "OK (ma $code)"
  else
    log "LOI (ma $code): $*"
  fi
  return 0
}

log "Bat dau $(date)"
log "User: $(whoami)  May: $(hostname)"

run sudo mkdir -p /var/run/tailscale /var/lib/tailscale /run/sshd
run sudo ssh-keygen -A

log ""
log "----- khoi dong sshd -----"
if sudo ss -ltnp 2>/dev/null | grep -q ':22 '; then
  log "OK sshd da lang nghe cong 22"
else
  sudo /usr/sbin/sshd >>"$LOG" 2>&1
  code=$?
  if [ "$code" -eq 0 ]; then
    log "OK sshd da bat"
  else
    log "LOI (ma $code): khong bat duoc sshd"
  fi
fi

log ""
log "----- khoa SSH -----"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK5/cAuf59hL5lizzKN0GMhDp01a+/h54SE8ovtw0Krp u0_a287@localhost'
touch "$HOME/.ssh/authorized_keys"
if grep -qxF "$KEY" "$HOME/.ssh/authorized_keys"; then
  log "OK khoa da co san"
else
  printf '%s\n' "$KEY" >> "$HOME/.ssh/authorized_keys"
  log "OK da them khoa"
fi
chmod 600 "$HOME/.ssh/authorized_keys"

log ""
log "----- tailscaled -----"
if [ -S /var/run/tailscale/tailscaled.sock ]; then
  log "OK tailscaled da chay"
else
  sudo nohup tailscaled \
    --state=/var/lib/tailscale/tailscaled.state \
    --socket=/var/run/tailscale/tailscaled.sock \
    >>/tmp/tailscaled.log 2>&1 &
  sleep 2
  if [ -S /var/run/tailscale/tailscaled.sock ]; then
    log "OK tailscaled vua bat"
  else
    log "LOI tailscaled khong tao socket. Xem /tmp/tailscaled.log"
    if [ -f /tmp/tailscaled.log ]; then
      log "----- /tmp/tailscaled.log -----"
      cat /tmp/tailscaled.log >>"$LOG"
    fi
  fi
fi

log ""
log "----- tailscale up -----"
log "Neu hien link, mo link va dang nhap dung tai khoan Tailscale tren dien thoai."
sudo tailscale up 2>&1 | tee -a "$LOG"
code=${PIPESTATUS[0]}
if [ "$code" -eq 0 ]; then
  log "OK tailscale up (ma $code)"
else
  log "LOI (ma $code): tailscale up"
fi

log ""
log "----- ket qua -----"
IP="$(tailscale ip -4 2>>"$LOG")"
log "tailscale ip -4: ${IP:-KHONG CO}"
log "whoami: $(whoami)"
log "Xong $(date)"
log "File log: $LOG"

echo
echo "Gui lai 2 dong nay:"
echo "tailscale ip -4: ${IP:-KHONG CO}"
echo "whoami: $(whoami)"
echo "Log day du: $LOG"
