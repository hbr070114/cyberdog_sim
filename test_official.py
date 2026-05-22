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
    print(f"[{time.strftime('%H:%M:%S')}] {desc} mode={mode} gait={gait_id} vel={vel} life={life_count}")

print("=" * 60)
print("[TEST] 官方风格测试 - 模仿 basic_motion/main.py")
print("=" * 60)

# Step 1: RecoveryStand (官方: 只发一次，等完成)
print("\n[1] 发送RecoveryStand...")
send(12, 0, [0,0,0], "RecoveryStand")
time.sleep(8)  # 等待站立完成

# Step 2: Locomotion (官方: 只发一次，持续5秒)
print("\n[2] 发送Locomotion (vel=0.3) - 只发一次，观察5秒...")
send(11, 29, [0.3, 0.0, 0.0], "Locomotion-FORWARD")

print("\n[等待5秒观察运动...]")
for i in range(50):
    time.sleep(0.1)
    if i % 10 == 0:
        print(f"  ... {i/10:.0f}s")

# Step 3: 停止
print("\n[3] 发送PureDamper停止...")
send(7, 0, [0,0,0], "PureDamper-STOP")
time.sleep(2)

print("\n" + "=" * 60)
print("[✓] 测试完成！请观察Gazebo中机器狗是否移动了！")
print("=" * 60)
