# If not in tmux, start tmux
#if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
#  exec tmux
# fi

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

export EDITOR=/usr/local/bin/vim

export PATH=~/.local/bin:/usr/sandbox/:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/usr/share/games:/usr/local/sbin:/usr/sbin:/sbin:$PATH
# export TERM=screen-256color
# Cant be bothered to re-color vim and others, sticking with 8col for now

PS1="\[\e[0;31m\][\[\e[0;37m\]\u\[\e[0;33m\]@\[\e[0;36m\]\h\[\e[0;31m\]]\[\e[0;31m\]-\[\e[0;31m\][\[\e[0;32m\]\W\[\e[0;31m\]]\[\e[0;33m\] $ \[\e[0m\]"

#change blinking block to blinking | in xterm
echo -e -n "\x1b[\x35 q"

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# Colored Prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# Set 'man' colors
if [ "$color_prompt" = yes ]; then
        man() {
        env \
        LESS_TERMCAP_mb=$'\e[01;31m' \
        LESS_TERMCAP_md=$'\e[01;31m' \
        LESS_TERMCAP_me=$'\e[0m' \
        LESS_TERMCAP_se=$'\e[0m' \
        LESS_TERMCAP_so=$'\e[01;44;33m' \
        LESS_TERMCAP_ue=$'\e[0m' \
        LESS_TERMCAP_us=$'\e[01;32m' \
        man "$@"
        }
fi

unset color_prompt force_color_prompt

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more aliases
alias ll='ls -lhF --color=auto'
alias la='ls -laF --color=auto'
alias l='ls -CF --color=auto'
alias em='emacs -nw'
alias dd='dd status=progress'
alias sudo='doas'
alias please='doas'
alias fucking='doas'
alias x='exit'
alias ffox='flatpak run org.mozilla.firefox'
alias fseal='flatpak run com.github.tchx84.Flatseal'
alias s='dbus-launch --exit-with-session sway'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# for sway
XDG_CONFIG_HOME=~/.config
# for ruby
export PATH="/home/me/.local/share/gem/ruby/3.0.0/bin:$PATH"
# for local binaries / scripts
export PATH="~/bin:$PATH"

# For ANSI posting on irc
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# change 'hostname' to joe lol
echo -e -n "\e]2;thiccpad\e\\"
