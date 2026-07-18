#!/bin/bash
set -e
[[ $EUID -ne 0 ]] && { echo "Jalankan: sudo $0"; exit 1; }

RED='\033[0;31m';GREEN='\033[0;32m';YELLOW='\033[1;33m';BLUE='\033[0;34m';NC='\033[0m'
LOG_DIR=/var/log; DAYS_OLD=15
format_size(){ numfmt --to=iec-i --suffix=B "$1" 2>/dev/null || echo "$1 B"; }
wait_for_apt(){
 local timeout=300 elapsed=0
 echo "    Menunggu proses APT selesai..."
 while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
   [ $elapsed -ge $timeout ] && { echo -e "${YELLOW}    Timeout, lewati cleanup APT.${NC}"; return 1; }
   echo "    APT sedang digunakan... (${elapsed}s)"
   sleep 5; elapsed=$((elapsed+5))
 done
 echo -e "${GREEN}    ✓ APT siap${NC}"
}
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SYSTEM CLEANUP $(date '+%F %T')${NC}"
echo -e "${BLUE}========================================${NC}"
bused=$(df /var|awk 'NR==2{print $3}'); bav=$(df /var|awk 'NR==2{print $4}')
echo -e "${YELLOW}[1] Disk Sebelum${NC}"
echo "    Digunakan: $(format_size $((bused*1024)))"
echo "    Tersedia : $(format_size $((bav*1024)))"
echo -e "\n${YELLOW}[2] Scan Log Rotasi > ${DAYS_OLD} hari${NC}"
mapfile -t files < <(find "$LOG_DIR" -type f \( -name "*.gz" -o -name "*.1" -o -name "*.old" \) -mtime +$DAYS_OLD)
total=0
for f in "${files[@]}"; do s=$(stat -c%s "$f"); total=$((total+s)); echo " - $f ($(format_size $s))"; done
echo "Total: ${#files[@]} file ($(format_size $total))"
echo -e "\n${YELLOW}[3] Hapus Log Rotasi${NC}"
for f in "${files[@]}"; do rm -f "$f" && echo " ✓ $f"; done
echo -e "\n${YELLOW}[4] Vacuum Journal >30d${NC}"
echo "    Sebelum: $(journalctl --disk-usage)"
journalctl --vacuum-time=30d
echo "    Sesudah: $(journalctl --disk-usage)"
echo -e "\n${YELLOW}[5] Batasi Journal 200M${NC}"
journalctl --vacuum-size=200M
echo "    Saat ini: $(journalctl --disk-usage)"
echo -e "\n${YELLOW}[6] Cleanup APT${NC}"
if wait_for_apt; then
 echo "Cache sebelum: $(du -sh /var/cache/apt|cut -f1)"
 apt-get clean; apt-get autoclean; apt autoremove -y
 echo "Cache sesudah: $(du -sh /var/cache/apt|cut -f1)"
fi
aused=$(df /var|awk 'NR==2{print $3}'); aav=$(df /var|awk 'NR==2{print $4}')
echo -e "\n${BLUE}========== RINGKASAN ==========${NC}"
echo "Log dihapus : ${#files[@]} file"
echo "Ukuran log  : $(format_size $total)"
echo "Disk awal   : $(format_size $((bused*1024)))"
echo "Disk akhir  : $(format_size $((aused*1024)))"
echo "Space bebas : $(format_size $(((bused-aused)*1024)))"
echo "Journal     : $(journalctl --disk-usage)"
echo "Selesai     : $(date '+%F %T')"
