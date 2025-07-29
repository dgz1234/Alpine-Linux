cat > /tmp/lxc-status.sh << 'EOF'
#!/bin/sh
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; CYAN='\033[1;36m'; NC='\033[0m'

get_cpu_info() {
    cpu_line=$(cat /sys/fs/cgroup/cpu.max 2>/dev/null)
    cpu_quota=$(echo "$cpu_line" | awk '{print $1}')
    cpu_period=$(echo "$cpu_line" | awk '{print $2}')
    [ "$cpu_quota" = "max" ] && echo "${YELLOW}无限制${NC}" || \
    echo "${YELLOW}$(echo "scale=1; $cpu_quota*100/$cpu_period" | bc)%${NC} (${cpu_quota}us/${cpu_period}us)"
}

get_mem_info() {
    mem_max=$(cat /sys/fs/cgroup/memory.max 2>/dev/null)
    mem_used=$(cat /sys/fs/cgroup/memory.current 2>/dev/null)
    if [ "$mem_max" = "max" ]; then
        echo "限制=${YELLOW}无限制${NC}, 已用=${GREEN}$(echo "scale=1; $mem_used/1048576" | bc)MB${NC}"
    else
        used_mb=$(echo "scale=1; $mem_used/1048576" | bc)
        max_mb=$(echo "scale=1; $mem_max/1048576" | bc)
        usage_percent=$(echo "scale=0; $mem_used*100/$mem_max" | bc)
        if [ "$usage_percent" -ge 90 ]; then
            echo "限制=${YELLOW}${max_mb}MB${NC}, 已用=${RED}${used_mb}MB (警告: ${usage_percent}%)${NC}"
        else
            echo "限制=${YELLOW}${max_mb}MB${NC}, 已用=${GREEN}${used_mb}MB${NC}"
        fi
    fi
}

echo -e "${BLUE}🛠️ LXC 容器资源状态 $(date '+%m-%d %H:%M')${NC}"
echo -e "----------------------------------"
echo -e "${CYAN}⚡ CPU${NC}: $(get_cpu_info)"
echo -e "${CYAN}📊 内存${NC}: $(get_mem_info)"
echo -e "${CYAN}💾 磁盘${NC}: $(df -h / | awk 'NR==2 {print "已用='${GREEN}'"$3"'${NC}'/总容量='${YELLOW}'"$2"'${NC}' ("$5")"}')"
echo -e "----------------------------------"
EOF

# 运行
chmod +x /tmp/lxc-status.sh && /tmp/lxc-status.sh