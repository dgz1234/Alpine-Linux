#!/bin/sh
# LXC Container Resource Monitor
# License: MIT
# GitHub: https://github.com/yourname/lxc-monitor

# 颜色定义
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; CYAN='\033[1;36m'; NC='\033[0m'

# 检查依赖
check_deps() {
    for cmd in bc awk; do
        if ! command -v $cmd >/dev/null; then
            echo >&2 "${RED}错误: 需要安装 $cmd${NC}"
            echo >&2 "Alpine请运行: apk add bc awk"
            exit 1
        fi
    done
}

# 获取CPU信息
get_cpu_info() {
    [ -f /sys/fs/cgroup/cpu.max ] || {
        echo "${YELLOW}无法获取CPU数据${NC}"
        return
    }
    cpu_line=$(cat /sys/fs/cgroup/cpu.max)
    cpu_quota=$(echo "$cpu_line" | awk '{print $1}')
    cpu_period=$(echo "$cpu_line" | awk '{print $2}')
    [ "$cpu_quota" = "max" ] && echo "${YELLOW}无限制${NC}" || \
    echo "${YELLOW}$(echo "scale=1; $cpu_quota*100/$cpu_period" | bc)%${NC}"
}

# 主函数
main() {
    check_deps
    echo -e "${BLUE}🛠️ LXC 容器资源状态 $(date '+%m-%d %H:%M')${NC}"
    echo -e "----------------------------------"
    echo -e "${CYAN}⚡ CPU${NC}: $(get_cpu_info)"
    echo -e "${CYAN}📊 内存${NC}: $(get_mem_info)"
    echo -e "${CYAN}💾 磁盘${NC}: $(get_disk_info)"
    echo -e "----------------------------------"
}

# 运行主函数
main "$@"