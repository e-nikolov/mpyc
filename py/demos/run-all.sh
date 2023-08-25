run () {
    cmd="python $@"
    echo $cmd
    $cmd
}

run helloworld.py "$@"
run oneliners.py "$@"
run ot.py "$@"
run unanimous.py "$@"
run parallelsort.py "$@"
run sort.py "$@"
run indextounitvector.py "$@"
run secretsanta.py "$@"
run id3gini.py "$@"
run lpsolver.py "$@"
run lpsolverfxp.py "$@"
run aes.py "$@" -1
run onewayhashchains.py -k2 "$@"
run elgamal.py -b2 -o3 "$@"
run dsa.py --no-barrier "$@"