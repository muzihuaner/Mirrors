#!/bin/bash

# 目标URL
URL="https://mirrors.sdu.edu.cn/software/Windows/WePE/"

# 本地保存目录
LOCAL_DIR="/home/www/mirrors/wepe"

# 创建本地目录（如果目录不存在）
mkdir -p "$LOCAL_DIR"

# 使用 wget 递归下载文件
wget -r -np -nH --cut-dirs=3 -P "$LOCAL_DIR" "$URL"