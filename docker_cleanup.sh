#!/bin/bash

# Docker Cleanup Script
# Membersihkan Docker images, containers, volumes, dan networks yang tidak digunakan

set -e

# Colors untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}   🐳 Docker Cleanup Script${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# Get disk usage sebelum cleanup
echo -e "${YELLOW}📊 Penggunaan Disk Sebelum Cleanup:${NC}"
DISK_BEFORE=$(du -sh /var/lib/docker 2>/dev/null | awk '{print $1}')
echo -e "   /var/lib/docker: ${DISK_BEFORE}"
echo ""

# Check Docker daemon status
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker tidak terinstall atau tidak dapat diakses${NC}"
    exit 1
fi

if ! docker ps &> /dev/null; then
    echo -e "${RED}❌ Docker daemon tidak berjalan atau user tidak punya permission${NC}"
    echo -e "   Coba: sudo bash $0"
    exit 1
fi

echo -e "${GREEN}✓ Docker daemon sedang berjalan${NC}"
echo ""

# Step 1: Docker System Prune
echo -e "${YELLOW}🧹 Step 1: Membersihkan Docker System (images, containers, networks)${NC}"
echo "   Menjalankan: docker system prune -a --force"
echo ""

if docker system prune -a --force; then
    echo -e "${GREEN}✓ Docker system prune berhasil${NC}"
else
    echo -e "${RED}✗ Docker system prune gagal${NC}"
fi
echo ""

# Step 2: Docker Volume Prune
echo -e "${YELLOW}🧹 Step 2: Membersihkan Docker Volumes${NC}"
echo "   Menjalankan: docker volume prune --force"
echo ""

if docker volume prune --force; then
    echo -e "${GREEN}✓ Docker volume prune berhasil${NC}"
else
    echo -e "${RED}✗ Docker volume prune gagal${NC}"
fi
echo ""

# Get disk usage setelah cleanup
echo -e "${YELLOW}📊 Penggunaan Disk Setelah Cleanup:${NC}"
DISK_AFTER=$(du -sh /var/lib/docker 2>/dev/null | awk '{print $1}')
echo -e "   /var/lib/docker: ${DISK_AFTER}"
echo ""

# Summary
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Cleanup Selesai!${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
echo -e "   Disk sebelum: ${DISK_BEFORE}"
echo -e "   Disk sesudah: ${DISK_AFTER}"
echo ""
echo -e "Untuk hasil optimal, jalankan juga:"
echo -e "   ${YELLOW}docker network prune --force${NC}  (bersihkan unused networks)"
echo -e "   ${YELLOW}journalctl --vacuum=30d${NC}      (bersihkan log sistem)"
echo ""
