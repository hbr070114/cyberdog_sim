#!/usr/bin/env python3
import sys, time
sys.path.insert(0, '/home/cyberdog_sim/src/cyberdog_locomotion/common/lcm_type/lcm')

import lcm
from robot_control_cmd_lcmt import robot_control_cmd_lcmt

lc = lcm.LCM("udpm://239.255.76.67:7671?ttl=255")
msg = robot_control_cmd_lcmt()
life_count = 0

def send(mode, gait_id=0, vel=[0,0,0], desc=""):
    global life_count
    life_count = (life_count + 1) % 127
    msg.mode = mode
    msg.gait_id = gait_id
    msg.vel_des = [float(vel[0]), float(vel[1]), float(vel[2])]
    msg.pos_des = [0.0, 0.0, 0.0]
    msg.step_height = [0.06, 0.06] if mode == 11 else [0.0, 0.0]
    msg.duration = 0
    msg.life_count = life_count
    lc.publish("robot_control_cmd", msg.encode())
    print(f"[{time.strftime('%H:%M:%S')}] {desc}")

print("=" * 60)
print("[完整测试] RecoveryStand + Locomotion(gait=10)")
print("=" * 60)

# Step 1: RecoveryStand
print("\n[1/3] RecoveryStand (等待8秒)...")
send(12, 0, [0,0,0], "RecoveryStand")
for i in range(16):
    time.sleep(0.5)
    send(12, 0, [0,0,0], "Maintain-RecoveryStand")

# Step 2: Locomotion - 持续发送10秒
print("\n[2/3] Locomotion gait=10 vel=0.1 (持续10秒)...")
send(11, 10, [0.1, 0.0, 0.0], "Locomotion-START")
for i in range(100):
    time.sleep(0.1)
    send(11, 10, [0.1, 0.0, 0.0], f"Loco-v0.1-{i}")
    if i % 20 == 19:
        print(f"  ... 已运行 {(i+1)/10:.1f}秒")

# Step 3: 停止
print("\n[3/3] PureDamper (停止)...")
send(7, 0, [0,0,0], "PureDamper-STOP")
time.sleep(2)

# 检查结果
import subprocess
result = subprocess.run(['pgrep', '-f', 'cyberdog_control'], capture_output=True, text=True)
print("\n" + "=" * 60)
if result.stdout.strip():
    print("[✓] Control进程存活！测试成功！")
else:
    print("[✗] Control崩溃了！")
print("=" * 60)
print("请观察Gazebo：机器狗是否前进了？")
