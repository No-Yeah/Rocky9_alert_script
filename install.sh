#!/bin/bash

#===========================================#
#      public 함수 또는 변수 선언 구간      #
#===========================================#
# 문자열 일치 함수
chk_str() {
 if [ "$1" != "$2" ]; then
         echo "NOT MATCHED $3 !!!"
         exit 0
 else echo "MATCHED $3 !!!"
 fi
}

# 입력 값으로 token 및 ids 변경
change_value() {
	# $1 변경항목분류 (ids|token)
	# $2 value 
	# $3 file name
	case $1 in
		ids)
			sed -i "s/IDS=\"\"/IDS=\"$2\"/" $3
			;;
		token)

			sed -i "s/KEY=\"\"/KEY=\"$2\"/" $3
			;;
	esac	
}
#===========================================#

clear

# API TOKEN 값 만들기
echo "
 ▄▄▄       ██▓    ▓█████  ██▀███  ▄▄▄█████▓ ▄▄▄▄    ▒█████  ▄▄▄█████▓
▒████▄    ▓██▒    ▓█   ▀ ▓██ ▒ ██▒▓  ██▒ ▓▒▓█████▄ ▒██▒  ██▒▓  ██▒ ▓▒
▒██  ▀█▄  ▒██░    ▒███   ▓██ ░▄█ ▒▒ ▓██░ ▒░▒██▒ ▄██▒██░  ██▒▒ ▓██░ ▒░
░██▄▄▄▄██ ▒██░    ▒▓█  ▄ ▒██▀▀█▄  ░ ▓██▓ ░ ▒██░█▀  ▒██   ██░░ ▓██▓ ░ 
 ▓█   ▓██▒░██████▒░▒████▒░██▓ ▒██▒  ▒██▒ ░ ░▓█  ▀█▓░ ████▓▒░  ▒██▒ ░ 
 ▒▒   ▓▒█░░ ▒░▓  ░░░ ▒░ ░░ ▒▓ ░▒▓░  ▒ ░░   ░▒▓███▀▒░ ▒░▒░▒░   ▒ ░░   
  ▒   ▒▒ ░░ ░ ▒  ░ ░ ░  ░  ░▒ ░ ▒░    ░    ▒░▒   ░   ░ ▒ ▒░     ░    
  ░   ▒     ░ ░      ░     ░░   ░   ░       ░    ░ ░ ░ ░ ▒    ░      
      ░  ░    ░  ░   ░  ░   ░               ░          ░ ░           
      ░                  
					Last Update : 2024-04-25 KST
"

echo " "
echo " "

sleep 1

read -s -p "Telegram Bot API Token 값을 입력하세요." api_token
echo " "
echo "입력한 값이 ${api_token} 이 맞습니까? (Y/N ※ Only uppercase)"
read yesno

if [ "$yesno" == "Y" ] || [ "$yesno" == "y" ] ; then
        echo "token get success !!!"
else
	echo "Please, restart the script !!!" 
	exit 0
fi
               
echo " " 

echo "Telegram 받을 계정의 ID 값을 입력하세요."
echo "다수의 ID 값은 , 로 구분합니다. (ex. 1234567,6754321,10111213)" 
echo ""
read telegram_ids

echo " "
echo "입력한 값이 ${telegram_ids} 이 맞습니까? (Y/N ※ Only uppercase)"
read yesno

if [ "$yesno" == "Y" ] || [ "$yesno" == "y" ] ; then
        echo "telegram ids get success !!!"
else
        echo "Please, restart the script !!!"
        exit 0
fi

echo " " 

clear

echo "설치를 시작합니다."

sleep 2

clear

# 운영 체제 검사 후 Rocky 9이 아닐 경우 스크립트를 종료합니다.
OS_get=$(cat /etc/os-release | grep PRETTY_NAME | awk -F '"' '{print $2}' | awk '{print $1, $2, int($3)}')

echo "Checking OS..."

sleep 1 

chk_str "$OS_get" "Rocky Linux 9" "OS"

# root 권한인지 확인
USER_get=$(whoami)
echo "Checking Administrator..."

sleep 2

chk_str "$USER_get" "root" "Root privileges"

# 필요 패키지 먼저 설치 
dnf install -y dnf-utils http://rpms.remirepo.net/enterprise/remi-release-9.rpm
geo_pk_get=$(rpm -qa | grep -w GeoIP | wc -l)
if [ $geo_pk_get -lt 3 ]; then
dnf install -y GeoIP GeoIP-devel GeoIP-data zlib-devel
fi
inotyfy_pk_get=$(rpm -qa | grep -w inotify-tools | wc -l)
if [ $inotyfy_pk_get -eq 0 ]; then
dnf install -y inotify-tools
fi

# /root/bin 폴더 생성
mkdir -p /root/bin

# /etc/profile 설정 추가
source /etc/profile
rip_get=`echo $remoteip | wc -l`
setcmd_get=`cat '/etc/profile' | grep "readonly PROMPT_COMMAND" | wc -l`

echo "Checking environment..."

sleep 1

if [ $rip_get -eq 0 ] || [ $setcmd_get -eq 0 ] ; then 
echo "making /etc/profile good!!!"
echo -e "remoteip=\$(hostname -I) \n
if [[ -z \$remoteip ]]; then remoteip=localhost; fi \n
export PROMPT_COMMAND='RETRN_VAL=\$?;logger -p local6.debug \"\$(whoami) \$remoteip [$$] [\$RETRN_VAL] [\$PWD]: \$(history 1 | sed \"s/^[ \\t]*[0-9]\\+[ \\t]*//\")\"' \n
readonly PROMPT_COMMAND" >> /etc/profile
else echo "MATCHED /etc/profile!!!"
fi

source /etc/profile

# sshd login alert 스크립트
echo "making ssh login alert sh..."

cat << 'EOF' > /etc/profile.d/sshd-login-telegram.sh
#!/usr/bin/env bash
# Telegram Bot send
# Dev / jsh
# Update / 2018.08.30
#
#####################################################################
#
# 여러 사용자의 텔레그램 ID를 쉼표로 구분하여 추가합니다.
# 예: IDS="12345678,87654321,98765432"
IDS=""
KEY="" ## API Token Value
URL="https://api.telegram.org/bot${KEY}/sendMessage"
DATE="$(date "+%Y-%m-%d %H:%M")"
#
####################################################################
CLIENT_IP=$(echo $SSH_CLIENT | awk '{print $1}')
SRV_HOSTNAME=$(hostname -f)
SRV_IP=$(hostname -I | awk '{print $1}')
#PUB_IP=$(curl ifconfig.me | awk '{print $1}')
if [ -n "$CLIENT_IP" ]; then
    GEO=$(geoiplookup $CLIENT_IP | grep "Country" | awk -F, '{print $2}')
    TEXT="$SRV_IP SSH Connection / User=${USER} / Client IP *${CLIENT_IP}* $GEO / Date: ${DATE}"
else
    TEXT="$SRV_IP SSH Connection / User=${USER} / Date: ${DATE}"
fi
# 각각의 ID에 대해 알림을 보냅니다.
for ID in $(echo $IDS | tr ',' '\n'); do
    curl -s -d "chat_id=$ID&text=${TEXT}&disable_web_page_preview=true&parse_mode=markdown" $URL > /dev/null
done
EOF

change_value "ids" "${telegram_ids}" "/etc/profile.d/sshd-login-telegram.sh"
change_value "token" "${api_token}" "/etc/profile.d/sshd-login-telegram.sh"

sleep 1

chmod +x /etc/profile.d/sshd-login-telegram.sh

# command alert 스크립트
echo "making cmd alert sh..."
touch /var/log/.cmd.log
cat << 'EOF' > /root/bin/command-history-telegram.sh
#!/bin/bash
IDS=""
KEY="" ## API Token Value
URL="https://api.telegram.org/bot${KEY}/sendMessage"
# inotifywait로 파일 시스템 이벤트를 실시간으로 모니터링합니다.
tail -n0 -F /var/log/.cmd.log | while read -r line; do
    # 새로운 라인을 읽어와서 텔레그램으로 전송합니다.
    log="$line"
    # _ OK
    # log_escaped=$(printf '%s' "$log" | sed 's/\//\\\//g; s/_/\\_/g')
    log_escaped=$(printf '%s' "$log" | sed 's/_/\\_/g')
    # 로그를 전송합니다.
    for ID in $(echo $IDS | tr ',' '\n'); do
        curl -s -d "chat_id=$ID&text=${log_escaped}&disable_web_page_preview=true&parse_mode=markdown" $URL > /dev/null
    done
done 
EOF

change_value "ids" "${telegram_ids}" "/root/bin/command-history-telegram.sh"
change_value "token" "${api_token}" "/root/bin/command-history-telegram.sh"

sleep 1

chmod +x /root/bin/command-history-telegram.sh

# making service daemon file
cat << 'EOF' > /etc/systemd/system/command-history-telegram.service
[Unit]
Description=Command History Telegram Service
After=network.target
[Service]
Type=simple
ExecStart=/root/bin/command-history-telegram.sh
[Install]
WantedBy=multi-user.target
EOF

systemctl enable command-history-telegram --now

echo "local6.*                        /var/log/.cmd.log" >> /etc/rsyslog.conf

source /etc/profile
systemctl enable rsyslog
systemctl restart rsyslog

sleep 1

# making logout alert 스크립트
cat << 'EOF' > /etc/bash.bash_logout
#!/bin/bash
# Telegram Bot 설정
IDS=""
KEY="" ## API Token Value
URL="https://api.telegram.org/bot${KEY}/sendMessage"
# Get user information
USER=$(whoami)
#REMOTE_ADDR=$(who -m --ips | awk '{print $5}')
REMOTE_ADDR=$(curl -s ifconfig.me)
DATE="$(date "+%Y-%m-%d %H:%M")"
# Create message for Telegram
MESSAGE="User $USER logged out. Remote address: $REMOTE_ADDR / Date: ${DATE}"
# Send notification to Telegram for each user ID
for ID in $(echo $IDS | tr ',' '\n'); do
    curl -s -d "chat_id=$ID&text=${MESSAGE}&disable_web_page_preview=true&parse_mode=markdown" $URL > /dev/null
done
EOF

change_value "ids" "${telegram_ids}" "/etc/bash.bash_logout"
change_value "token" "${api_token}" "/etc/bash.bash_logout"

systemctl restart command-history-telegram
