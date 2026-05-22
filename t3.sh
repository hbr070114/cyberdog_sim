#!/bin/bash
# 终端3: 键盘控制
# 用法: bash /home/fish/cyberdog_sim/t3.sh (需先运行t1和t2)

echo "=== 键盘控制 === Y:站立 B:趴下 W/S:前后 A/D:左右 Q/E:转向 Ctrl+C:退出 ==="

docker exec -it cyberdog_slam bash -c '
source /opt/ros/galactic/setup.bash; source /home/cyberdog_sim/install/setup.bash
pgrep -f "cyberdog_control" > /dev/null && echo "[OK] control运行中" || echo "[WARN] control未运行!"
/home/cyberdog_sim/install/lib/cyberdog_example/keybroad_commander
'