#!/bin/bash
clear
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
trap 'echo -e "\nbye~"' EXIT
export PATH
svndata="/application/svndata/"
Yellow_font_prefix="\033[33m"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Font_color_suffix="\033[0m"
Flash_font="\033[5m"

PASSWD_FILE='/application/svnpasswd/passwd'
AUTHZ_FILE='/application/svnpasswd/authz'
function PRINT_USER() {
    echo
    echo "########User info#########"
	echo -e "[${Green_font_prefix}+${Font_color_suffix}]Username:${Red_font_prefix}$user${Font_color_suffix}"
	echo -e "[${Green_font_prefix}+${Font_color_suffix}]Password:${Red_font_prefix}$passwd${Font_color_suffix}"
    echo -e "[${Green_font_prefix}+${Font_color_suffix}]Group:${Red_font_prefix}${groupalias}${Font_color_suffix}"
	echo "##########################"
}
function RESTART() {
	{ pkill svn
	  svnserve -d -r ${svndata};
	} && echo -e "[${Green_font_prefix}+${Font_color_suffix}]Restart successful!" || \
	echo -e "[${Red_font_prefix}+${Font_color_suffix}]Restart failed" 
}
function WRITE_FILE() {
	########把用户密码及权限写到对应文件##########
	sed -i "/${type}/a${user} = ${passwd}" $PASSWD_FILE
	sed -i "/^${group}/s/$/&,${user}/g" $AUTHZ_FILE
}
function ADD_USER() {
while :;do

	while true;do
		echo -e -n "${Yellow_font_prefix}Input username:${Font_color_suffix}"
		read
		if [[ $REPLY =~ ^[[:lower:]]+[0-9]{4}$ ]];then
			if grep "${REPLY}" $PASSWD_FILE &>/dev/null;then
				echo "'$REPLY' already exist,please input again" && continue
			else
				user=$REPLY
				break
			fi
		else
			echo -e "[${Red_font_prefix}-${Font_color_suffix}]Sorry,username format error,must be name + job number,example:zhangsan0001"
			continue
		fi
	done

	while :;do
		echo -e -n "${Yellow_font_prefix}Input${Font_color_suffix} ${Red_font_prefix}'$user'${Font_color_suffix} ${Yellow_font_prefix}password:${Font_color_suffix}"
		read
		if grep -Po "^(?:(?=.*[0-9].*)(?=.*[A-Za-z].*))[\\W0-9A-Za-z]{6,16}$"<<<$REPLY &>/dev/null;then
 			passwd=$REPLY && break
		else
			echo -e "[${Red_font_prefix}-${Font_color_suffix}]Passwd is too simple,please input again" && continue
		fi
	done
	##########分配到对应组########
	while true;do
	    echo
		echo -e "[${Red_font_prefix}Group list:${Font_color_suffix}]"
		echo "1.Software group"
		echo "2.Hardware group"
		while :;do
			echo
			echo -e -n "[${Green_font_prefix}-${Font_color_suffix}]Add ${Red_font_prefix}'${user}'${Font_color_suffix} to what group?    [1 or 2]:"
			read group_num
			case ${group_num} in
				1)  
					groupalias="software group"
					group="sw_group"
					type="Soft"
					break 2
					;;
				2)
					groupalias="hardware group"
					group="hw_group"
					type="Hard"
					break 2
					;;
				*)
					echo "Input error,please input again!"
					continue
					;;
			esac
		done 
	done
	############把用户信息写进文件########
	PRINT_USER
	echo -e -n "[${Green_font_prefix}-${Font_color_suffix}]Enter any keyborad to add the user['q' to quit]>>>"
    read answer
	if [[ "${answer}" == 'q' || "${answer}" == 'Q' ]];then
		exit 0
	else
		WRITE_FILE && echo -e "[${Green_font_prefix}+${Font_color_suffix}]Add $user successful!"
	fi
	##########是否继续添加用户##########
	echo && read -p "Continue add user?    [Y/N]:" option
	case ${option} in
		Y|y)
			continue;;
		N|n)
			break;;
		*)
			echo -e "[${Red_font_prefix}-${Font_color_suffix}]Input error,plase input again!"
			echo
			continue;;
	esac
done
}
function CANCEL_USER() {
	while true;do
 		echo -e -n "${Yellow_font_prefix}Input Username:${Font_color_suffix}" 
		read user
		[ -n "$user" ] && \
        { 
            user_list=(
                $(for svn_user in $(awk 'NR>9&&$0!~/^#/{print $1}' $PASSWD_FILE);do  echo $svn_user;done)
            );
            if { for i in ${user_list[@]};do echo "$i";done|&grep -w "$user"; } &>/dev/null;then    	
            #########判断被注销用户是否存在############
			    while :;do
				    echo -e -n "[${Green_font_prefix}+${Font_color_suffix}]Cancel User:${Green_font_prefix}$user${Font_color_suffix}?   [Y/N]:"
				    read answer
			
				    case ${answer} in
				    Y|y)
					    { 	sed -ir "s/^\($user\)/#\1/" $PASSWD_FILE &&\						                ########注释passwd的用户
						  	sed -i "s/\(.*\),${user}\(.*\)/\1\2/g" $AUTHZ_FILE  &&\                     #######删除authz的用户							  
							echo -e "[${Green_font_prefix}+${Font_color_suffix}]Cancel '$user' successful!";
						} || echo -e "[${Red_font_prefix}-${Font_color_suffix}]Cancel '$user' failed,Please manual cancel it"
                        while true;do 
                            echo
                            read -p "Continue cancel user?   [Y/N]:" option
	                        case ${option} in
		                        Y|y)
			                        continue 3;;   ###########退出到输出用户名的while循环
		                        N|n)
			                        exit 0;;
		                        *)
			                        echo -e "[${Red_font_prefix}-${Font_color_suffix}]Input error,plase input again!" && echo		                
			                        continue;;
	                        esac
                        done;;
				    N|n)
					    exit 0
                        ;;
				    *)
					    echo -e "[${Red_font_prefix}-${Font_color_suffix}]Input error,plase input again!" && echo
					    continue
                        ;;
				    esac && break
			    done	
		    else
				    echo -e "[${Red_font_prefix}-${Font_color_suffix}]'$user' not exist,please input again"	
				    echo
				    continue
		    fi; 
            } || continue
	done
}
echo -e "##############${Red_font_prefix}svn user manager script${Font_color_suffix}###############"
cat <<- EOF
#1.Add svn user                                    #             
#2.Cancel svn user                                 #
#3.Restart svn service                             #
####################################################
EOF
while :;do
    echo
	echo -e -n "[${Green_font_prefix}+${Font_color_suffix}]Input Option:"
    read option
	if [ "${option}" == "1" ];then
		ADD_USER
		break
	elif [ "${option}" == "2" ];then
		CANCEL_USER
		break
	elif [ "${option}" == "3" ];then
		RESTART
		break
	else
		echo -e "[${Red_font_prefix}-${Font_color_suffix}]Input error,plase input again!"
		echo
		continue
	fi
done

