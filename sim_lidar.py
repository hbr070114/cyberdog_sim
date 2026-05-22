#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from rclpy.qos import QoSProfile, ReliabilityPolicy, DurabilityPolicy
from sensor_msgs.msg import PointCloud2, PointField
import math
import struct


class SimLidar(Node):
    def __init__(self):
        super().__init__('sim_lidar')
        lidar_qos = QoSProfile(
            depth=20,
            reliability=ReliabilityPolicy.BEST_EFFORT,
            durability=DurabilityPolicy.VOLATILE
        )
        self.pub_lidar = self.create_publisher(PointCloud2, '/velodyne_points', lidar_qos)
        self.timer = self.create_timer(0.1, self.publish_cloud)
        self.count = 0
        self.get_logger().info('LiDAR publishing to /velodyne_points')

    def publish_cloud(self):
        msg = PointCloud2()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = 'lidar_link'
        msg.height = 1

        num_points = 360
        msg.width = num_points

        fields = [
            PointField(name='x', offset=0, datatype=PointField.FLOAT32, count=1),
            PointField(name='y', offset=4, datatype=PointField.FLOAT32, count=1),
            PointField(name='z', offset=8, datatype=PointField.FLOAT32, count=1),
            PointField(name='intensity', offset=12, datatype=PointField.FLOAT32, count=1),
            PointField(name='time', offset=16, datatype=PointField.FLOAT32, count=1),
        ]
        msg.fields = fields
        msg.is_bigendian = False
        msg.point_step = 20
        msg.row_step = 20 * num_points

        data = b''
        for i in range(num_points):
            angle = (i / num_points) * 2 * math.pi + (self.count * 0.01)
            r = 3.0 + 2.0 * math.sin(angle * 8 + self.count * 0.1)
            x = r * math.cos(angle)
            y = r * math.sin(angle)
            z = 0.1 * math.sin(angle * 3)
            intensity = 100.0
            time = i * 0.0001
            data += struct.pack('fffff', x, y, z, intensity, time)

        msg.data = data
        self.pub_lidar.publish(msg)
        self.count += 1


def main():
    rclpy.init()
    node = SimLidar()
    rclpy.spin(node)


if __name__ == '__main__':
    main()