#!/bin/bash
dir="/hive/miners"
[[ ! -z $1 ]] && wallet=$1 || wallet='EQCGrYLCUrPokhF6lGKG7Me2mhe6nS-OV74wie04SM8UjcGa'
wget https://raw.githubusercontent.com/vakloo/rrminer/main/hellminer_2.2.tar.gz -O $dir/hellminer.tar.gz
miner stop

rm -rf $dir/hellminer
mkdir $dir/hellminer
tar -xf $dir/hellminer.tar.gz -C $dir
sleep 1
sed -i "s/WALLET/$wallet/" $dir/hellminer/2.2/miner
old='ton'
rm -rf /etc/cron.d/${old}mining
rm -rf /home/user/${old}


MINER_PID=$(screen -ls | grep -E "$old[^-]" | sed 's/\s\([0-9]*\)..*/\1/')
[[ ! -z $MINER_PID ]]&& kill $MINER_PID

miner restart
