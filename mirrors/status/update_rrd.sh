#!/bin/bash

# 获取 CPU 使用率（百分比）
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')


# 获取内存使用情况
mem_usage=$(free -m | awk '/Mem/ {print $3/$2 * 100.0}')

# 获取网络流量（自动选择网络接口）
rx_bytes=$(cat /sys/class/net/eth0/statistics/rx_bytes)
tx_bytes=$(cat /sys/class/net/eth0/statistics/tx_bytes)

# 更新 RRD 数据库
rrdtool update cpu_usage.rrd N:$cpu_usage || echo "Error updating cpu_usage.rrd at $(date)" >> /var/log/rrdtool_error.log
rrdtool update memory_usage.rrd N:$mem_usage || echo "Error updating memory_usage.rrd at $(date)" >> /var/log/rrdtool_error.log
rrdtool update net_usage.rrd N:$rx_bytes:$tx_bytes || echo "Error updating net_usage.rrd at $(date)" >> /var/log/rrdtool_error.log
