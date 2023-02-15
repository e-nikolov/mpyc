#!/bin/sh
# docker compose down --remove-orphans

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

    args+=" -P $host-docker:$port" 
done < "$hosts"

if [ $MY_PID = -1 ]
then
    echo Only $i parties are allowed. $HOSTNAME will not participate in this MPC session
else

cd demos

cmd=$*

if [ -z "$cmd" ]
then
    cmd="python ./secretsanta.py"
    # cmd="python ./np_cnnmnist.py 1.5"
fi

cmd="$cmd \
    --log-level debug \
    -I ${MY_PID} \
    ${args}"

docker compose up -d tailscale
sleep 2

echo docker compose up --rm demo \"$cmd\"

docker compose run --rm demo "$cmd"

fi
