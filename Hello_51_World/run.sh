#!/bin/bash


# 与服务器进行时间同步
echo "正在同步服务器时间，时间服务器：time.windows.com"
sudo ntpdate -u time.windows.com

# 再同步一次，以防万一
echo "正在同步服务器时间，时间服务器：time.windows.com"
sudo ntpdate -u time.windows.com

echo "修改当前用户open files为4096"
# 临时增加当前用户的open files数量
ulimit -n 4096

echo "调用可执行文件"
# 运行可执行文件
./Hello_51_World