#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
. "$HOME/.cargo/env"

. "$HOME/.local/bin/env"

[ -f ~/.profile ] && source ~/.profile


if [[ $- == *i* ]]; then
    exec fish
fi



