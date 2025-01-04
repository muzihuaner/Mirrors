#!/bin/bash

# 获取 CPU 使用率
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

# 获取内存使用率
MEMORY_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')

# 获取网络流量
NETWORK_IN=$(cat /sys/class/net/eth0/statistics/rx_bytes)
NETWORK_OUT=$(cat /sys/class/net/eth0/statistics/tx_bytes)

# 更新 RRD 数据库
rrdtool update /home/www/mirrors/status/cpu.rrd N:$CPU_USAGE
rrdtool update /home/www/mirrors/status/memory.rrd N:$MEMORY_USAGE
rrdtool update /home/www/mirrors/status/network.rrd N:$NETWORK_IN:$NETWORK_OUT

# 生成图片
rrdtool graph /home/www/mirrors/status/cpu.png \
--start -1h \
--title "CPU Usage" \
--vertical-label "Percentage" \
DEF:cpu=/home/www/mirrors/status/cpu.rrd:cpu:AVERAGE \
LINE1:cpu#FF0000:"CPU Usage"

rrdtool graph /home/www/mirrors/status/memory.png \
--start -1h \
--title "Memory Usage" \
--vertical-label "Percentage" \
DEF:memory=/home/www/mirrors/status/memory.rrd:memory:AVERAGE \
LINE1:memory#00FF00:"Memory Usage"

rrdtool graph /home/www/mirrors/status/network.png \
--start -1h \
--title "Network Traffic" \
--vertical-label "Bytes" \
DEF:in=/home/www/mirrors/status/network.rrd:in:AVERAGE \
DEF:out=/home/www/mirrors/status/network.rrd:out:AVERAGE \
LINE1:in#0000FF:"Download" \
LINE2:out#FF00FF:"Upload"