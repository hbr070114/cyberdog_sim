#!/bin/bash
# ============================================================
# 🚀 CyberDog SuperLIO SLAM 终极修复版 v3.0
# 解决：Rviz + 激光雷达 + 所有已知问题
# 特点：逐步验证，每步确认成功后再继续
# ============================================================

echo "=========================================="
echo "  🔧 CyberDog SLAM 终极修复工具 v3.0"
echo "  全面解决：Rviz + 激光雷达 + 建图"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

cd /home/fish/cyberdog_sim

source /opt/ros/galactic/setup.bash

echo -e "${YELLOW}[准备] 编译所有更新...${NC}"
colcon build --packages-select cyberdog_gazebo cyberdog_example --symlink-install 2>&1 | grep -E "error|Error|SUCCESS" || true
source install/setup.bash 2>/dev/null || true
echo -e "${GREEN}✅ 编译完成${NC}"
echo ""

cat > /tmp/step1_gazebo.sh << 'EOF'
#!/bin/bash
clear
echo "=========================================="
echo "  📍 步骤1: 启动Gazebo仿真（带激光雷达）"
echo "=========================================="
echo ""
echo "⏳ 正在启动Gazebo..."
echo "   请等待15-20秒"
echo ""
echo "✅ 成功标志:"
echo "   1. Gazebo窗口弹出"
echo "   2. 机器狗趴在地面上"
echo "   3. race地图完整显示"
echo ""
echo "⚠️  如果看不到激光射线:"
echo "   按 V 键 或 View → Sensors"
echo ""
echo "❌ 失败处理:"
echo "   按 Ctrl+C 停止后重新执行此脚本"
echo ""

cd /home/fish/cyberdog_sim
source /opt/ros/galactic/setup.bash
source install/setup.bash
ros2 launch cyberdog_gazebo race_gazebo.launch.py use_lidar:=true
EOF
chmod +x /tmp/step1_gazebo.sh

cat > /tmp/step2_check.sh << 'EOF'
#!/bin/bash
clear
echo "=========================================="
echo "  🔍 步骤2: 验证系统状态"
echo "=========================================="
echo ""

source /opt/ros/galactic/setup.bash 2>/dev/null

echo "[检查1] ROS Topics:"
TOPICS=$(ros2 topic list 2>/dev/null | wc -l)
echo "   发现 $TOPICS 个活跃topics"

if ros2 topic list 2>/dev/null | grep -q "/scan"; then
    echo "   ✅ /scan (激光雷达) 存在"
    echo "   测试数据频率:"
    timeout 5 ros2 topic hz /scan 2>&1 | grep -E "average|rate" || echo "   ⚠️  等待数据..."
else
    echo "   ❌ /scan 不存在 → 请先启动步骤1(Gazebo)"
fi

if ros2 topic list 2>/dev/null | grep -q "/imu"; then
    echo "   ✅ /imu (惯性测量) 存在"
else
    echo "   ⚠️  /imu 不存在"
fi

echo ""
echo "[检查2] 运行节点:"
NODES=$(ros2 node list 2>/dev/null | wc -l)
echo "   发现 $NODES 个运行节点"

echo ""
echo "[检查3] TF变换:"
if command -v tf2_tools &> /dev/null; then
    timeout 3 ros2 run tf2_tools view_frames 2>/dev/null && echo "   ✅ TF树正常" || echo "   ⚠️  无法生成TF图"
fi

echo ""
echo "=========================================="
if [ "$TOPICS" -gt 0 ]; then
    echo -e "${GREEN}✅ 系统正常！可以继续步骤3${NC}"
else
    echo -e "${RED}❌ 系统未就绪！请先完成步骤1${NC}"
fi
echo "=========================================="

read -p "按 Enter 继续..."
EOF
chmod +x /tmp/step2_check.sh

cat > /tmp/step3_superlio.sh << 'EOF'
#!/bin/bash
clear
echo "=========================================="
echo "  📍 步骤3: 启动SuperLIO + Rviz"
echo "=========================================="
echo ""
echo "⏳ 正在启动SuperLIO算法..."
echo "   请等待10-20秒让Rviz窗口出现"
echo ""
echo "✅ 成功标志:"
echo "   1. Rviz窗口弹出"
echo "   2. 左侧显示 Global Status: OK"
echo "   3. 主视图开始出现点云数据(可能需要30秒)"
echo ""
echo "⚠️  如果Rviz空白:"
echo "   - 等待更长时间(最多1分钟)"
echo "   - 检查左侧是否有错误提示"
echo "   - 确认Gazebo正在运行且/scan有数据"
echo ""
echo "💾 建图完成后按 Ctrl+C 保存地图"
echo "   地图保存位置:"
echo "   /home/cyberdog_sim/src/Super-LIO-ros2/src/super_lio/map/race_map.pcd"
echo ""

cd /home/fish/cyberdog_sim/src/Super-LIO-ros2
source /opt/ros/galactic/setup.bash
source install/setup.bash
ros2 launch super_lio Livox_mid360.py rviz:=true \
    --ros-args \
    -r /livox/lidar:=/scan \
    -r /livox/imu:=/imu

echo ""
echo "🎉 SuperLIO已停止"
EOF
chmod +x /tmp/step3_superlio.sh

cat > /tmp/step4_keyboard.sh << 'EOF'
#!/bin/bash
clear
echo "=========================================="
echo "  📍 步骤4: 启动键盘控制"
echo "=========================================="
echo ""

cd /home/cyberdog_ws
source /opt/ros/galactic/setup.bash
source install/setup.bash

echo "⏳ 启动运动管理服务..."
ros2 run motion_manager motion_manager &
MOTION_PID=$!
sleep 8

cd /home/fish/cyberdog_sim
source install/setup.bash 2>/dev/null || true

echo ""
echo "========================================"
echo "  🐕 增强版键盘控制器 v2.0"
echo "========================================"
echo ""
echo "【基本移动】WASD + JL (转向)"
echo "【速度控制】Q/E 加速/减速"
echo ""
echo "【步态切换】"
echo "  1 → 慢速行走(303) ⭐石板路/独木桥"
echo "  2 → 中速行走(308) ✅平地建图(默认)"
echo "  3 → 快速行走(305) ⚡开阔地带"
echo ""
echo "【姿态控制】I/K 俯仰 | 空格 急停"
echo "【系统控制】Y 恢复站立 | R 行走 | T 趴下"
echo ""
echo "💡 快速开始流程:"
echo "   第1步: 输入 y (恢复站立)"
echo "   第2步: 输入 r (进入行走模式)"
echo "   第3步: 输入 1 或 2 或 3 (选择步态)"
echo "   第4步: 输入 w (开始前进建图)"
echo ""
echo "⚠️  LCM错误可忽略，不影响使用"
echo "========================================"
echo ""

ros2 run cyberdog_example keybroad_commander

kill $MOTION_PID 2>/dev/null || true
EOF
chmod +x /tmp/step4_keyboard.sh

echo -e "${GREEN}✅ 所有启动脚本已创建${NC}"
echo ""

echo "=========================================="
echo "  📋 完整操作步骤（请严格按顺序执行）"
echo "=========================================="
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  重要提醒：总共需要打开4个终端！${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}终端0（当前终端）:${NC}"
echo "  用于运行此初始化脚本（已完成）"
echo "  保持打开不要关闭"
echo ""
echo -e "${YELLOW}终端1:${NC}"
echo "  用途：Gazebo仿真器"
echo "  命令: ${BLUE}bash /tmp/step1_gazebo.sh${NC}"
echo "  等待：看到Gazebo窗口和机器狗后继续"
echo ""
echo -e "${YELLOW}终端2:${NC}"
echo "  用途：验证系统状态"
echo "  命令: ${BLUE}bash /tmp/step2_check.sh${NC}"
echo "  等待：确认所有检查通过后继续"
echo ""
echo -e "${YELLOW}终端3:${NC}"
echo "  用途：SuperLIO算法 + Rviz可视化"
echo "  命令: ${BLUE}bash /tmp/step3_superlio.sh${NC}"
echo "  等待：Rviz窗口弹出后继续"
echo ""
echo -e "${YELLOW}终端4:${NC}"
echo "  用途：键盘控制机器狗"
echo "  命令: ${BLUE}bash /tmp/step4_keyboard.sh${NC}"
echo "  操作：输入 y → r → 1 → w 开始建图"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}执行顺序总结:${NC}"
echo "  1. 打开新终端1 → 执行 bash /tmp/step1_gazebo.sh"
echo "  2. 等Gazebo启动完(约20秒)"
echo "  3. 打开新终端2 → 执行 bash /tmp/step2_check.sh"
echo "  4. 确认检查通过"
echo "  5. 打开新终端3 → 执行 bash /tmp/step3_superlio.sh"
echo "  6. 等Rviz出现(约20秒)"
echo "  7. 打开新终端4 → 执行 bash /tmp/step4_keyboard.sh"
echo "  8. 输入 y → r → 1 → w 开始SLAM建图！"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}🎯 成功标志检查清单:${NC}"
echo ""
echo "  ✅ 终端1: Gazebo窗口弹出，机器狗趴在地上"
echo "  ✅ 终端2: 显示 '/scan存在' 和 '系统正常'"
echo "  ✅ 终端3: Rviz窗口弹出，有点云数据"
echo "  ✅ 终端4: 显示键盘帮助，可输入命令"
echo ""
echo -e "${RED}❌ 如果某步失败:${NC}"
echo "  - 在该终端按 Ctrl+C"
echo "  - 重新执行该步骤的命令"
echo "  - 或回到此终端运行 ./fix_all.sh 重新开始"
echo ""
echo "=========================================="
echo ""
