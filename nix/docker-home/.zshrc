alias ls="ls -alh"

lss () {
    ls -ald /nix/store/* | grep $@
}

demo () {
    python ./demos/dc-demo.py
    python ./demos/helloworld.py -M 3
}

if [ -n "${commands[fzf-share]}" ]; then
  source "$(fzf-share)/key-bindings.zsh"
  source "$(fzf-share)/completion.zsh"
fi

PS1='\w\$ '

