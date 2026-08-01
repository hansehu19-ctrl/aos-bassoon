#!/bin/bash
# AOS Mock VM 启动器 - 物理实体版本
# 用途：后台启动 mock_cat01_server.py，创建 Unix Socket，供 fc_self_test.py 连接

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
MOCK_SERVER="$REPO_ROOT/core/mock/mock_cat01_server.py"
SOCK_PATH="/tmp/aos_ivn_self-test-vm-001.sock"
LOG_FILE="/AOS/logs/mock_vm_startup.log"

# 宪法合规：创建审计目录
mkdir -p "$(dirname "$LOG_FILE")"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] start_mock_vm.sh invoked" >> "$LOG_FILE"

# 物理检查：Mock Server 是否存在
if [[ ! -f "$MOCK_SERVER" ]]; then
    echo "❌ 错误：Mock Server 不存在: $MOCK_SERVER"
    echo "请先创建 core/mock/mock_cat01_server.py"
    exit 1
fi

# 物理检查：Socket 文件是否已存在（清理旧的）
if [[ -S "$SOCK_PATH" ]]; then
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] 清理旧的 Socket: $SOCK_PATH" >> "$LOG_FILE"
    rm -f "$SOCK_PATH"
fi

# 物理检查：Python 与依赖
if ! command -v python3 &> /dev/null; then
    echo "❌ 错误：python3 未安装"
    exit 1
fi

# 启动 Mock VM（后台守护进程）
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] 启动 Mock VM..." >> "$LOG_FILE"
nohup python3 "$MOCK_SERVER" --sock-path "$SOCK_PATH" >> "$LOG_FILE" 2>&1 &

MOCK_PID=$!
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Mock VM PID: $MOCK_PID" >> "$LOG_FILE"

# 物理等待：确认 Socket 文件被创建（最多等 10 秒）
for i in $(seq 1 100); do
    if [[ -S "$SOCK_PATH" ]]; then
        echo "✅ Mock VM 启动成功！Socket: $SOCK_PATH"
        echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Socket created successfully" >> "$LOG_FILE"
        exit 0
    fi
    sleep 0.1
done

# 超时：启动失败
echo "❌ 错误：Mock VM 启动超时（10秒未创建 Socket）"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: Socket creation timeout" >> "$LOG_FILE"
kill "$MOCK_PID" 2>/dev/null || true
exit 1
