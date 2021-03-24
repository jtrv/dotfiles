#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

PATH="~/bin:${PATH}"
export PATH

alias config='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
