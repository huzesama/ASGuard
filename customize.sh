#BOOTMODE（布尔）：true如果模块已安装在Magisk应用中
#MODPATH （路径）：应在其中安装模块文件的路径
timer_start=$(date "+%Y-%m-%d %H:%M:%S")
LogPrint() { echo "$1" ; }
WriteConfig() {
	touch /data/media/0/Android/ASGuard.conf
	LogPrint "- 调整外部配置文件权限组(3/3)"
	chmod 664 /data/media/0/Android/ASGuard.conf
	chown 'media_rw:media_rw' /data/media/0/Android/ASGuard.conf
}
model="$(grep_prop ro.product.system.model)"
version="$(grep_prop version ${MODPATH}/module.prop)"
versioncode="$(grep_prop versionCode ${MODPATH}/module.prop)"
var_version="$(grep_prop ro.build.version.release)"
name="$(grep_prop name ${MODPATH}/module.prop)"
description="$(grep_prop description ${MODPATH}/module.prop)"
cat <<EOF
- **********该设备信息**********
- 您的设备名称: ${model}
- 系统版本: ${var_version}
- ********正在安装的模块********
- 名称：${name}
- 版本：${version}
- 版本号：${versioncode}
- 作者：沍澤
- ${description}
- 安装日期：${timer_start}
- **********更新日志***********
- 注意：v3.0之后的版本更改了模块id，更新须卸载v3.0以前的版本
- 卸载前请备份/Android/ASGuard.txt以防配置被删除
- （尽管此版本会移除旧版模块的删除配置文件命令）
- --------------------------------------
- v6.0_beta更新日志
- 改进运行逻辑(4.12)
- 改进获取EAS方式(4.12)
- 移除EAS存储文件(4.12)
- 新增自动模式(4.12)
- 新增APP过滤名单(4.12)
- 新增单个开关过滤名单(4.12)
- 优化已知命令(4.14)
- 修改R模式时间单位秒为分(4.14)
- 改进Auto模式(4.17)
- 修复一些问题(4.17)
- 
- 提示：在Magisk列表关闭模块开关可暂时停止保护服务，关机前请记得打开~
- 
- *******************************
- 
EOF
if ${BOOTMODE}; then
	if_update=1
else
	if_update=0
fi
LogPrint "- 开始安装...(0/3)"
LogPrint "- 调整配置文件所属权限用户组(1/3)"
chmod 777 "${MODPATH}/service.sh"
chmod 777 "${MODPATH}"/config/*
chown 'root:root' "${MODPATH}/service.sh"
chown 'root:root' "${MODPATH}"/config/*
LogPrint "- 释放配置(2/3)"
if [[ ! -f "/data/media/0/Android/ASGuard.conf" ]]; then
	LogPrint "- 第一次正常运行时会生成配置，生成内容详情请到目录/data/media/0/Android/ASGuard.conf查看"
	LogPrint ""
	LogPrint "-- 默认周期10秒(运行模式为M/R时有效)"
	LogPrint "-- 默认开启log日志"
	LogPrint "-- 默认开机关闭所有无障碍服务"
	LogPrint "-- 默认运行模式:A(A/M/F/R)"
	LogPrint "-- 模块安装目录${MODPATH//_update/}"
	WriteConfig
fi
timer_end=$(date "+%Y-%m-%d %H:%M:%S")
duration=$(echo $(($(date +%s -d "${timer_end}") - $(date +%s -d "${timer_start}"))) | awk '{t=split("60 s 60 m 24 h 999 d",a);for(n=1;n<t;n+=2){if($1==0)break;s=$1%a[n]a[n+1]s;$1=int($1/a[n])}print s}')
[[ -z "${duration}" ]] || [[ "${duration}" = "1s" ]] && duration="秒刷！"
if [[ ${if_update} = 1 ]]; then
	LogPrint "- 更新完成，耗时：${duration}"
else
	LogPrint "- 安装完成，耗时：${duration}"
fi
LogPrint "- 重启设备后生效(安装ASGuardUI可免重启更新)"