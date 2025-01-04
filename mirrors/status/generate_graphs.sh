#!/bin/bash

# 生成 CPU 使用率图像
rrdtool graph /home/www/mirrors/status/cpu_usage.png \
  --start -3600 \
  --end now \
  --title "CPU Usage" \
  --vertical-label "CPU (%)" \
  DEF:cpu=cpu_usage.rrd:cpu:AVERAGE \
  LINE1:cpu#FF0000:"CPU Usage"

# 生成内存使用率图像
rrdtool graph /home/www/mirrors/status/memory_usage.png \
  --start -3600 \
  --end now \
  --title "Memory Usage" \
  --vertical-label "Memory (%)" \
  DEF:mem=memory_usage.rrd:mem:AVERAGE \
  LINE1:mem#00FF00:"Memory Usage"

# 生成网络流量图像
rrdtool graph /home/www/mirrors/status/net_usage.png \
  --start -3600 \
  --end now \
  --title "Network Usage" \
  --vertical-label "Bytes" \
  DEF:in=net_usage.rrd:in:AVERAGE \
  DEF:out=net_usage.rrd:out:AVERAGE \
  LINE1:in#0000FF:"Incoming Traffic" \
  LINE1:out#FF6600:"Outgoing Traffic"
