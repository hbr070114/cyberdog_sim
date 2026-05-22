#!/usr/bin/env python3
import sys
sys.path.insert(0, '/home/cyberdog_sim/src/cyberdog_locomotion/common/lcm_type/lcm')

import lcm
import time
from robot_control_cmd_lcmt import robot_control_cmd_lcmt

lc = lcm.LCM("udpm://239.255.76.67:7671?ttl=255")

msg = robot_control_cmd_lcmt()
msg.mode = 12  # RecoveryStand
msg.gait_id = 29
msg.vel_des = [0.0, 0.0, 0.0]
msg.pos_des = [0.0, 0.0, 0.24]
msg.step_height = [0.06, 0.06]
msg.life_count = 1

print("=" * 60)
print("[TEST] 阶段1: 发送站立命令 (RecoveryStand)")
print("=" * 60)
for i in range(30):
    msg.life_count = (msg.life_count + 1) % 128
    lc.publish("robot_control_cmd", msg.encode())
    time.sleep(0.1)

print("\n[TEST] 等待3秒让机器狗站起来...")
time.sleep(3)

print("\n" + "=" * 60)
print("[TEST] 阶段2: 发送前进命令 (Locomotion v=0.3 m/s)")
print("=" * 60)
msg.mode = 11  # Locomotion
msg.vel_des = [0.3, 0.0, 0.0]
msg.life_count = (msg.life_count + 1) % 128

for i in range(100):
    msg.life_count = (msg.life_count + 1) % 128
    lc.publish("robot_control_cmd", msg.encode())
    time.sleep(0.1)

print("\n[TEST] 等待5秒观察运动...")
time.sleep(5)

print("\n" + "=" * 60)
print("[TEST] 阶段3: 停止命令")
print("=" * 60)
msg.vel_des = [0.0, 0.0, 0.0]
msg.life_count = (msg.life_count + 1) % 128

for i in range(20):
    msg.life_count = (msg.life_count + 1) % 128
    lc.publish("robot_control_cmd", msg.encode())
    time.sleep(0.1)

print("\n" + "=" * 60)
print("[✓] 测试完成！")
print("[请检查Gazebo窗口]")
print("  - 机器狗是否站起来了？")
print("  - 机器狗是否向前移动了？")
print("=" * 60)
