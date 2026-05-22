# CyberDog 四足机器人 SLAM 建图操作指南

> 环境：ROS2 Galactic | Docker容器(cyberdog_slam) | Gazebo 11 | Super-LIO
> 仿真工作空间：`/home/cyberdog_sim`
> Super-LIO位置：`/home/cyberdog_sim/src/Super-LIO-ros2`

---

## 目录

- [0. 启动前准备](#0-启动前准备)
- [1. 终端1：Gazebo仿真 + 激光雷达](#1-终端1gazebo仿真--激光雷达)
- [2. 终端2：cyberdog_control + SuperLIO建图 + RViz](#2-终端2cyberdog_control--superlio建图--rviz)
- [3. 终端3：键盘控制](#3-终端3键盘控制)
- [4. 建图最佳实践](#4-建图最佳实践)
- [5. 保存地图](#5-保存地图)
- [6. 常见问题排查](#6-常见问题排查)

---

## 0. 启动前准备

### 0.1 主机执行（只需一次）

```bash
xhost +local:docker
```
> 作用：允许Docker容器访问X11图形界面

### 0.2 清理残留进程

在**主机终端**执行：

```bash
killall -9 gazebo gzserver gzclient cyberdog_control 2>/dev/null
sleep 2
```

确认无残留：

```bash
ps aux | grep -E "gzserver|gzclient|cyberdog_control" | grep -v grep
```

预期输出：**空**（无任何进程）

### 0.3 清理共享内存（重要！）

```bash
docker exec cyberdog_slam bash -c 'rm -f /dev/shm/*'
```

> 作用：清除旧的共享内存文件，防止Gazebo启动时因旧数据冲突而崩溃

### 0.4 确认编译状态

```bash
docker exec cyberdog_slam bash -c '
echo "=== cyberdog_sim ==="
ls /home/cyberdog_sim/install/lib/cyberdog_locomotion/cyberdog_control 2>/dev/null && echo "  ✅ cyberdog_control OK" || echo "  ❌ 缺少cyberdog_control"

echo "=== keybroad_commander ==="
ls /home/cyberdog_sim/install/lib/cyberdog_example/keybroad_commander 2>/dev/null && echo "  ✅ keybroad_commander OK" || echo "  ❌ 缺少keybroad_commander"

echo "=== SuperLIO ==="
ls /home/cyberdog_sim/src/Super-LIO-ros2/install/lib/super_lio/super_lio_node 2>/dev/null && echo "  ✅ SuperLIO OK" || echo "  ❌ SuperLIO未编译"
'
```

全部显示 ✅ 才可继续。如有 ❌ 需要先编译：

```bash
# 编译cyberdog_sim（如需）
docker exec cyberdog_slam bash -c '
cd /home/cyberdog_sim
source /opt/ros/galactic/setup.bash
colcon build --packages-select cyberdog_locomotion cyberdog_gazebo cyberdog_description cyberdog_example --symlink-install
'

# 编译SuperLIO（如需）
docker exec cyberdog_slam bash -c '
cd /home/cyberdog_sim/src/Super-LIO-ros2
source /opt/ros/galactic/setup.bash
colcon build
'
```

### 0.5 数据流架构总览

```
┌─────────────────────┐   /velodyne_points(PointCloud2)   ┌──────────────────┐
│                     │ ─────────────────────────────────→ │                  │
│   Gazebo (终端1)     │   /imu (IMU)                      │  SuperLIO (终端2) │
│   仿真+激光雷达      │ ─────────────────────────────────→ │  SLAM建图算法    │
│                     │                                    │                  │
└────────┬────────────┘                                    └────────┬─────────┘
         │ 共享内存                                                  │ /lio/cloud_world
         │                                                           │ /lio/odom + TF(world→imu)
         ▼                                                           ▼
┌─────────────────────┐                                    ┌──────────────────┐
│  cyberdog_control   │                                    │     RViz          │
│  (终端2后台启动)     │                                    │   点云地图可视化    │
│                     │                                    └──────────────────┘
▲        │
│   LCM   │ robot_control_cmd
│ (udpm://239.255.76.67:7671)
│         │
┌────────┴─────────────┐
│  keybroad_commander   │
│  (终端3 键盘控制)      │
└──────────────────────┘
```

---

## 1. 终端1：Gazebo仿真 + 激光雷达

### 启动命令

打开**第1个终端窗口**，依次执行：

```bash
docker exec -it cyberdog_slam bash
```

进入容器后执行：

```bash
export DISPLAY=:0
export XAUTHORITY=/run/user/1000/gdm/Xauthority
export GAZEBO_PLUGIN_PATH=/home/cyberdog_sim/build/cyberdog_gazebo:/home/cyberdog_sim/install/lib:$GAZEBO_PLUGIN_PATH
export LD_LIBRARY_PATH=/home/cyberdog_sim/build/cyberdog_locomotion/simbridge:/home/cyberdog_sim/build/cyberdog_locomotion/control:/home/cyberdog_sim/build/cyberdog_locomotion/common:/home/cyberdog_sim/install/lib:$LD_LIBRARY_PATH
export LIBGL_ALWAYS_SOFTWARE=1
mkdir -p /tmp/runtime-root
cd /home/cyberdog_sim
source /opt/ros/galactic/setup.bash
source install/setup.bash
ros2 launch cyberdog_gazebo race_gazebo.launch.py use_lidar:=true headless:=false
```

| 命令段 | 作用 |
|--------|------|
| `DISPLAY=:0` | 指定X11显示器 |
| `XAUTHORITY=...` | X11认证文件路径 |
| `GAZEBO_PLUGIN_PATH=...` | Gazebo插件搜索路径（liblegged_plugin.so） |
| `LD_LIBRARY_PATH=...` | 动态库搜索路径（libsimbridge.so等） |
| `LIBGL_ALWAYS_SOFTWARE=1` | 使用MESA软件渲染（Docker内必需） |
| `use_lidar:=true` | **启用激光雷达传感器** |
| `headless:=false` | **启用图形化Gazebo窗口** |

### 预期结果

- Gazebo 图形窗口弹出
- CyberDog 机器狗出现在赛道中
- 控制台输出类似：
  ```
  [INFO] [gzserver-1]: process started with pid [xxxx]
  [INFO] [gzclient-2]: process started with pid [xxxx]
  [spawn_entity-3]: process has finished cleanly [pid xxxx]
  [Simulation] Success! the robot is alive
  ```

### 验证1：激光雷达数据

**新开一个临时终端**（或等终端2启动后在终端2中）执行：

```bash
docker exec -it cyberdog_slam bash -c '
source /opt/ros/galactic/setup.bash
echo "=== 所有活跃话题 ==="
ros2 topic list | grep -E "scan|lidar|velodyne|imu"
echo ""
echo "=== 检查激光雷达话题 ==="
timeout 5 ros2 topic hz /velodyne_points 2>&1 || echo "(超时或无数据)"
'
```

预期输出：
```
/velodyne_points
/imu
...
average rate: 10.000 min: 10.000 Hz max: 10.000 Hz std dev: 0.00000 Hz window: 10
```

> ⚠️ **注意**：Gazebo 的激光雷达发布的是 **`/velodyne_points`**（PointCloud2 格式），不是 `/scan`（LaserScan）。这是由 [gazebo.xacro](src/cyberdog_simulator/cyberdog_robot/cyberdog_description/xacro/gazebo.xacro) 中 `libgazebo_ros_velodyne_laser.so` 插件决定的。

### 验证2：查看激光雷达原始数据

```bash
docker exec cyberdog_slam bash -c '
source /opt/ros/galactic/setup.bash
ros2 topic echo /velodyne_points --once
' | head -30
```

预期输出：看到 `width: xxx` 和点云坐标数据（x, y, z, intensity 字段）

### 验证3：IMU 数据

```bash
docker exec cyberdog_slam bash -c '
source /opt/ros/galactic/setup.bash
ros2 topic echo /imu --once
'
```

预期输出：看到 `orientation`、`angular_velocity`、`linear_acceleration` 字段

### 如果Gazebo启动失败

**错误现象**：`No protocol specified`、`Aborted (core dumped)`、进程立即退出

**排查与修复**：

```bash
# 1. 确认xhost已执行
xhost +local:docker

# 2. 在主机彻底清理
killall -9 gzserver gzclient 2>/dev/null
rm -rf /tmp/gazebo-* /tmp/.gz* ~/.gazebo/* 2>/dev/null

# 3. 清理容器内共享内存
docker exec cyberdog_slam bash -c 'rm -f /dev/shm/*'

# 4. 杀掉僵尸进程
ps aux | grep -E "defunct.*gz" | awk "{print \$2}" | xargs kill -9 2>/dev/null

# 5. 重新启动终端1
# 回到终端1，重新执行上面的启动命令
```

---

## 2. 终端2：cyberdog_control + SuperLIO建图 + RViz

⚠️ **必须等终端1的Gazebo完全加载（看到机器狗出现在场景中）后再执行此步骤**

### 启动命令

打开**第2个终端窗口**，依次执行：

#### 第1步：进入容器

```bash
docker exec -it cyberdog_slam bash
```

#### 第2步：设置环境变量并启动 cyberdog_control

```bash
export DISPLAY=:0
export XAUTHORITY=/run/user/1000/gdm/Xauthority
export LD_LIBRARY_PATH=/home/fish/cyberdog_sim/build/cyberdog_locomotion/simbridge:/home/fish/cyberdog_sim/build/cyberdog_locomotion/control:/home/fish/cyberdog_sim/build/cyberdog_locomotion/common:/home/fish/cyberdog_sim/install/lib:$LD_LIBRARY_PATH
cd /home/fish/cyberdog_sim
source /opt/ros/galactic/setup.bash
source install/setup.bash
```

> 以上为环境准备，以下为核心启动命令

#### 第3步：启动 cyberdog_control（键盘控制的依赖）

```bash
./install/lib/cyberdog_locomotion/cyberdog_control m s > logs/control.log 2>&1 &
```

| 参数 | 作用 |
|------|------|
| `m` | RobotType = MINI CYBERDOG (cyberdog2) |
| `s` | 从网络加载参数（读取robot-defaults.yaml） |
| `> logs/control.log 2>&1 &` | 后台运行，日志写入文件 |

等待5秒后验证：

```bash
pgrep -x cyberdog_control && echo "✅ cyberdog_control 运行中" || echo "❌ 未运行"
```

如果未运行，检查日志：

```bash
tail -30 logs/control.log
```

#### 第4步：启动 SuperLIO SLAM + RViz

```bash
cd /home/fish/cyberdog_sim/src/Super-LIO-ros2
source install/setup.bash
ros2 launch super_lio hesai.py rviz:=true \
  --ros-args \
  -r /hesai_front/pandar:=/velodyne_points \
  -r /imu/data:=/imu
```

| 参数 | 作用 |
|------|------|
| `hesai.py` | 使用Hesai配置模板（支持标准PointCloud2输入） |
| `rviz:=true` | 同时启动RViz可视化窗口 |
| `-r /hesai_front/pandar:=/velodyne_points` | **将SuperLIO的激光话题重映射到Gazebo实际发布的`/velodyne_points`** |
| `-r /imu/data:=/imu` | 将SuperLIO的IMU话题重映射到Gazebo的`/imu` |

### SuperLIO 配置说明

当前使用的配置文件：[livox_360.yaml](src/Super-LIO-ros2/src/super_lio/config/livox_360.yaml)

关键参数（已按建图需求预配置）：

```yaml
lio.ros.lidar_topic: "/velodyne_points"    # 激光雷达话题（通过-r重映射覆盖）
lio.ros.imu_topic: "/imu"                 # IMU话题（通过-r重映射覆盖）

lio.sensor.lidar_type: 4                   # VELO32类型（匹配Velodyne PointCloud2格式）
lio.sensor.blind: 2.0                       # 盲区距离(m)
lio.sensor.maxrange: 60.0                   # 最大探测距离(m)
lio.sensor.voxel_fliter_size: 0.5           # 体素滤波尺寸(m)
lio.sensor.gravity_norm: 9.7946            # 重力加速度
lio.sensor.imu_type: 1                     # IMU类型

lio.extrinsic.lidar_imu: [-0.011,-0.02329,0.04412, 1,0,0, 0,1,0, 0,0,1]
                                           # 激光雷达到IMU的外参(平移+旋转)

lio.kf.kf_align_gravity: true              # 重力对齐(推荐开启)

lio.output.map: true                       # 输出全局地图点云
lio.output.dense: true                     # 输出稠密点云
lio.output.pub_step: 1                     # 发布频率(每N帧发布一次)

lio.map.save_map: true                     # 自动保存地图
lio.map.save_map_dir: "map"                # 保存目录(相对于包目录)
lio.map.map_name: "race_map.pcd"           # 地图文件名
lio.map.ds_size: 0.15                      # 下采样网格尺寸(m)
lio.map.save_interval: 300                 # 自动保存间隔(帧数)
```

> ⚠️ 关于 `lidar_type`：用户要求设为1（LIVOX），但Gazebo输出的是Velodyne格式的PointCloud2。SuperLIO对LIVOX类型订阅的是`livox_ros_driver2::msg::CustomMsg`，无法解析标准PointCloud2。因此必须使用 **`lidar_type: 3`(VELO16) 或 `4`(VELO32)**。

### 预期结果

- RViz 窗口弹出
- 控制台输出：
  ```
  ---> Using Lidar type: VELO32
  ---> [Param] map/save_map: true
  ```
- RViz 中逐渐出现**彩色3D点云**

### 验证方法

#### 验证1：SuperLIO 节点状态

```bash
docker exec cyberdog_slam bash -c '
source /opt/ros/galactic/setup.bash
source /home/fish/cyberdog_sim/src/Super-LIO-ros2/install/setup.bash
ros2 node list | grep super_lio
'
```

预期输出：`/super_lio_node`

#### 验证2：检查 /lio/cloud_world 话题

```bash
docker exec cyberdog_slam bash -c '
source /opt/ros/galactic/setup.bash
timeout 8 ros2 topic echo /lio/cloud_world --once 2>&1 | grep -E "width|height|frame_id"
'
```

预期输出：
```
width: xxxx
height: 1
frame_id: world
```

如果有数据则建图正常；如果一直超时无输出，说明激光雷达数据未正确传入SuperLIO。

#### 验证3：RViz 显示检查

在RViz窗口中确认：
1. **Global Options → Fixed Frame** = `world`
2. 左下角 **Status** 全部绿色（无红色报错）
3. **TF** 树正常：`world → imu → ... → base_link`
4. 能看到彩色3D点云

#### 验证4：黄线碰撞体检测

在RViz中观察赛道边缘是否有一条清晰的**点云线条**沿黄线分布。
- 如果能看到 → 黄线碰撞体生效 ✅
- 如果看不到但其他物体有点云 → 可能黄线距离较远或高度不对，可移动机器人靠近观察

### 如果看不到全局点云地图

按顺序排查：

**步骤1：检查 Fixed Frame**

RViz 左侧面板 → Global Options → Fixed Frame 设为 `world`（不是 `map` 或 `odom`）

**步骤2：检查 Topic 名称**

RViz 中添加 PointCloud2 显示项：
- By topic → 选择 `/lio/cloud_world`（不是 `/io/cloud_world`）
- 注意：是 `cloud_world` 带 `l-i-o` 前缀

**步骤3：检查 TF 树**

```bash
docker exec cyberdog_slam bash -c '
source /opt/ros/galactic/setup.bash
ros2 run tf2_tools view_frames
'
```

生成 `frames.pdf`，确认 `world → imu` TF 存在且持续更新。

**步骤4：检查激光雷达话题重映射**

```bash
docker exec cyberdog_slam bash -c '
source /opt/ros/galactic/setup.bash
ros2 topic list | grep -E "velodyne|pandar|lidar"
'
```

确认 `/velodyne_points` 存在且有数据。如果 SuperLIO 订阅的是错误的话题名，调整 `-r` 重映射参数。

**步骤5：检查 lidar_type 是否匹配**

SuperLIO 控制台输出的 `Using Lidar type:` 必须是非 LIVOX 类型（VELO16/VELO32 等），否则无法解析 PointCloud2。

---

## 3. 终端3：键盘控制

⚠️ **必须先完成终端1和终端2，且 cyberdog_control 正在运行**

### 3.1 motion_manager 调查结果

```bash
find /home/fish/cyberdog_sim -name "*motion_manager*" 2>/dev/null
find /home/fish -maxdepth 4 -name "*motion_manager*" 2>/dev/null
```

**结论：motion_manager 在当前系统中不存在。**

替代方案：使用项目自带的 `keybroad_commander`，它通过 **LCM 协议** 直接向 `cyberdog_control` 发送控制指令（不依赖 `/cmd_vel` 话题）。

### 启动命令

打开**第3个终端窗口**，依次执行：

```bash
docker exec -it cyberdog_slam bash
```

进入容器后执行：

```bash
cd /home/fish/cyberdog_sim
source /opt/ros/galactic/setup.bash
source install/setup.bash
./install/lib/cyberdog_example/keybroad_commander
```

### 键盘控制对照表

| 按键 | 功能 | 说明 |
|------|------|------|
| **Y** | 恢复站立 | RecoveryStand → QPStand |
| **B** | 趴下 | PureDamper（低功耗模式） |
| **W** | 前进加速 | 每次增加 0.02 m/s，最大 0.5 m/s |
| **S** | 后退减速 | 每次减少 0.02 m/s |
| **A** | 左移加速 | 横向速度 |
| **D** | 右移减速 | 横向速度 |
| **Q** | 左转加速 | 角速度 |
| **E** | 右转减速 | 角速度 |
| **Ctrl+C** | 退出 | 安全停止 |

### 操作流程（首次使用）

```
1. 按 Y → 机器狗从趴下状态恢复站立（约3秒）
2. 等待出现 [CMD] Locomotion 提示后
3. 按 W/S/A/D/Q/E 控制移动
4. 按 B 可随时让机器狗趴下
```

### 通信链路说明

```
按键输入 → keybroad_commander
         ↓ LCM (udpm://239.255.76.67:7671)
         ↓ channel: "robot_control_cmd"
         ↓ 消息类型: robot_control_cmd_lcmt
    cyberdog_control (接收LCM指令)
         ↓ 共享内存 (/dev/shm/development-simulator)
    Gazebo legged_plugin (驱动机器人关节)
```

> 这意味着：**cyberdog_control 必须在运行中**，否则键盘指令无人接收。

### 建图推荐速度

| 参数 | 建图推荐值 | 最大值 |
|------|-----------|--------|
| 前进线速度 | **0.08 ~ 0.12 m/s** | 0.5 m/s |
| 横向线速度 | **0.05 ~ 0.08 m/s** | 0.5 m/s |
| 转向角速度 | **0.2 ~ 0.35 rad/s** | 0.5 rad/s |

> 按 W 一次增加 0.02 m/s，所以建图时按 **4~6 次 W** 即可达到推荐速度。不要连续按太多！

### 速度调整方法

- **加速**：重复按 W（前进）/ A（左移）/ Q（左转）
- **减速**：按 S（后退）/ D（右移）/ E（右转）
- **归零**：按 B 趴下后重新按 Y 站立，速度归零
- **急停**：Ctrl+C 退出程序（会发送 PureDamper 指令让机器狗安全趴下）

### 如果键盘控制无效

#### 排查1：cyberdog_control 是否在运行

```bash
docker exec cyberdog_slam bash -c 'pgrep -a cyberdog_control'
```

预期输出：显示 PID 和路径。如果没有输出 → **回到终端2重新启动 cyberdog_control**

#### 排查2：LCM 通信是否正常

```bash
docker exec cyberdog_slam bash -c '
source /opt/ros/galactic/setup.bash
cd /home/fish/cyberdog_sim
source install/setup.bash
# 检查LCM是否能创建
python3 -c "
import lcm
lc = lcm.LCM(\"udpm://239.255.76.67:7671?ttl=255\")
print(\"LCM OK\" if lc.good() else \"LCM FAIL\")
" 2>&1
'
```

#### 排查3：检查 control 日志是否有收到指令

终端3操作按键后，在另一个终端查看：

```bash
docker exec cyberdog_slam bash -c 'tail -5 /home/fish/cyberdog_sim/logs/control.log | grep -E "Push command|GamepadCmd|life_count"'
```

如果看到 `Push command` 行且数值在变化 → LCM通信正常，问题在控制层
如果只有 `GamepadCmd` 全零 → LCM指令未送达

#### 应急方案：直接用 LCM 发送控制指令

如果键盘程序完全不可用，可以用 Python 直接发送 LCM 指令：

```bash
docker exec cyberdog_slam bash -c '
source /opt/ros/galactic/setup.bash
cd /home/fish/cyberdog_sim
source install/setup.bash
python3 << "EOF"
import lcm
from robot_control_cmd_lcmt import robot_control_cmd_lcmt
import time

lc = lcm.LCM("udpm://239.255.76.67:7671?ttl=255")
msg = robot_control_cmd_lcmt()
msg.mode = 12       # RecoveryStand (站立)
msg.gait_id = 0
msg.duration = 0
msg.vel_des = [0.0, 0.0, 0.0]
msg.life_count = 1
lc.publish("robot_control_cmd", msg)
lc.handle()
print("已发送: RecoveryStand(站立)")
time.sleep(3)

msg.mode = 11       # Locomotion (运动模式)
msg.gait_id = 29    # TROT_AUTO
msg.vel_des = [0.1, 0.0, 0.0]  # 前进 0.1m/s
msg.life_count = 2
lc.publish("robot_control_cmd", msg)
lc.handle()
print("已发送: Locomotion 前进 0.1m/s")
EOF
'
```

---

## 4. 建图最佳实践

### 4.1 完整操作流程

```
阶段1: 初始化定位（开机后第1分钟）
┌─────────────────────────────────────┐
│  ① 按 Y 让机器狗站立               │
│  ② 等待 SuperLIO 初始化完成         │
│     (RViz中出现初始点云)            │
│  ③ 原地慢速旋转一圈                 │
│     (按Q或E, 角速度0.3, 约15秒)     │
│  ✓ 目的: 完成初始位姿估计           │
└─────────────────────────────────────┘
              ↓
阶段2: 边界扫描（第2~8分钟）
┌─────────────────────────────────────┐
│  ④ 沿赛道外圈慢速行走               │
│     (W键按4~5次, v≈0.1m/s)        │
│  ⑤ 弧形过弯, 不要原地转向           │
│     (同时按W+Q 或 W+E)             │
│  ⑥ 每个弯道停留3~5秒              │
│     (松开所有按键)                  │
│  ✓ 目的: 建立完整边界地图           │
└─────────────────────────────────────┘
              ↓
阶段3: 内部填充（第9~20分钟）
┌─────────────────────────────────────┐
│  ⑦ S形/Z字形走完内部区域           │
│  ⑧ 重点区域(起点/终点)多走几遍     │
│  ⑧ 单板桥区域减速到0.08m/s         │
│  ✓ 目的: 提高点云覆盖密度           │
└─────────────────────────────────────┘
              ↓
阶段4: 回环闭合（最后3~5分钟）
┌─────────────────────────────────────┐
│  ⑨ 沿原路返回起点                   │
│  ⑩ 在起点附近再次旋转一圈           │
│  ✓ 目的: 触发回环检测, 修正漂移     │
└─────────────────────────────────────┘
```

### 4.2 速度参数参考

| 场景 | 线速度 | 角速度 | 按键操作 |
|------|--------|--------|---------|
| 初始定位旋转 | 0 | 0.3 rad/s | Q或E按1次 |
| 直线行走 | 0.1 m/s | 0 | W按4~5次 |
| 弯道弧形通过 | 0.08 m/s | 0.25 rad/s | W按3~4次 + Q/E按1次 |
| 单板桥/窄道 | 0.06~0.08 m/s | 0.15 rad/s | W按2~3次 + 微调QE |
| 停留补点云 | 0 | 0 | 松开所有键 |

### 4.3 常见异常处理

| 异常现象 | 处理方法 |
|----------|---------|
| 地图出现双重影像（重叠） | **立即停止移动**，等待5~10秒让算法收敛，然后缓慢继续 |
| 点云突然消失 | 检查Gazebo是否正常运行；检查终端2SuperLIO日志有无报错 |
| 机器人翻倒 | 按B趴下 → 按Y重新站立；降低速度后继续 |
| RViz中轨迹断开 | 正常现象，回环闭合后会修正 |
| 建图过程中Gazebo卡顿 | 降低移动速度，减少场景复杂度 |

---

## 5. 保存地图

### ⚠️ 重要说明

SuperLIO **没有提供 ROS 服务接口**来触发保存地图。它使用**自动保存机制**：

- 当 `lio.map.save_map: true` 时，算法每隔 `lio.map.save_interval` 帧（当前配置300帧 ≈ 30秒）自动保存一次
- 地图保存位置：`/home/fish/cyberdog_sim/src/Super-LIO-ros2/src/super_lio/map/race_map.pcd`

### 方法1：利用自动保存（推荐）

建图完成后，**不要关闭 SuperLIO**，保持运行至少30秒，最新地图会自动覆盖保存。

### 方法2：手动触发保存（需修改配置）

如果想即时保存，可以在建图开始前将 `save_interval` 改小：

编辑配置文件：
```bash
docker exec cyberdog_slam vim /home/fish/cyberdog_sim/src/Super-LIO-ros2/src/super_lio/config/livox_360.yaml
```

将 `lio.map.save_interval: 300` 改为 `lio.map.save_interval: 10`（约每秒保存一次）

### 验证地图已保存

```bash
docker exec cyberdog_slam bash -c '
ls -lh /home/fish/cyberdog_sim/src/Super-LIO-ros2/src/super_lio/map/
'
```

预期输出：
```
-rw-r--r-- 1 root root 12M May 11 xx:xx race_map.pcd
```

### 查看地图质量

```bash
# 方法1: 在容器内用pcl_viewer
docker exec -it cyberdog_slam bash -c '
pcl_viewer /home/fish/cyberdog_sim/src/Super-LIO-ros2/src/super_lio/map/race_map.pcd
'

# 方法2: 复制到主机后用其他工具查看
cp /home/fish/cyberdog_sim/src/Super-LIO-ros2/src/super_lio/map/race_map.pcd ~/Desktop/
```

pcl_viewer 操作：
- 鼠标左键拖动：旋转视角
- 鼠标右键拖动：平移视角
- 滚轮：缩放
- **R键**：重置视角
- **Q/E**：切换颜色渲染模式
- **Ctrl+S**：截图

### 地图质量评估标准

| 指标 | 优秀 | 合格 | 不合格 |
|------|------|------|--------|
| 边界完整性 | 黄线清晰连续 | 主要段落可见 | 大段缺失 |
| 内部覆盖率 | 无明显空洞 | 少量小空洞 | 大面积空白 |
| 重叠一致性 | 无双重影像 | 轻微可接受 | 明显错位 |
| 文件大小 | >20MB | 5~20MB | <5MB |

---

## 6. 常见问题排查

### 问题速查表

| 编号 | 现象 | 可能原因 | 解决方案 |
|------|------|---------|---------|
| E01 | Gazebo窗口不弹出 | X11权限不足 | 主机执行 `xhost +local:docker` |
| E02 | Gazebo启动后立即崩溃 | 共享内存冲突 | `rm -f /dev/shm/*` 后重启 |
| E03 | Gazebo报 "No protocol specified" | DISPLAY/XAUTHORITY未设置 | t1.sh 中确保 export 了这两个变量 |
| E04 | 机器狗不出现在场景中 | spawn失败 | 检查 race.world 和 URDF 是否正确 |
| E05 | /velodyne_points 无数据 | use_lidar:=true 未生效 | 确认 launch 参数包含 use_lidar:=true |
| E06 | SuperLIO 无点云输出 | lidar_type 不匹配 | 使用 lidar_type: 3 或 4（非LIVOX） |
| E07 | RViz 中 TF 报错 | SuperLIO 未收到足够 IMU/Lidar 数据 | 等待初始化完成（通常需要几秒） |
| E08 | 键盘按了没反应 | cyberdog_control 未运行 | 先执行终端2的 cyberdog_control 启动命令 |
| E09 | 机器狗站起来又趴下 | FSM状态跳变 | 检查 control.log 中的 FSM 转换信息 |
| E10 | 地图严重偏移/漂移 | 移动太快或 IMU噪声大 | 降低速度到 0.08 m/s 以下 |
| E11 | 建图过程中程序崩溃 | 内存不足 | 减小 voxel_fliter_size 或 ds_size |
| E12 | 地图文件未生成 | save_map=false 或时间不够 | 确认配置并保持运行30秒+ |

### E01-E04 详细排查：Gazebo 相关

```bash
# 完整诊断脚本（主机执行）
echo "=== 1. Docker容器状态 ==="
docker ps | grep cyberdog_slam

echo "=== 2. X11权限 ==="
xhost | head -2

echo "=== 3. 残留进程 ==="
ps aux | grep -E "gzserver|gzclient" | grep -v grep | grep -v defunct || echo "无残留"

echo "=== 4. 容器内共享内存 ==="
docker exec cyberdog_slam ls -la /dev/shm/

echo "=== 5. 容器内环境 ==="
docker exec cyberdog_slam bash -c 'echo "DISPLAY=$DISPLAY"; echo "XAUTHORITY=${XAUTHORITY:-未设置}"'
```

### E05-E07 详细排查：激光雷达与SuperLIO

```bash
# 容器内执行
docker exec -it cyberdog_slam bash -c '
source /opt/ros/galactic/setup.bash
source /home/fish/cyberdog_sim/install/setup.bash

echo "=== 1. 激光雷达话题列表 ==="
ros2 topic list | grep -E "scan|lidar|velodyne|laser"

echo "=== 2. /velodyne_points 频率 ==="
timeout 5 ros2 topic hz /velodyne_points 2>&1 | tail -3

echo "=== 3. /imu 频率 ==="
timeout 5 ros2 topic hz /imu 2>&1 | tail -3

echo "=== 4. SuperLIO节点 ==="
source /home/fish/cyberdog_sim/src/Super-LIO-ros2/install/setup.bash
ros2 node list

echo "=== 5. /lio/cloud_world 频率 ==="
timeout 8 ros2 topic hz /lio/cloud_world 2>&1 | tail -3
'
```

### E08-E09 详细排查：键盘控制

```bash
# 终端A: 检查cyberdog_control
docker exec cyberdog_slam bash -c '
echo "=== 进程 ==="
pgrep -a cyberdog_control || echo "未运行"
echo "=== 最近日志 ==="
tail -10 /home/fish/cyberdog_sim/logs/control.log 2>/dev/null | grep -v GamepadCmd
echo "=== 共享内存 ==="
ls -la /dev/shm/development-simulator 2>/dev/null || echo "无共享内存"
'

# 终端B: 测试LCM通信
docker exec cyberdog_slam bash -c '
cd /home/fish/cyberdog_sim
source /opt/ros/galactic/setup.bash
source install/setup.bash
python3 -c "
import lcm
from robot_control_cmd_lcmt import robot_control_cmd_lcmt
lc = lcm.LCM(\"udpm://239.255.76.67:7671?ttl=255\")
msg = robot_control_cmd_lcmt()
msg.mode = 12; msg.gait_id = 0; msg.duration = 0
msg.vel_des = [0.0, 0.0, 0.0]; msg.life_count = 99
lc.publish(\"robot_control_cmd\", msg); lc.handle()
print(\"LCM测试消息已发送 (mode=RecoveryStand)\")
" 2>&1
'
# 然后检查control日志是否收到 life_count=99
sleep 2
docker exec cyberdog_slam tail -3 /home/fish/cyberdog_sim/logs/control.log
```

### 停止所有服务（按顺序）

在三个终端中分别 **Ctrl+C**：

1. **终端3** 先停：键盘控制（Ctrl+C）
2. **终端2** 再停：SuperLIO + RViz（Ctrl+c）
3. **终端1** 最后停：Gazebo（Ctrl+C，可能需要等几秒）

如果 Ctrl+C 无法终止：

```bash
# 主机执行强制清理
docker exec cyberdog_slam bash -c '
killall -9 gzserver gzclient cyberdog_control keybroad_commander 2>/dev/null
rm -f /dev/shm/*
echo "全部清理完毕"
'
```

---

## 附录A：文件索引

| 文件 | 路径 | 用途 |
|------|------|------|
| Gazebo 启动文件 | `src/cyberdog_simulator/cyberdog_gazebo/launch/race_gazebo.launch.py` | 加载race.world和机器人 |
| URDF 激光雷达定义 | `src/cyberdog_simulator/cyberdog_robot/cyberdog_description/xacro/gazebo.xacro` | velodyne激光传感器配置 |
| 控制器源码 | `src/cyberdog_locomotion/control/src/cyberdog_controller.cpp` | 主控制器入口 |
| 键盘控制源码 | `src/cyberdog_simulator/cyberdog_example/src/keybroad_commander.cpp` | LCM键盘控制 |
| LCM 通信桥接 | `src/cyberdog_locomotion/simbridge/include/simulation_bridge.hpp` | LCM订阅robot_control_cmd |
| SuperLIO 节点 | `src/Super-LIO-ros2/src/super_lio/src/apps/super_lio_node.cpp` | SLAM算法入口 |
| SuperLIO ROS封装 | `src/Super-LIO-ros2/src/super_lio/src/ros/ROSWrapper.cpp` | 话题订阅/发布 |
| SuperLIO 配置 | `src/Super-LIO-ros2/src/super_lio/config/livox_360.yaml` | 建图参数 |
| SuperLIO Launch | `src/Super-LIO-ros2/src/super_lio/launch/hesai.py` | 启动文件 |
| 机器人默认参数 | `src/cyberdog_locomotion/common/config/robot-defaults.yaml` | 控制参数 |

## 附录B：话题速查

| 话题 | 类型 | 发布者 | 作用 |
|------|------|--------|------|
| `/velodyne_points` | sensor_msgs/PointCloud2 | Gazebo | 激光雷达点云（180×8线） |
| `/imu` | sensor_msgs/Imu | Gazebo | IMU数据（500Hz） |
| `/joint_states` | sensor_msgs/JointState | Gazebo | 12关节状态 |
| `/tf` | tf2_msgs/TFMessage | Gazebo+SuperLIO | 坐标变换树 |
| `/lio/cloud_world` | sensor_msgs/PointCloud2 | SuperLIO | 全局地图点云 |
| `/lio/odom` | nav_msgs/Odometry | SuperLIO | 位姿里程计 |
| `robot_control_cmd` (LCM) | robot_control_cmd_lcmt | keybroad_commander | 键盘控制指令 |

## 附录C：LCM 消息格式参考

`robot_control_cmd_lcmt` 关键字段：

| 字段 | 类型 | 含义 |
|------|------|------|
| mode | int8_t | 控制模式 (3=QPStand, 7=PureDamper, 11=Locomotion, 12=RecoveryStand) |
| gait_id | int8_t | 步态ID (29=TROT_AUTO) |
| vel_des[3] | float | [vx, vy, vyaw] 期望速度 |
| pos_des[3] | float | [px, py, pz] 期望位置 |
| step_height[2] | float | [front, back] 步高 |
| life_count | int32_t | 生命周期计数（每次发送递增） |
| duration | int32_t | 持续时间(ms), 0=持续直到新指令 |

---

*文档版本：v2.0 | 更新日期：2026-05-11 | 基于 cyberdog_sim 实际源码验证*
