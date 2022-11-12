alias ls="ls -alh"

lss () {
    ls -ald /nix/store/* | grep $@
}

demo () {
    python ./demos/dc-demo.py
    python ./demos/helloworld.py -M 3
}

if command -v fzf-share >/dev/null; then
  source "$(fzf-share)/key-bindings.bash"
  source "$(fzf-share)/completion.bash"
fi

PS1='\w\$ '
