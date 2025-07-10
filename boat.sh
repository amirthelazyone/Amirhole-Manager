#!/usr/bin/env bash
##############################################################################
RATHOLE_DIR="/root/rathole-core"
Amirhole_SCRIPT="/root/boat.sh"
Amirhole_SERVICE="rathole_Amirhole.service"
LOGF="/var/log/rathole_manager.log"

if [ -t 1 ]; then RED=$'\e[31m'; GRN=$'\e[32m'; ORG=$'\e[33m'; CYN=$'\e[36m'; RST=$'\e[0m'; else RED=''; GRN=''; ORG=''; CYN=''; RST=''; fi
info(){ echo -e "${GRN}$*${RST}" | tee -a "$LOGF"; }
warn(){ echo -e "${ORG}$*${RST}" | tee -a "$LOGF"; }
err() { echo -e "${RED}$*${RST}" | tee -a "$LOGF"; }

configs(){ ls "$RATHOLE_DIR"/*.toml 2>/dev/null || true; }
scripts(){ ls "$RATHOLE_DIR"/rathole-*.sh 2>/dev/null || true; }
extract_ports(){ grep -Eo '\[server\.services\.[0-9]+' "$1"|grep -Eo '[0-9]+'; grep -E 'bind_addr' "$1"|grep -Eo ':[0-9]+'|tr -d ':'; }
all_ports(){ for f in $(configs); do extract_ports "$f"; done | sort -u; }

kill_ratholes(){ pkill -TERM -f "$RATHOLE_DIR/rathole" 2>/dev/null || true; sleep 0.4; pkill -9 -f "$RATHOLE_DIR/rathole" 2>/dev/null || true; }

spawn_ratholes(){
  kill_ratholes
  local idx=1 total port; total=$(configs | wc -l)
  for cfg in $(configs); do
    port=$(extract_ports "$cfg" | head -n1)
    info "[$idx/$total] starting $(basename "$cfg") (port $port)"
    nohup nice -n 10 "$RATHOLE_DIR/rathole" "$cfg" >>"$LOGF" 2>&1 & disown
    ((idx++)); sleep 0.25
  done
  for s in $(scripts); do
    pgrep -f "$s" >/dev/null && continue
    [ -x "$s" ] || chmod +x "$s"
    info "launching $(basename "$s")"
    nohup "$s" >>"$LOGF" 2>&1 & disown
    sleep 0.15
  done
  info "restart successful"
}

install_Amirhole(){
cat > "$Amirhole_SCRIPT" <<'WDSH'
#!/usr/bin/env bash
RATHOLE_DIR="/root/rathole-core"
LOGF="/var/log/rathole_manager.log"
parse_ports(){ grep -Eo '\[server\.services\.[0-9]+' "$1"|grep -Eo '[0-9]+'; grep -E 'bind_addr' "$1"|grep -Eo ':[0-9]+'|tr -d ':'; }
all_ports(){ for f in "$RATHOLE_DIR"/*.toml; do [ -f "$f" ] && parse_ports "$f"; done | sort -u; }
restart_all(){
  pkill -TERM -f "$RATHOLE_DIR/rathole" 2>/dev/null || true; sleep 0.4
  pkill -9   -f "$RATHOLE_DIR/rathole" 2>/dev/null || true
  for f in "$RATHOLE_DIR"/*.toml; do
    [ -f "$f" ] && (nohup nice -n 10 "$RATHOLE_DIR/rathole" "$f" >>"$LOGF" 2>&1 & disown)
  done
  echo "$(date) - restart successful" >>"$LOGF"
}
while true; do
  ok=0 tot=0
  for p in $(all_ports); do
    ((tot++))
    if timeout 4 bash -c "</dev/tcp/127.0.0.1/$p" &>/dev/null; then ((ok++))
    else
      echo "$(date) - port $p DOWN → restart" >>"$LOGF"
      restart_all; break
    fi
  done
  [ $tot -gt 0 ] && echo "$(date) - $ok/$tot healthy" >>"$LOGF"
  sleep 3
done
WDSH
chmod +x "$Amirhole_SCRIPT"

cat > /etc/systemd/system/"$Amirhole_SERVICE" <<EOF
[Unit]
Description=Rathole Amirhole
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/env bash $Amirhole_SCRIPT
Restart=always
RestartSec=10
KillMode=mixed
StandardOutput=append:$LOGF
StandardError=append:$LOGF
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable "$Amirhole_SERVICE"
sudo systemctl restart "$Amirhole_SERVICE"
info "Amirhole installed & running"
}

remove_Amirhole(){ sudo systemctl stop "$Amirhole_SERVICE"; sudo systemctl disable "$Amirhole_SERVICE"; sudo rm -f /etc/systemd/system/"$Amirhole_SERVICE" "$Amirhole_SCRIPT"; sudo systemctl daemon-reload; warn "Amirhole removed"; }

restart_all_wrapped(){ sudo systemctl restart "$Amirhole_SERVICE"; spawn_ratholes; }

edit_service(){ sudo ${EDITOR:-nano} /etc/systemd/system/"$Amirhole_SERVICE"; sudo systemctl daemon-reload; }

CACHE_LOC=""; CACHE_ISP=""
get_geo(){ read L I < <(curl -s --max-time 3 'http://ip-api.com/line/?fields=country,isp'|tr '\n' ' '); [ -n "$L" ] && CACHE_LOC=$L; [ -n "$I" ] && CACHE_ISP=$I; }

banner(){
  [ -t 1 ] || return
  get_geo
  systemctl is-active "$Amirhole_SERVICE" &>/dev/null && ST="${GRN}Active${RST}" || ST="${RED}Inactive${RST}"
  clear
  echo -e "${CYN}"
cat <<'ASCII'
    ___              _         __          __   
   /   |  ____ ___  (_)____   / /_  ____  / /__ 
  / /| | / __ `__ \/ / ___/  / __ \/ __ \/ / _ \
 / ___ |/ / / / / / / /     / / / / /_/ / /  __/
/_/  |_/_/ /_/ /_/_/_/     /_/ /_/\____/_/\___/ 
                                               
ASCII
  echo -e "${RST}"
  echo -e "${ORG}Version:${RST}  v2.1"
  echo -e "${ORG}Github:${RST}   github.com/amirthelazyone"
  echo -e "${ORG}Telegram:${RST} @edite909"
  echo -e "═══════════════════════════════════════════════"
  echo -e "${ORG}Location:${RST}   ${CACHE_LOC:-unknown}"
  echo -e "${ORG}Datacenter:${RST} ${CACHE_ISP:-unknown}"
  echo -e "${ORG}Amirhole:${RST}   $ST"
  echo -e "═══════════════════════════════════════════════"
}

menu(){
cat <<'MENU'
 1) Install / Update Amirhole
 2) Restart Amirhole + ports
 3) Start Amirhole
 4) Stop Amirhole
 5) Status Amirhole
 6) Amirhole log (ENTER to quit)
 7) Remove Amirhole
 8) Edit Amirhole
 0) Exit
-------------------------------
MENU
}

handle(){
  case "$1" in
    1) install_Amirhole ;;
    2) restart_all_wrapped ;;
    3) sudo systemctl start "$Amirhole_SERVICE" && info "started" ;;
    4) sudo systemctl stop  "$Amirhole_SERVICE" && warn "stopped" ;;
    5) systemctl status "$Amirhole_SERVICE" ;;
    6) (trap '' INT; tail -f "$LOGF" & TPID=$!; read -r; kill $TPID; wait $TPID 2>/dev/null) ;;
    7) remove_Amirhole ;;
    8) edit_service ;;
    0) exit 0 ;;
    *) err "invalid choice" ;;
  esac
}

mkdir -p "$(dirname "$LOGF")"; touch "$LOGF"; chmod +x "$0"
while true; do banner; menu; read -rp "choice: " C; handle "$C"; done
