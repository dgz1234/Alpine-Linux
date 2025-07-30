#!/bin/sh

# 脚本功能：检测系统类型，并检查是否安装 bash 和 curl
# 强制启用颜色（即使通过管道执行）
export TERM=xterm
NC='\033[0m'  # 重置颜色
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'

echo -e "${GREEN}===== 系统及依赖检测脚本 =====${NC}"
echo -n "${YELLOW}🔍 检测系统类型:${NC} "

echo "===== 系统及依赖检测脚本 ====="

# 1. 检测系统类型
echo -n "🔍 检测系统类型: "
if [ -f /etc/os-release ]; then
    # 大多数Linux发行版（Debian/Ubuntu/CentOS等）
    . /etc/os-release
    echo "$NAME $VERSION"
elif [ -f /etc/alpine-release ]; then
    # Alpine Linux
    echo "Alpine Linux $(cat /etc/alpine-release)"
elif [ -f /etc/redhat-release ]; then
    # CentOS/RHEL
    echo "$(cat /etc/redhat-release)"
elif command -v uname >/dev/null 2>&1; then
    # 其他Unix-like系统（FreeBSD/MacOS等）
    echo "$(uname -s) $(uname -r)"
else
    echo "未知系统"
fi

# 2. 检查是否安装 bash
echo -n "🔍 检查是否安装 bash: "
if command -v bash >/dev/null 2>&1; then
    echo "✅ 已安装 ($(bash --version | head -n 1))"
else
    echo "❌ 未安装"
fi

# 3. 检查是否安装 curl
echo -n "🔍 检查是否安装 curl: "
if command -v curl >/dev/null 2>&1; then
    echo "✅ 已安装 ($(curl --version | head -n 1))"
else
    echo "❌ 未安装"
fi

echo "============================="