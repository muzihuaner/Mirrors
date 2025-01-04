要使用 **RRDTool** 生成 CPU、内存和网络使用情况的图表，并将这些图表保存到 `status` 文件夹中，首先你需要收集相应的性能数据并存储在 `.rrd` 文件中。然后，你可以使用 `rrdtool graph` 命令生成图表并将它们保存为图片。

以下是详细步骤：

### 1. **安装 RRDTool**

如果你还没有安装 `RRDTool`，请按照以下步骤进行安装。

#### Debian/Ubuntu 系统：

```
sudo apt update
sudo apt install rrdtool
```

#### CentOS/RHEL 系统：

```
sudo yum install rrdtool
```

### 2. **收集和存储数据**

`RRDTool` 需要数据来生成图表。你可以手动收集系统性能数据，并将其存储在 `.rrd` 文件中，或者通过脚本定期收集数据并更新 `.rrd` 文件。

#### 创建一个 `.rrd` 数据库文件

首先，我们需要为 CPU、内存和网络使用情况创建 `.rrd` 文件。例如，我们将创建一个用于监控 **CPU 使用率** 的 `.rrd` 文件。

```
rrdtool create cpu_usage.rrd \
  --step 60 \
  DS:cpu:GAUGE:120:0:100 \
  RRA:AVERAGE:0.5:1:10080
```

- `--step 60`: 数据的收集频率是 60 秒。
- `DS:cpu:GAUGE:120:0:100`: 创建一个名为 `cpu` 的数据源，数据类型为 `GAUGE`，即在 120 秒内记录的数据值范围是 0 到 100。
- `RRA:AVERAGE:0.5:1:10080`: 数据的存储方式，`AVERAGE` 表示每个数据点的平均值，存储 10080 个数据点（即 1 周的数据）。

#### 创建内存使用 `.rrd` 文件

```
rrdtool create memory_usage.rrd \
  --step 60 \
  DS:mem:GAUGE:120:0:100 \
  RRA:AVERAGE:0.5:1:10080
```

#### 创建网络流量 `.rrd` 文件

```
rrdtool create net_usage.rrd \
  --step 60 \
  DS:in:COUNTER:120:0:U \
  DS:out:COUNTER:120:0:U \
  RRA:AVERAGE:0.5:1:10080
```

- `DS:in:COUNTER:120:0:U`：表示 `in`（输入）数据为 `COUNTER` 类型。
- `DS:out:COUNTER:120:0:U`：表示 `out`（输出）数据为 `COUNTER` 类型。

### 3. **收集数据并更新 `.rrd` 文件**

你需要创建脚本来定期收集系统的 CPU、内存和网络使用数据，并更新 `.rrd` 文件。例如，可以使用 `top` 或 `free` 命令来获取 CPU 和内存数据，使用 `cat /sys/class/net/eth0/statistics/rx_bytes` 和 `tx_bytes` 来获取网络流量数据。

以下是一个简单的脚本，用于收集这些数据并更新 `.rrd` 文件：

#### `update_rrd.sh` 脚本示例：

```
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
```

- 每次执行 `update_rrd.sh` 脚本，它会将当前的 CPU、内存和网络流量数据更新到相应的 `.rrd` 文件。

你可以将此脚本添加到 `cron` 作业中，定期运行它：

```
crontab -e
```

然后添加以下行以每分钟更新一次数据：

```
* * * * * /home/www/mirrors/status/update_rrd.sh
```

### 4. **生成图像文件并保存到 `status` 文件夹**

一旦数据在 `.rrd` 文件中更新，你就可以使用 `rrdtool graph` 命令生成图像并将其保存到 `status` 文件夹。

#### 生成 CPU 使用率图像：

```
rrdtool graph ~/status/cpu_usage.png \
  --start -3600 \
  --end now \
  --title "CPU Usage" \
  --vertical-label "CPU (%)" \
  DEF:cpu=cpu_usage.rrd:cpu:AVERAGE \
  LINE1:cpu#FF0000:"CPU Usage"
```

#### 生成内存使用率图像：

```
rrdtool graph ~/status/memory_usage.png \
  --start -3600 \
  --end now \
  --title "Memory Usage" \
  --vertical-label "Memory (%)" \
  DEF:mem=memory_usage.rrd:mem:AVERAGE \
  LINE1:mem#00FF00:"Memory Usage"
```

#### 生成网络流量图像：

```
rrdtool graph ~/status/net_usage.png \
  --start -3600 \
  --end now \
  --title "Network Usage" \
  --vertical-label "Bytes" \
  DEF:in=net_usage.rrd:in:AVERAGE \
  DEF:out=net_usage.rrd:out:AVERAGE \
  LINE1:in#0000FF:"Incoming Traffic" \
  LINE1:out#FF6600:"Outgoing Traffic"
```

### 5. **定期生成图像**

你可以将这些命令添加到一个新的脚本中，并通过 `cron` 定期生成图像。例如，创建一个 `generate_graphs.sh` 脚本：

```
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
```

然后将此脚本添加到 `cron` 中，以定期生成图像。例如，每小时生成一次图像：

```
crontab -e
```

添加以下行：

```
0 * * * * /home/www/mirrors/status/generate_graphs.sh
```

### 6. **查看生成的图像**

在 `status` 文件夹中，你将看到生成的图像文件，例如：

- `cpu_usage.png`
- `memory_usage.png`
- `net_usage.png`

这些图像可以通过浏览器或图像查看器查看，并可以定期更新。

------

### 总结

- 使用 `RRDTool` 创建 `.rrd` 数据库文件来收集和存储 CPU、内存和网络流量数据。
- 使用脚本定期更新 `.rrd` 文件。
- 使用 `rrdtool graph` 命令生成图像并将其保存到 `status` 文件夹中。
- 可通过 `cron` 定期执行这些任务，确保数据和图像的自动更新。