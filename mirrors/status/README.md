要使用 RRDTool 生成 CPU、内存和网络的监控图片，并将其保存到 `/home/www/mirrors/status` 文件夹中，你需要完成以下几个步骤：

### 1. 安装 RRDTool

首先，确保你已经安装了 RRDTool。如果没有安装，可以使用以下命令进行安装：

- **Debian/Ubuntu**:

  ```
  sudo apt-get install rrdtool
  ```

- **CentOS/RHEL**:

  ```
  sudo yum install rrdtool
  ```

### 2. 创建 RRD 数据库

你需要为 CPU、内存和网络分别创建 RRD 数据库。以下是一个示例：

#### CPU 使用率

```
rrdtool create /home/www/mirrors/status/cpu.rrd \
--start N \
--step 60 \
DS:cpu:GAUGE:120:0:100 \
RRA:AVERAGE:0.5:1:1440 \
RRA:AVERAGE:0.5:5:2016 \
RRA:AVERAGE:0.5:15:1488
```

#### 内存使用率

```
rrdtool create /home/www/mirrors/status/memory.rrd \
--start N \
--step 60 \
DS:memory:GAUGE:120:0:U \
RRA:AVERAGE:0.5:1:1440 \
RRA:AVERAGE:0.5:5:2016 \
RRA:AVERAGE:0.5:15:1488
```

#### 网络流量

```
rrdtool create /home/www/mirrors/status/network.rrd \
--start N \
--step 60 \
DS:in:COUNTER:120:0:U \
DS:out:COUNTER:120:0:U \
RRA:AVERAGE:0.5:1:1440 \
RRA:AVERAGE:0.5:5:2016 \
RRA:AVERAGE:0.5:15:1488
```

### 3. 更新 RRD 数据库

你需要定期更新这些 RRD 数据库。可以使用脚本来自动化这个过程。

#### 示例脚本

保存为update_rrd.sh

```
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
```

### 定时任务

```
crontab -e
```

```
* * * * * /home/www/mirrors/status/update_rrd.sh
```

### 访问图片

生成的图片将保存在 `/home/www/mirrors/status` 文件夹中。你可以通过 Web 服务器访问这些图片，例如：

复制

```
http://your-server/status/cpu.png
http://your-server/status/memory.png
http://your-server/status/network.png
```

确保你的 Web 服务器配置正确，能够访问 `/home/www/mirrors/status` 文件夹。

### 定期清理旧数据

你可以设置一个定期任务来清理旧的 RRD 数据，以防止数据库文件过大。

```
find /home/www/mirrors/status -name "*.rrd" -mtime +30 -exec rm {} \;
```

这个命令会删除 30 天前的 RRD 文件。

### 总结

通过以上步骤，你可以使用 RRDTool 监控 CPU、内存和网络的使用情况，并生成相应的图片。这些图片可以用于实时监控系统的状态。