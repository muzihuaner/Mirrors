#!/bin/bash

# 目标URL
URL="https://mirrors.sdu.edu.cn/software/Windows/WePE/"

# 本地保存目录
LOCAL_DIR="/home/www/mirrors/wepe"

# 创建本地目录（如果目录不存在）
mkdir -p "$LOCAL_DIR"

# 使用 curl 下载文件
# 注意：curl 不支持递归下载，因此需要手动列出文件并下载
# 这里假设 URL 是一个文件列表页面，可以通过解析 HTML 获取文件链接

# 下载文件列表页面
curl -s "$URL" -o /tmp/filelist.html

# 解析文件列表页面，提取文件链接
# 这里使用简单的 grep 和 sed 提取链接，实际情况可能需要更复杂的解析
grep -oP '(?<=href=")[^"]*' /tmp/filelist.html | grep -v '^\.\./$' | while read -r file; do
    # 下载每个文件
    file_url="${URL}${file}"
    file_path="${LOCAL_DIR}/${file}"
    
    # 创建子目录（如果文件路径包含目录）
    mkdir -p "$(dirname "$file_path")"
    
    # 下载文件
    curl -L -o "$file_path" "$file_url"
done

# 清理临时文件
rm /tmp/filelist.html