#!/bin/sh

MAX_PARTIES=3
hosts="./hosts.pssh"

i=0
MY_PID=-1

args=""
while IFS= read -r line
do
    if [ $i -ge $MAX_PARTIES ]
    then
        break
    fi

    host=${line#"root@"}

    if [ "$host" = "$HOSTNAME" ]
    then
        MY_PID=$i
    fi
    ((i = i + 1))

    args+=" -P $host:11377" 
done < "$hosts"

if [ $MY_PID = -1 ]
then
    echo Only $MAX_PARTIES parties are allowed. $HOSTNAME will not participate in this MPC session
else

# cmd="python ./demos/helloworld.py --log-level debug \
#     -I ${MY_PID} \
#     ${args}"

cmd="python ./demos/secretsanta.py --log-level debug \
    -I ${MY_PID} \
    ${args}"

echo $cmd
$cmd

fi