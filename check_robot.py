#!/usr/bin/env python3
import struct
import sys

SHM_NAME = "/dev/shm/development-simulator"

def read_robot_position():
    try:
        with open(SHM_NAME, 'rb') as f:
            data = f.read()

            # SimulatorToRobotMessage结构:
            # - GamepadCommand (前面部分)
            # - RobotType (int)
            # - VectorNavData (IMU数据)
            # - CheaterState (机器人位姿)
            # - SpiData (关节数据)
            # - ControlParameterRequest
            # - SimulatorMode mode (最后4字节)

            # CheaterState包含position和orientation
            # 位置是Vec3<double> (24 bytes: 3个double)
            # 四元数是Quat<double> (32 bytes: 4个double)

            # 从共享内存读取cheaterState的位置信息
            # 假设cheaterState在结构体中间偏后的位置
            # 我们需要找到模式1出现前的位置数据

            print("=" * 60)
            print("[机器人状态检测]")
            print("=" * 60)

            # 搜索mode=1的位置，然后往回找位置数据
            for i in range(len(data) - 200, 100, -4):
                val = struct.unpack('<i', data[i:i+4])[0]
                if val == 1:  # 找到kRunContorller
                    # 往回读约200-300字节应该是CheaterState
                    pos_offset = i - 200  # 估计位置

                    if pos_offset > 0 and pos_offset + 24 < len(data):
                        pos = struct.unpack('<ddd', data[pos_offset:pos_offset+24])
                        quat = struct.unpack('<dddd', data[pos_offset+24:pos_offset+56])

                        print(f"\n[✓] 检测到控制循环运行中 (mode=1)")
                        print(f"\n[机器人位置]")
                        print(f"  X: {pos[0]:.3f} m")
                        print(f"  Y: {pos[1]:.3f} m")
                        print(f"  Z: {pos[2]:.3f} m")
                        print(f"\n[机器人姿态 (四元数)]")
                        print(f"  W: {quat[0]:.3f}")
                        print(f"  X: {quat[1]:.3f}")
                        print(f"  Y: {quat[2]:.3f}")
                        print(f"  Z: {quat[3]:.3f}")

                        # 判断是否穿模
                        if pos[2] < 0.25:
                            print(f"\n[⚠️ 警告] 机器人可能穿模! Z={pos[2]:.3f}m < 0.25m")
                        elif pos[2] > 0.5:
                            print(f"\n[⚠️ 警告] 机器人可能飘空! Z={pos[2]:.3f}m > 0.5m")
                        else:
                            print(f"\n[✓] 正常: 机器人在地面上 (Z={pos[2]:.3f}m)")

                        return

            print("[⏳] 等待控制循环启动...")
            print(f"[INFO] 共享内存大小: {len(data)} bytes")

    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == '__main__':
    read_robot_position()
