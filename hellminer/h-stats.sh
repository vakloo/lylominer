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
#/tmp/rrminer/rrminer.0b.log
# Calc log freshness
local diffTime=`get_log_time_diff`
local maxDelay=120
echo "diffTime $diffTime"
if [ "$diffTime" -lt "$maxDelay" ]; then
	khs=0
	logs=(`find /tmp/rrminer/ -name rrminer.*.log | sort`)

	count=${#logs[@]}
	now=`date +%s`
	for ((i=0; $i < $count; i++)); do
		log=${logs[$i]}
		bus_number=`echo $log | sed 's#/tmp/rrminer/rrminer.##' | sed 's/.log//'`
		bus_numbers[$i]=`printf "%d" 0x$bus_number`
		hr[$i]=0
		lastUpdate=`stat -c %Y $log`
		refresh=$(($now - $lastUpdate))
		if [[ $refresh -le 15 ]]; then
			hrPart=`tail -n 100 $log | grep speed | tail -n 1`
			hrRaw=`echo $hrPart | sed 's/.*speed: \([.+0-9e]*\).*/\1/'`
			if [[ ! -z $hrRaw ]]; then
				if [[ `echo $hrRaw | grep -c 'e+'` -gt 0 ]]; then
					hsR=`echo "scale=0; $hrRaw " | sed 's/e+/*10^/' | bc -l`
					hs[$i]=`echo "scale=0; $hsR / 1000000" | bc -l`
				else
					x=1000
					if [[ `echo $hrPart | grep -c 'Mhash'` -gt 0 ]]; then
						x=1
					elif [[ `echo $hrPart | grep -c 'Ghash'` -gt 0 ]]; then
						x=0.1
					fi

					hs[$i]=`echo "scale=0; $hrRaw * $x" | bc -l`
				fi
			else
				hs[$i]=0
			fi
			fan[$i]=0
			temp[$i]=0
			khs=`echo "scale=0; $khs + ${hs[$i]} * 1000" | bc -l`
		fi

	done

	local log_name="$MINER_LOG_BASENAME.log"
	local ver=`miner_ver`

	local hs_units='mhs' # hashes utits
	algo='verushash'
	local uptime=`get_miner_uptime /tmp/rrminer` # miner uptime

	echo "hs ${hs[@]}"
	echo "hsStr $hsStr"
	echo "hs_units $hs_units"
	echo "uptime $uptime"
	echo "algo $algo"
	echo "bus_numbers ${bus_numbers[@]}"
	echo "bus_numbers2 ${bus_numbersStr[@]}"

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
