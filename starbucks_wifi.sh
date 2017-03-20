#!/bin/sh

TARGET_WIFI="at_STARBUCKS_Wi2"

function connect_STARBUCKS_WiFi() {	

	# 接続可能なWi-Fiを取得
	WIFI_DEV_NAME=$(networksetup -listallhardwareports | grep -w Wi-Fi -A1 | awk '/^Device:/{ print $2 }')
	if [ -z "${WIFI_DEV_NAME}" ]; then
	  echo "Wi-Fi device not found!"
	  return
	fi

	# スタバWi-Fiと繋がっているか
	COUNT=`networksetup -getairportnetwork ${WIFI_DEV_NAME} | grep -c ${TARGET_WIFI}`
	if [ $COUNT -eq 1 ]; then
		echo "Wifi is already connecting ${TARGET_WIFI}."
		return
	fi

	# Wi-Fiの電源が入っていなければONにする
	POWER_ON_WAIT=1
	networksetup -getairportpower ${WIFI_DEV_NAME} | grep -wiq 'off'
	if [ $? -eq 0 ]; then
		echo "WiFi is off, turned on."
		networksetup -setairportpower ${WIFI_DEV_NAME} on
		if [ $? -ne 0 ]; then
			echo "Failed to power on ${WIFI_DEV_NAME}."
	    	exit 3
	    fi
	    sleep ${POWER_ON_WAIT}
	fi

	# スタバWi-Fiがあるか
	AIRPORT_CMD='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport'
	AIRPORT_COUNT=`${AIRPORT_CMD} -s ${TARGET_WIFI} | grep -c ${TARGET_WIFI}`
	if [ $AIRPORT_COUNT -lt 1 ]; then
		echo "${TARGET_WIFI} not found."
		exit 4
	else
		echo "${TARGET_WIFI} found."
	fi

	# 接続リトライ回数/リトライ間隔秒数
	CONNECTION_RETRY=3
	RETRY_INTERNAL=2
	# 接続する
	remain=${CONNECTION_RETRY}
	while [ ${remain} -gt  0 ]
	do
	  # networksetup -setairportnetwork は成功時も失敗時も0を返してくるので出力で判断
	  networksetup -setairportnetwork ${WIFI_DEV_NAME} ${TARGET_WIFI} | grep -wq 'Error'
	  if [ $? -ne 0 ]; then
	    break
	  fi
	  ((remain--))
	  sleep ${RETRY_INTERNAL}
	done
	if [ ${remain} -eq 0 ]; then
	  echo "Failed to join the network. Password may be incorrect."
	  exit 5
	fi	
}

# main
while [ $? == 0 ]
do
  ping -c 1 8.8.8.8
  while [ $? == 0 ]
  do
    sleep 1s
    ping -c 1 8.8.8.8
  done
  connect_STARBUCKS_WiFi
  sleep 20s
done