#!/bin/bash
# ============================================================
# 🔧 激光雷达修复工具 + 完整启动流程
# 解决：激光雷达不发射射线的问题
# ============================================================

echo "=========================================="
echo "  🔧 CyberDog 激光雷达诊断与修复"
echo "=========================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /home/fish/cyberdog_sim
source /opt/ros/galactic/setup.bash

echo -e "${YELLOW}🔍 正在检查激光雷达配置...${NC}"
echo ""

# 检查1：URDF中的lidar_link
echo "[1/4] 检查URDF中的激光雷达定义..."
LIDAR_COUNT=$(ros2 run xacro xacro src/cyberdog_simulator/cyberdog_robot/cyberdog_description/xacro/robot.xacro USE_LIDAR:=true 2>/dev/null | grep -c "lidar_link" || echo "0")
if [ "$LIDAR_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ URDF包含lidar_link（$LIDAR_COUNT处引用）${NC}"
else
    echo -e "${RED}❌ URDF中没有lidar_link！${NC}"
fi

# 检查2：Gazebo插件
echo ""
echo "[2/4] 检查Gazebo激光雷达插件..."
if [ -f "/opt/ros/galactic/lib/libgazebo_ros_ray_sensor.so" ]; then
    echo -e "${GREEN}✅ 激光雷达插件存在${NC}"
else
    echo -e "${RED}❌ 激光雷达插件缺失${NC}"
    echo "   路径: /opt/ros/galactic/lib/libgazebo_ros_ray_sensor.so"
fi

# 检查3：当前topics
echo ""
echo "[3/4] 检查ROS topics..."
if ros2 topic list 2>/dev/null | grep -q "/scan"; then
    echo -e "${GREEN}✅ 发现 /scan topic${NC}"
    
    # 测试是否有数据
    echo "   测试数据频率..."
    timeout 3 ros2 topic hz /scan 2>&1 | tail -3
    
else
    echo -e "${YELLOW}⚠️  未发现 /scan topic${NC}"
    echo "   原因：Gazebo可能未启动或未使用 use_lidar:=true"
fi

if ros2 topic list 2>/dev/null | grep -q "/imu"; then
    echo -e "${GREEN}✅ 发现 /imu topic${NC}"
fi

echo ""
echo "[4/4] 生成修复方案..."

cat > /tmp/start_gazebo_with_lidar.sh << 'GAZEBOEOF'
#!/bin/bash
echo "📍 启动Gazebo（带激光雷达）..."
echo ""
echo "⚠️  重要：必须使用 use_lidar:=true 参数！"
echo ""

cd /home/fish/cyberdog_sim
source /opt/ros/galactic/setup.bash
source install/setup.bash

echo "正在启动Gazebo..."
echo "请等待15-20秒让仿真完全加载"
echo ""

ros2 launch cyberdog_gazebo race_gazebo.launch.py use_lidar:=true

echo ""
echo "❌ Gazebo已退出"
GAZEBOEOF
chmod +x /tmp/start_gazebo_with_lidar.sh

cat > /tmp/check_lidar.sh << 'CHECKEOF'
#!/bin/bash
echo "🔍 激光雷达状态检查"
echo "======================"
echo ""

source /opt/ros/galactic/setup.bash 2>/dev/null

echo "1. 检查 /scan topic:"
if ros2 topic list 2>/dev/null | grep -q "/scan"; then
    echo "   ✅ /scan 存在"
    echo "   数据频率:"
    timeout 5 ros2 topic hz /scan 2>&1 | grep -E "average|rate|Hz" || echo "   ⚠️  暂无数据流"
else
    echo "   ❌ /scan 不存在"
    echo "   → 请先启动Gazebo并确保使用 use_lidar:=true"
fi

echo ""
echo "2. 检查 /imu topic:"
if ros2 topic list 2>/dev/null | grep -q "/imu"; then
    echo "   ✅ /imu 存在"
else
    echo "   ❌ /imu 不存在"
fi

echo ""
echo "3. 所有topics列表:"
ros2 topic list 2>/dev/null | head -20 || echo "   无活跃topics"

echo ""
echo "💡 如果没有/scan，请执行:"
echo "   bash /tmp/start_gazebo_with_lidar.sh"
CHECKEOF
chmod +x /tmp/check_lidar.sh

echo -e "${GREEN}✅ 诊断完成${NC}"

echo ""
echo "=========================================="
echo "  🎯 问题原因与解决方案"
echo "=========================================="
echo ""
echo -e "${YELLOW}问题:${NC} 激光雷达没有发射射线"
echo ""
echo -e "${YELLOW}最可能的原因:${NC}"
echo "  1. 启动Gazebo时未加 use_lidar:=true 参数"
echo "  2. Gazebo传感器可视化被禁用"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ 解决方案（按顺序执行）${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}步骤1: 重启Gazebo（确保带激光雷达参数）${NC}"
echo ""
echo "  在【终端1】中按 Ctrl+C 停止当前Gazebo"
echo "  然后重新执行:"
echo -e "  ${BLUE}bash /tmp/start_gazebo_with_lidar.sh${NC}"
echo ""
echo -e "${YELLOW}步骤2: 等待Gazebo完全启动后...${NC}"
echo ""
echo "  确认以下现象:"
echo "    ✓ Gazebo窗口弹出"
echo "    ✓ 机器狗趴在地面上"
echo -e "    ✓ ${RED}机器狗头部应该有蓝色/红色射线${NC} ← 激光雷达"
echo ""
echo -e "  ${RED}如果还是看不到射线，继续步骤3${NC}"
echo ""
echo -e "${YELLOW}步骤3: 在Gazebo中手动启用传感器可视化${NC}"
echo ""
echo "  方法A: 菜单操作"
echo "    1. 点击Gazebo窗口顶部菜单: View → Sensors"
echo "    2. 或 View → Sensor Visuals"
echo "    3. 应该能看到激光射线出现"
echo ""
echo "  方法B: 快捷键"
echo "    按 V 键切换传感器可视化"
echo ""
echo "  方法C: 左侧面板"
echo "    在左侧面板找到 'Sensors' 或 'Sensor Visuals'"
echo "    勾选启用"
echo ""
echo -e "${YELLOW}步骤4: 验证激光雷达数据${NC}"
echo ""
echo "  打开新终端，执行:"
echo -e "  ${BLUE}bash /tmp/check_lidar.sh${NC}"
echo ""
echo "  应该看到:"
echo "    ✅ /scan 存在"
echo "    average rate: X.XX Hz  (有频率数值说明有数据)"
echo ""
echo "=========================================="
echo ""
echo -e "${GREEN}💡 关键提示:${NC}"
echo ""
echo "1. use_lidar:=true 参数是必须的！"
echo "   错误: ros2 launch ... race_gazebo.launch.py"
echo "   正确: ros2 launch ... race_gazebo.launch.py use_lidar:=true"
echo "                                                   ^^^^^^^^^^^^^^^^"
echo "                                                   这部分不能少!"
echo ""
echo "2. 激光射线颜色:"
echo "   - 通常为蓝色或红色"
echo "   - 从机器狗头部发出"
echo "   - 扫描周围环境形成扇形"
echo ""
echo "3. 如果Rviz有点云但Gazebo没射线:"
echo "   - 说明激光雷达在工作，只是Gazebo可视化关闭"
echo "   - 不影响SLAM建图功能"
echo "   - 可以用步骤3的方法开启"
echo ""
echo "=========================================="
