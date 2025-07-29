#!/bin/sh
# 完全兼容Alpine/BusyBox的内存监控脚本
# 更新于2024-07-29

# 颜色定义
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; CYAN='\033[1;36m'; NC='\033[0m'

# 1. 系统级内存概览
echo -e "${BLUE}===== 系统内存概览 =====${NC}"
free -m | awk '
    NR==1 {printf "%-15s %-10s %-10s %-10s\n", $1, $2, $3, $4}
    NR==2 {printf "%-15s %-10s %-10s %-10s\n", "Mem:", $2"MB", $3"MB", $4"MB"}
    NR==3 {printf "%-15s %-10s %-10s %-10s\n", "Swap:", $2"MB", $3"MB", $4"MB"}
'

# 2. 容器内存限制（兼容cgroup v1/v2）
echo -e "\n${BLUE}===== 容器内存限制 =====${NC}"
if [ -f /sys/fs/cgroup/memory.max ]; then
    # cgroup v2
    mem_max=$(cat /sys/fs/cgroup/memory.max)
    mem_used=$(cat /sys/fs/cgroup/memory.current)
elif [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
    # cgroup v1
    mem_max=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
    mem_used=$(cat /sys/fs/cgroup/memory/memory.usage_in_bytes)
else
    mem_max="max"
    mem_used=$(grep MemTotal /proc/meminfo | awk '{print $2*1024}')
fi

if [ "$mem_max" = "max" ]; then
    echo -e "限制: ${GREEN}无限制${NC}"
else
    usage_percent=$(echo "scale=1; $mem_used * 100 / $mem_max" | bc)
    echo -e "限制: ${YELLOW}$(echo "scale=1; $mem_max/1048576" | bc)MB${NC} | 已用: ${RED}$(echo "scale=1; $mem_used/1048576" | bc)MB${NC} (${usage_percent}%)"
fi

# 3. 兼容BusyBox的进程内存排行
echo -e "\n${BLUE}===== 进程内存排行 =====${NC}"
echo -e "${GREEN}%-6s %-8s %-10s %s${NC}" "PID" "RSS(KB)" "COMMAND"
ps -o pid,rss,comm | awk '
    NR>1 {print $0 | "sort -k2 -rn"}
' | head -n 5 | awk '{
    printf "%-6s %-8s %-10.1fMB %s\n", $1, $2, $2/1024, $3
}'

# 4. 兼容性Slab检测
echo -e "\n${BLUE}===== 内核内存 =====${NC}"
if grep -q 'Slab' /proc/meminfo; then
    grep -E 'Slab|SReclaimable|SUnreclaim' /proc/meminfo | awk '{
        printf "%-15s %-10s\n", $1, $2"KB"
    }'
else
    echo -e "${YELLOW}（Slab信息不可用，尝试读取/proc/slabinfo）${NC}"
    [ -f /proc/slabinfo ] && head -n 1 /proc/slabinfo || echo "无可用数据"
fi

# 5. 内存压力（兼容旧内核）
echo -e "\n${BLUE}===== 内存压力 =====${NC}"
if [ -f /proc/pressure/memory ]; then
    grep -E 'some|full' /proc/pressure/memory | awk '{
        printf "%-10s avg10=%.2f%% avg60=%.2f%% avg300=%.2f%%\n", $1, $3*100, $4*100, $5*100
    }'
else
    echo -e "${YELLOW}（内存压力指标不可用，内核版本可能较低）${NC}"
    echo -e "可用指标: OOM次数 - $(grep -c 'oom_kill' /var/log/kern.log 2>/dev/null || echo 0)"
fi

echo -e "\n${RED}提示：${NC}当前内存使用率 ${RED}${usage_percent}%${NC}，建议："
[ $(echo "$usage_percent >= 90" | bc) -eq 1 ] && \
echo -e "1. 立即清理缓存: ${GREEN}sync && echo 3 > /proc/sys/vm/drop_caches${NC} (需root)" || \
echo -e "1. 定期监控: ${GREEN}watch -n 5 'cat /sys/fs/cgroup/memory.current'${NC}"
