#!/bin/sh

# 脚本功能：检测系统类型，并检查是否安装 bash 和 curl

# 颜色定义（使用 printf 兼容性更好）
NC='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'

# 打印带颜色的文本函数
color_echo() {
    printf "%b\n" "$1"
}

color_echo "${GREEN}===== 系统及依赖检测脚本 =====${NC}"

# 1. 检测系统类型
printf "%b" "${YELLOW}🔍 检测系统类型:${NC} "
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$NAME $VERSION"
elif [ -f /etc/alpine-release ]; then
    echo "Alpine Linux $(cat /etc/alpine-release)"
elif [ -f /etc/redhat-release ]; then
    cat /etc/redhat-release
elif command -v uname >/dev/null 2>&1; then
    uname -sr
else
    echo "未知系统"
fi

# 2. 检查 bash
printf "%b" "${YELLOW}🔍 检查是否安装 bash:${NC} "
if command -v bash >/dev/null 2>&1; then
    printf "${GREEN}✅ 已安装 ($(bash --version | head -n 1))${NC}\n"
else
    printf "${RED}❌ 未安装${NC}\n"
fi

# 3. 检查 curl
printf "%b" "${YELLOW}🔍 检查是否安装 curl:${NC} "
if command -v curl >/dev/null 2>&1; then
    printf "${GREEN}✅ 已安装 ($(curl --version | head -n 1))${NC}\n"
else
    printf "${RED}❌ 未安装${NC}\n"
fi

color_echo "${GREEN}=============================${NC}"