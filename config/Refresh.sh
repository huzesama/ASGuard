source "${DIR}/config/Function.sh"
if [[ $? != 0 ]]; then
	change_prop "错误" "Function.sh加载失败"
	exit 1 >> "${LOG_PATH}"
fi
change_prop "更新配置时间:$(get_time)" "运行模式: R "
mylog "正在运行..." "R"
load_config
switch=1
if_config_change() {
	if [[ "$(ls -l "${CONFIG%/*}/" | fgrep "${CONFIG##*/}")" != "${LastConf}" ]]; then
		load_config
		LastConf=$(ls -l "${CONFIG%/*}/" | grep "${CONFIG##*/}")
		if [[ "${AS}" != "${old_AS}" ]]; then
			sameAS=$(take_same "${AS}" "${old_AS}")
			increaseAS=$(get_difference "${AS}" "${sameAS}")
		fi
		##匹配AS的无障碍开关
		result=$(getService "${increaseAS}")
		EAS=$(echo -e "${result}\n${EAS}" | sort | uniq | sed '/^$/d')
		##删去排除名单
		for var in $(echo ${exclude}); do
			EAS=$(echo "${EAS}" | grep -v "${var}")
		done
		change_prop "更新配置时间:$(get_time)" "运行模式: R"
		mylog "配置文件已被修改." "ASGuard.conf"
	fi
}
while true; do
	if [[ ! -f "${DIR}/disable" ]]; then
		if [[ ${switch} = 0 ]]; then
			change_prop "重新运行"
			switch=1
			nohup sh "${DIR}/service.sh" &
			exit 0
		fi
		if_config_change
		while [[ -n ${AS} ]] && [[ ${mode} = 'R' ]]; do
			EAST=$(read_EAST)
			write_EAST -c
			write_EAST "${EAST} ${EAS}"
			mylog "刷新开关." "R"
			sleep $(( ${CTime} * 60 ))
			[[ -f "${DIR}/disable" ]] && break
			if_config_change
		done
	else
		if [[ ${switch} = 1 ]]; then
			change_prop "暂停服务"
			mylog "暂停服务" "ASGuard"
			switch=0
		fi
	fi
	sleep $(( ${CTime} + 6 ))
	if [[ ${mode} != 'R' ]]; then
		change_prop "重新运行"
		nohup sh "${DIR}/service.sh" &
		exit 0
	fi
done
exit 10