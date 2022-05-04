source "${DIR}/config/Function.sh"
if [[ $? != 0 ]]; then
	change_prop "错误" "Function.sh加载失败"
	exit 1 >> "${LOG_PATH}"
fi
change_prop "更新配置时间:$(get_time)" "运行模式: A 排除应用个数:$(echo "${exAS:-}" | sed '/^$/d' | wc -l)"
mylog "正在运行..." "A"
ST=4
switch=1
n=0
m=0
for var in $(echo ${AS}); do
	write_EAST "$(getService "${var}")"
done
EAST="$(read_EAST)"
if_config_change() {
	if [[ "$(ls -l "${CONFIG%/*}/" | grep "${CONFIG##*/}")" != "${LastConf}" ]]; then
		load_config
		LastConf="$(ls -l "${CONFIG%/*}/" | grep "${CONFIG##*/}")"
		change_prop "更新配置时间:$(get_time)" "运行模式: A 排除应用个数:$(echo "${exAS:-}" | sed '/^$/d' | wc -l)"
		mylog "配置文件已被修改." "ASGuard.conf"
	fi
}
exEAS() {
	##删去排除名单
	local result var result
	result="${1:-}"
	for var in $(echo ${exclude}); do
		result="$(echo "${result}" | grep -v "${var}")"
	done
	echo "${result}"
}
while true; do
	if [[ ! -f "${DIR}/disable" ]]; then
		if [[ ${switch} = 0 ]]; then
			change_prop "重新运行"
			switch=1
			nohup sh "${DIR}/service.sh" &
			exit 0
		fi
		while [[ $(getUnlockState) = true ]] && [[ ${mode} = 'A' ]]; do
			[[ -f "${DIR}/disable" ]] && break
			n=$(( n + 1 ))
			old_EAST="${EAST}"
			sleep ${ST}
			##获取焦点窗口APP##
			EAST="$(read_EAST)"
			CFA="$(getCurrentFocusAPP)"
			##排除指定APP##
			[[ -n $(echo "${exAS}" | fgrep -w "${CFA}") ]] && CFA=""
			##焦点窗口为主页面时弱预测及监测##
			if [[ -n $(echo ${CFA} | grep home) ]]; then
				if [[ "${EAST}" != "${old_EAST}" ]]; then
					sameEAST=$(take_same "${EAST}" "${old_EAST}")
					decreaseEAST=$(get_difference "${old_EAST}" "${sameEAST}")
				fi
				##AS列表内的APP如果进程存在则开启无障碍
				for var in $(echo ${AS}); do
					if [[ $(getProcessState ${var}) != "false" ]]; then
						write_EAST "$(getService "${var}")"
						mylog "为进程开启无障碍服务." "${var}"
					fi
				done
				for var in $(echo ${AL}); do
					Td="$(getProcessState ${var//_/.} t)"
					if [[ $(eval "echo ${var}_Td") != ${Td} ]] || [[ -n $(echo "${decreaseEAST}" | fgrep "${var//_/.}/") ]]; then
						if [[ ${Td} != false ]]; then
							write_EAST "$(getService "${var//_/.}")"
							mylog "检测开启无障碍服务." "${var//_/.}"
						fi
						eval "${var}_Td=${Td}"
					##最近五分钟启动频率是否大于最近十分钟的前五分钟启动频率##
					elif [[ $(eval "(( ${var}_Fre10 - ${var}_Fre5 ))") < $(eval "echo \${${var}_Fre5}") ]]; then
						write_EAST "$(getService "${var//_/.}")"
						mylog "开启常用应用无障碍开关." "${var//_/.}"
					fi
				done
				if [[ m -gt 2 ]]; then
					for var in $(echo ${AL}); do
						if [[ $(eval "echo ${var}_Fre5") = 0 ]]; then
							##去除长时间未打开的APP名单##
							AL=$(echo "${AL}" | fgrep -vw "${var}")
							eval "unset ${var}_Fre10"
							eval "unset ${var}_Fre5"
							mylog "从AL名单中移除." "${CFA}"
						else
							eval "${var}_Fre10=${var}_Fre5"
						fi

					done
					m=0
				fi
				if [[ n -gt 75 ]]; then
					for var in $(echo ${AL}); do
						eval "${var}_Fre5=0"
					done
					n=0
					m=$(( m + 1 ))
				fi
				continue
			fi
			willWrite="$(getService "${CFA}")"
			willWrite="$(exEAS "${willWrite}")"
			if [[ -n ${willWrite} ]]; then
				write_EAST "${willWrite}"
				if [[ ${old_CFA} != "${CFA}" ]]; then
					mylog "应用获得焦点." "${CFA}"
					old_CFA="${CFA}"
				fi
				if [[ -z $(echo "${AS}" | fgrep "${CFA}") ]] && [[ -z $(echo "${AL}" | fgrep "${CFA//./_}") ]]; then
					mylog "已加入AL名单." "${CFA}"
					AL="${AL:-}${AL:+\n}${CFA}"
					##替换包名如com.huze.ASGuard替换为com_huze_ASGuard##
					AL=$(echo "${AL//./_}" | sort | uniq)
					eval "${CFA//./_}_Td=$(getProcessState ${CFA} t)"
					eval "${CFA//./_}_Fre5=\$(( \${${CFA//./_}_Fre5:-0} + 1 ))"
					eval "${CFA//./_}_Fre10=\$(( \${${CFA//./_}_Fre10:-0} + 1 ))"
				fi
				willWrite=""
			fi
			if_config_change
		done
	else
		if [[ ${switch} = 1 ]]; then
			change_prop "暂停服务"
			mylog "暂停服务" "ASGuard"
			switch=0
		fi
	fi
	sleep $(( ${ST} + 6 ))
	if [[ ${mode} != 'A' ]]; then
		change_prop "重新运行"
		nohup sh "${DIR}/service.sh" &
		exit 0
	fi
done
exit 10