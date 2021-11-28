#!/usr/bin/env bash

#######################
# Functions
#######################

get_miner_uptime(){
  local a=0
  let a=`date +%s`-`stat --format='%Y' $1`
  echo $a
}

get_log_time_diff(){
  local a=0
  let a=`date +%s`-`stat --format='%Y' /var/log/miner/hellminer/hellminer.log`
  echo $a
}

#######################
# MAIN script body
#######################
# Calc log freshness
local diffTime=`get_log_time_diff`
local maxDelay=120
echo "diffTime $diffTime"
if [ "$diffTime" -lt "$maxDelay" ]; then
	khs=0
	log="/tmp/hellminer.log"

	now=`date +%s`
	i=0
	lastUpdate=`stat -c %Y $log`
	refresh=$(($now - $lastUpdate))
	if [[ $refresh -le 15 ]]; then
		hrPart=`tail -n 100 $log | grep "Total system hashrate" | tail -n 1`
		hrRaw=`echo $hrPart | sed 's/.*Total system hashrate \([.0-9]*\).*/\1/'`
		if [[ ! -z $hrRaw ]]; then
			x=1
			hs[$i]=`echo "scale=2; $hrRaw * $x / 2000" | bc -l`
		else
			hs[$i]=0
		fi
		fan[$i]=0
		temp[$i]=0
		khs=`echo "scale=0; $khs + ${hs[$i]} * 1000" | bc -l`
	fi

	local log_name="$MINER_LOG_BASENAME.log"
	local ver=`miner_ver`

	local hs_units='mhs' # hashes utits
	algo='verushash'
	local uptime=`get_miner_uptime $log` # miner uptime

	stats=$(jq -nc \
		--argjson hs "`echo ${hs[@]} | tr " " "\n" | jq -cs '.'`" \
		--argjson bus_numbers "`echo ${bus_numbers[@]} | tr " " "\n" | jq -cs '.'`" \
		--arg uptime "$uptime" \
		--arg ver "$ver" \
		--arg hs_units "$hs_units" \
		--argjson fan "`echo ${fan[@]} | tr " " "\n" | jq -cs '.'`" \
		--argjson temp "`echo ${temp[@]} | tr " " "\n" | jq -cs '.'`" \
		'{$hs, $bus_numbers, $uptime, $hs_units, $ver, $fan, $temp}')

else
  stats=""
  khs=0
fi
