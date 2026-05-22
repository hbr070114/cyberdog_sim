#!/bin/bash
set -e
echo "=========================================="
echo "  🚀 一键初始化 (只需运行一次)"
echo "=========================================="
echo ""

docker rm -f cyberdog_slam 2>/dev/null || true

echo "[1/3] 启动容器并安装依赖..."
docker run -itd --name cyberdog_slam --privileged=true \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /home/fish/cyberdog_sim:/home/cyberdog_sim \
  cyberdog_sim:v2026 bash -c "
    apt-get update -qq && apt-get install -y -qq libglog-dev &&
    cd /home/cyberdog_sim/src/Super-LIO-ros2 &&
    source /opt/ros/galactic/setup.bash &&
    colcon build &&
    echo '✅ 初始化完成' &&
    tail -f /dev/null
  "

echo "[2/3] 等待编译完成..."
echo "   (这需要3-5分钟，请耐心等待...)"
echo ""

for i in {1..60}; do
  if docker logs cyberdog_slam 2>&1 | grep -q "✅ 初始化完成"; then
    echo ""
    echo "[3/3] ✅ 全部完成！"
    echo ""
    echo "=========================================="
    echo "  现在打开3个终端，分别执行："
    echo "=========================================="
    echo ""
    echo "  终端1: ./term1.sh"
    echo "  终端2: ./term2.sh"
    echo "  终端3: ./term3.sh"
    echo ""
    exit 0
  fi
  sleep 5
  echo "   等待中... ($i/60)"
done

echo "❌ 超时，请检查: docker logs cyberdog_slam"
