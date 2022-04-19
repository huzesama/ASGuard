#!/system/bin/sh
until [[ -z $(dumpsys window policy | grep mInputRestricted | grep true) ]]; do
	sleep 2
done
##设置环境变量##
export DIR="${0%/*}"
export PATH="${DIR}/busybox/bin:${PATH}"
export version='v6_beta'
export versionCode='202204171'
export inform="ASGuard ${version}(${versionCode}) created by 沍澤"
export CONFIG="/data/media/0/Android/ASGuard.conf"
export LOG_PATH="/data/media/0/Android/log_ASG.txt"
export PROP="${DIR}/module.prop"
export description="一个无障碍功能管理模块.在\"获取root权限\"的APP完全替代\"一般使用无障碍权限\"的APP前的Msgiask模块的不错选择."
export AS exAS EAS EAST package_whitelist CTime log clean mode exclude MODPATH LastConf
for var in $(ls "${DIR}/busybox/bin"); do
	chmod 111 "${DIR}/busybox/bin/${var}"
	chown 'root:root' "${DIR}/busybox/bin/${var}"
done
source "${DIR}/config/Function.sh"
if [[ $? != 0 ]]; then
	change_prop "错误" "Function.sh加载失败"
	exit 1 > "${LOG_PATH}"
fi
##读取配置后记录文件信息，当文件信息产生改动重新读取##
load_config
LastConf="$(ls -l "${CONFIG%/*}/" | grep "${CONFIG##*/}")"
if [[ ${log=1} -ne 0 ]]; then
	echo "${inform}" > "${LOG_PATH}"
	echo "运行日期:$(date '+%Y.%m.%d %X')" >> "${LOG_PATH}"
else
	[[ -f "${LOG_PATH}" ]] && rm -rf "${LOG_PATH}" >/dev/null 2>&1
fi

##电池优化白名单操作##
start_whitelist_clear "${AS} ${package_whitelist}" &
mylog "${AS} ${package_whitelist}" "Whitelist"

##匹配AS的无障碍开关##
EAS="$(getService "${AS:-}")"

##删去排除名单##
for var in $(echo ${exclude}); do
	EAS="$(echo "${EAS}" | grep -v "${var}")"
done
mylog "${exclude}" "过滤开关"

##判断是否清空已开启的无障碍##
if [[ ${clean} = 1 ]]; then
	write_EAST -c
fi

##选择加载文件路径##
case "${mode:-A}" in
R) file="${DIR}/config/Refresh.sh" ;;
F) file="${DIR}/config/Focus.sh" ;;
M) file="${DIR}/config/Monitor.sh" ;;
*) file="${DIR}/config/Auto.sh" ;;
esac
if [[ ! -f "${file}" ]]; then
	mylog "\"${file}\"文件丢失"
	change_prop "加载失败" "${file}文件丢失"
	exit 2 > "${LOG_PATH}"
fi
cp -f "${file}" "${DIR}/ASGuard_Process.sh"
chmod 111 "${DIR}/ASGuard_Process.sh"
chown 'root:root' "${DIR}/ASGuard_Process.sh"
settings put secure accessibility_enabled 1
while [[ "$(ps -ef | grep 'ASGuard_Process' | grep -v grep | wc -l)" = "0" ]]; do
	nohup sh "${DIR}/ASGuard_Process.sh" &
	sleep 2
done
exit