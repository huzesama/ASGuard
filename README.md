# ASGuard
Magisk模块，用于安卓的无障碍服务(或名:辅助功能)辅助管理模块
模块自带的四种运行机制(Auto/Monitor/Focus/Refresh)尽可能满足大部分人对无障碍功能需要时就开启，不需要的时候忽视的需求
此模块从2021年1月18号发布v1.0到现在，截至2022年4月14号粗略统计已更新34个版本，这不仅是我第一个更新维护长达一年的模块，也是我第一个出于兴趣开始制作的模块。

# 运行机制
## Auto(此模式无须配置AS即可使用)

当应用处于前台时会将其辅助功能打开，并开始粗略记录该应用的进程状况，使用频率，使用频率趋势，简易判断辅助功能是否要开启或保持开启，处于AS列表内的APP具有更高的优先级，而一段时间没有记录前台则从记录列表中移除


## Monitor

周期监测系统辅助功能开启名单，如果其中的列表发生改变，并且被关闭的是AS列表内的APP，则重新将其打开，其他情况则忽略操作


## Focus

监测前台APP是为AS列表内的APP，如果该APP有相应的辅助功能，则将其打开


## Refresh

定时重启所有AS列表内APP的辅助功能

# 配置
配置文件存放于/sdcard/Android/ASGuard.conf

配置方法可参考配置文件

过滤APP需要填入package name包名

过滤开关可通过以下命令获取:

dumpsys package [PackageName]| grep -s "ACCESSIBILITY_SERVICE" | sed 's/ /\n/g' | fgrep "[PackageName]/." | sed "s:/\.:/[PackageName]\.:g" | sort | uniq

以上三处[PackageName]需要替换成查找的package name

# 安装
下载zip之后通过Magisk manager刷入

Magisk详细查看<https://github.com/topjohnwu/Magisk>

![Magisk](https://github.com/topjohnwu/Magisk/raw/master/docs/images/logo.png)

# APP
APP是由酷安@嘟嘟ski提供的PIO框架二次创作而来，旨在于能够轻松修改ASGuard的配置，并非必需部分，可自行选择

而APP也提供了简易的无障碍管理功能，无需等待例如某些系统的开启警告倒计时

# 作者的自说自话
首先呢我是一个小fw，做的并不是太好，可能还有些设备不能很好的运行，但是我真的很想把它做好，如果喜欢的话可以点亮小星星
