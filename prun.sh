#!/bin/sh

MAX_PARTIES=600
hosts="./hosts.pssh"
port=11598

i=0
MY_PID=-1

args=""
while IFS= read -r line
do
    if [ $i -ge $MAX_PARTIES ]
    then
        break
    fi
    if [ -z "$line" ]
    then 
        break
    fi

    host=${line#"root@"}

    if [ "$host" = "$HOSTNAME" ]
    then
        MY_PID=$i
    fi
    ((i = i + 1))

    args+=" -P $host:$port" 
done < "$hosts"

if [ $MY_PID = -1 ]
then
    echo Only $i parties are allowed. $HOSTNAME will not participate in this MPC session
else

cd demos

# cmd="python ./np_cnnmnist.py 1.5 --log-level debug \
cmd="python ./secretsanta.py --log-level debug \
    -I ${MY_PID} \
    ${args}"

echo $cmd
$cmd

fi
