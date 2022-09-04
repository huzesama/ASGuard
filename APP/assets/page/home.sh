conf=/data/media/0/Android/ASGuard.conf
source "${conf}" >/dev/null 2>&1
[[ -n "${MODPATH}" ]] && [[ -d "${MODPATH}" ]] || [[ -d /data/adb/modules/huzeASGuard ]] && MODPATH=/data/adb/modules/huzeASGuard || MODPATH=""
prop="${MODPATH}/module.prop"
LF='&#x000A;'
amp='&#38;'
quot='&#34;'

ASGuardUIversion='1.6.5'
ASGuardUIversionCode=202209041
updata_text1="修改部分描述${LF}新增APP使用手册条目"
new_version='v6.1'
new_versionCode=202209041
updata_text2="调整优化Auto模式运行逻辑${LF}修复已知bug${LF}提升AS列表内APP在Auto模式的优先级"
if [[ -n "${MODPATH}" ]] && [[ -d "${MODPATH}" ]]; then
	installed=1
	uninstalled=0
	if [[ -f "${prop}" ]]; then
	source "${prop}" >/dev/null 2>&1
	description=$(cat "${prop}" | grep 'description')
	description=${description#*=}
	inform="模块作者：沍澤\n模块版本：${version}(${versionCode})\n\n模块简介\n${description}\n\n模块信息路径：${prop}"
		if [[ "${new_versionCode}" -gt "${versionCode}" ]]; then
			updata=1
		else
			updata=0
		fi
	else
		updata=0
	fi
else
	installed=0
	uninstalled=1
	updata=0
fi
num1=$(echo "${AS}" | sed '/^$/d' | wc -l)
num2=$(echo "${exAS}" | sed '/^$/d' | wc -l)
num3=$(echo "${exclude}" | sed '/^$/d' | wc -l)
num4=$(echo "${package_whitelist}" | sed '/^$/d' | wc -l)

for var in $(echo ${exAS:-}); do
	result="$(dumpsys package ${var} | grep -s "ACCESSIBILITY_SERVICE" | sed 's/ /\n/g' | grep "${var}/" | sort | uniq)"
	if [[ -n "${result}" ]]; then
		result="$(echo "${result}" | sed "s:/\.:/${var}\.:g")"
		tmp="${tmp:-}${result} "
	fi
done
result="${tmp}"

cat <<EOF
<?xml version="1.0" encoding="UTF-8" ?>
<group>
	<text>
		<slice color="#FF6800">本应用为Magisk模块 无障碍服务守护(ASGuard) 的可视化配置界面，仅适配对应版本的模块</slice>
	</text>
	<text>
		<slice color="#FF6800">ASGuardUI ${ASGuardUIversion}(${ASGuardUIversionCode})</slice>
		<slice color="#FF6800" break="true">${updata_text1}</slice>
	</text>
	<text visible="echo ${uninstalled}">
		<slice color="#FF6800" bold="true">找不到模块安装目录！请检测是否（正确）安装！</slice>
		<slice color="#FF6800" bold="true">请确保/sdcard/Android/ASGuard.conf文件没有被手机管家或其他模块当做垃圾清理！</slice>
		<slice color="#FF6800" bold="true">面具包下载入口请点击 其它-下载完整包</slice>
	</text>
</group>
<group visible="[[ ${updata} -eq 1 ]] ${amp}${amp} rm -rf ./script/modulefiles/* ; echo ${updata}">
	<text>
		<slice color="#FF6800">更新版本 ${new_version}(${new_versionCode})</slice>
		<slice color="#FF6800" break="true">${updata_text2}</slice>
	</text>
	<resource dir="script/modulefiles"/>
	<action reload="true">
		<title>开始更新 [模块beta版本对应APP的更新入口将一直显示]</title>
		<desc>无需额外下载，免重启更新，新版模块文件已内置APP</desc>
		<set>
			if [[ -f './script/modulefiles/service.sh' ]] ${amp}${amp} [[ -f './script/modulefiles/module.prop' ]]; then
				echo '安装目录: '${MODPATH}
				echo '开始拷贝文件...'
				rm -rf ${MODPATH}/*
				cp -rvf ./script/modulefiles/* ${MODPATH}/
				echo '正在运行模块'
				if [[ \$(ps -ef | grep '/huzeASGuard/' | grep -v grep | wc -l) -eq '0' ]]; then
					sh ${MODPATH}/service.sh
				else
					echo '正在结束模块进程...'
					ps -ef | grep "huzeASGuard" | grep -v grep | awk '{print \$2}' | xargs kill -9
					echo '重新运行模块进程...'
					sh ${MODPATH}/service.sh
					sleep 1
				fi
				echo '完成'
				echo '移除释放的更新文件'
			else
				echo '更新资源文件已被移除，结束ASGuardUI进程以重新释放更新文件...'
			fi
		</set>
	</action>
</group>
<group>
	<switch shell="hidden" reload="true" title="无障碍服务守护(ASGuard) 开关" desc-sh="echo -e '${inform:-无内容}'">
		<get>
			if [[ ${installed} -eq 1 ]];then
				if [[ -f ${MODPATH}/disable ]]; then
					echo 0
				else
					if [[ \$(ps -ef | grep '/huzeASGuard/' | grep -v grep | wc -l) != '0' ]]; then
						echo 1
					else
						echo 0
					fi
				fi
			else
				echo 0
			fi
		</get>
		<set>
			if [[ \${state} -eq 0 ]]; then
				touch ${MODPATH}/disable
				ps -ef | grep '/huzeASGuard/' | grep -v grep | awk '{print \$2}' | xargs kill -9
			else
				[[ -f ${MODPATH}/disable ]] ${amp}${amp} rm ${MODPATH}/disable
				if [[ \$(ps -ef | grep 'ASGuard_Process.sh' | grep -v grep | wc -l) = '0' ]];then
					nohup sh ${MODPATH}/service.sh ${amp}
				fi
			fi
		</set>
		<lock>
			if [[ ${installed} -eq 1 ]]; then
				echo 0
			else
				echo '模块路径未找到启动文件，确保/sdcard/Android/ASGuard.conf文件没被清理掉'
			fi
		</lock>
	</switch>
</group>
<group>
	<resource file="script/WriteConfig.sh" />
	<action shell="hidden" reload="true">
		<title>运行模式 [当前: ${mode}]</title>
		<param name="mo" value-sh="source ${conf} ; echo \${mode}" required="true" title="#A(Auto): 自动管理开启相应无障碍功能，即使不配置AS也可使用，适用于大部分场景${LF}#M(Monitor): 持续监控无障碍服务的启用应用，将被关闭的无障碍服务重新开启${LF}#F(Focus): 选择该模式在开机时不会自动打开无障碍服务，直到指定的APP处于焦点窗口时若app未打开无障碍服务，则将其打开${LF}#R(Refresh): 该模式为定时刷新开启状态，适用于scene等轻度且使用无障碍功能的APP${LF}请根据实际使用情况选择模式，这样可以帮助你把更多的电量花在需要的地方">
			<option value="A">Auto</option>
			<option value="M">Monitor</option>
			<option value="F">Focus</option>
			<option value="R">Refresh</option>
		</param>
		<set>
			sh ./script/WriteConfig.sh 'mode' \${mo}
		</set>
	</action>
</group>
<group>
	<action shell="hidden" reload="true">
		<title>无障碍功能受保护APP [已配置${num1}个APP]</title>
		<desc>配置需要保护无障碍功能的APP (实时生效)</desc>
		<summary>在Auto模式具有最高优先级</summary>
		<param
			name="ASpackages"
			title="加入此项的APP不需要加入电池优化白名单APP列表"
			type="app"
			multiple="true"
			editable="false"
			value-sh="source ${conf} ; echo ${quot}\${AS}${quot}"/>
		<set>
			sh ./script/WriteConfig.sh 'AS' ${quot}\${ASpackages}${quot}
		</set>
	</action>
	<action shell="hidden" reload="true">
		<title>电池优化白名单APP [已配置${num4}个APP]</title>
		<desc>配置开机后加入电池优化白名单的APP (重启模块生效)</desc>
		<param
			name="WhitelistPackages"
			title="约在开机解锁90秒后添加，加入无障碍功能受保护APP列表则不需要加入此项"
			type="app"
			multiple="true"
			editable="false"
			value-sh="source ${conf} ; echo ${quot}\${package_whitelist}${quot}"/>
		<set>
			sh ./script/WriteConfig.sh 'package_whitelist' ${quot}\${WhitelistPackages}${quot}
		</set>
	</action>
	<action shell="hidden" reload="true">
		<title>监测周期 [当前设置: ${CTime}]</title>
		<desc>监测无障碍功能的频率周期 (当运行模式为R/M时有效)</desc>
		<param
			name="Time"
			title="M模式建议不要小于3，R模式建议不小于20，越小的数字意味着越高的性能开销，时间单位: M:秒 R:分钟"
			type="seekbar"
			min="1"
			max="60"
			value-sh="source ${conf} ; echo \${CTime}"/>
		<set>
			sh ./script/WriteConfig.sh 'CTime' \${Time}
		</set>
	</action>
</group>
<group>
	<action shell="hidden" reload="true">
		<title>过滤APP列表 [已指定${num2}个APP]</title>
		<desc>Auto模式下这些APP将被忽略</desc>
		<param
			name="exASpackages"
			title="当mode为A时过滤有效"
			type="app"
			multiple="true"
			editable="false"
			value-sh="source ${conf} ; echo ${quot}\${exAS}${quot}"/>
		<set>
			sh ./script/WriteConfig.sh 'exAS' ${quot}\${exASpackages}${quot}
		</set>
	</action>
	<action shell="hidden" reload="true">
		<title>过滤开关列表 [已指定${num3}个开关]</title>
		<desc>任何模式下这些APP的开关将被忽略，一般用于APP存在多个开关的情况</desc>
		<param name="exswitch" multiple="multiple" value-sh="source ${conf} ; echo ${quot}\${exclude}${quot} ;" option-sh="source ${conf} ; echo -e ${quot}${result} ${exclude}${quot} | sed 's: :\\n:g' | sort | uniq">
		</param>
		<set>
			sh ./script/WriteConfig.sh 'exclude' ${quot}\${exswitch}${quot}
		</set>
	</action>
</group>
<group>
	<switch shell="hidden">
		<title>清空电池优化白名单</title>
		<desc>开机90秒后将清空系统电池优化白名单并添加配置APP</desc>
		<summary>注意: 开启此功能可能会导致系统某些功能睡死，部分应用及桌面部件功能可能受影响</summary>
		<get>
			source ${conf}
			echo \${WhitelistCleaner}
		</get>
		<set>
			sh ./script/WriteConfig.sh 'WhitelistCleaner' \${state}
		</set>
	</switch>
	<switch shell="hidden">
		<title>抓取Log</title>
		<desc>一般用于检查模块流程的问题</desc>
		<get>
			source ${conf}
			echo \${log}
		</get>
		<set>
			sh ./script/WriteConfig.sh 'log' \${state}
		</set>
	</switch>
	<switch shell="hidden">
		<title>开机关闭所有无障碍</title>
		<desc>开机时关闭所有APP的无障碍服务</desc>
		<get>
			source ${conf}
			echo \${clean}
		</get>
		<set>
			sh ./script/WriteConfig.sh 'clean' \${state}
		</set>
	</switch>
</group>

EOF