#!/bin/sh
# 内存详细监控脚本 - 支持Alpine/BusyBox
# 功能：显示系统总内存、容器限制、进程级内存占用、Slab缓存等

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

# 2. 容器内存限制（cgroup v2）
echo -e "\n${BLUE}===== 容器内存限制 =====${NC}"
if [ -f /sys/fs/cgroup/memory.max ]; then
    mem_max=$(cat /sys/fs/cgroup/memory.max)
    mem_used=$(cat /sys/fs/cgroup/memory.current)
    if [ "$mem_max" = "max" ]; then
        echo -e "限制: ${GREEN}无限制${NC}"
    else
        usage_percent=$(echo "scale=1; $mem_used * 100 / $mem_max" | bc)
        echo -e "限制: ${YELLOW}$(echo "scale=1; $mem_max/1048576" | bc)MB${NC} | 已用: ${RED}$(echo "scale=1; $mem_used/1048576" | bc)MB${NC} (${usage_percent}%)"
    fi
else
    echo -e "${RED}未检测到cgroup内存限制${NC}"
fi

# 3. 用户进程内存排行
echo -e "\n${BLUE}===== 用户进程内存排行 =====${NC}"
ps -eo user,pid,%mem,rss,comm --sort=-rss | head -n 6 | awk '
    BEGIN {printf "%-10s %-8s %-8s %-10s %s\n", "USER", "PID", "%MEM", "RSS(MB)", "COMMAND"}
    NR>1 {printf "%-10s %-8s %-8s %-10.1f %s\n", $1, $2, $3, $4/1024, $5}
'

# 4. Slab内核缓存详情
echo -e "\n${BLUE}===== Slab内核缓存 =====${NC}"
if grep -q 'slab' /proc/meminfo; then
    grep -E 'Slab|SReclaimable|SUnreclaim' /proc/meminfo | awk '
        {printf "%-15s %-10s\n", $1, $2"KB"}
    '
else
    echo -e "${YELLOW}（Slab信息不可用）${NC}"
fi

# 5. 内存压力指标
echo -e "\n${BLUE}===== 内存压力 =====${NC}"
if [ -f /proc/pressure/memory ]; then
    grep -E 'some|full' /proc/pressure/memory | awk '
        {printf "%-10s avg10=%.2f%% avg60=%.2f%% avg300=%.2f%%\n", $1, $3*100, $4*100, $5*100}
    '
else
    echo -e "${YELLOW}（内存压力指标不可用）${NC}"
fi

echo -e "\n${RED}提示：${NC}若内存使用持续高位，建议执行 ${GREEN}sync && echo 3 > /proc/sys/vm/drop_caches${NC} 清理缓存（需root权限）"