#!/usr/bin/env python3
import mmap
import struct
import os

SHM_NAME = "/dev/shm/development-simulator"

def read_shared_memory():
    try:
        with open(SHM_NAME, 'rb') as f:
            data = f.read()
            print(f"[DEBUG] 共享内存大小: {len(data)} bytes")

            if len(data) > 1000:
                # 查找mode字段 (通常在结构体末尾)
                # SimulatorMode是enum class，底层是int (4 bytes)
                # 搜索模式: 在最后200字节查找非零的4字节整数

                last_200 = data[-200:]
                for i in range(0, len(last_200) - 3, 4):
                    val = struct.unpack('<i', last_200[i:i+4])[0]
                    if 0 <= val <= 3:
                        offset = len(data) - 200 + i
                        print(f"[DEBUG] 偏移 {offset}: 可能的mode值 = {val} (0=PARAMS, 1=CONTROL, 2=NOTHING, 3=EXIT)")

                print(f"\n[DEBUG] 最后50字节 (hex): {data[-50:].hex()}")
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == '__main__':
    read_shared_memory()
