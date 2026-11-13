# BEGIN ATOMIC-MOD SETTINGS
export BASH_IT="$HOME/.bash_it"
 
export THEME_SHOW_SCM=true
export THEME_SHOW_CLOCK=true
export THEME_SHOW_BATTERY=false
export THEME_SHOW_EXITCODE=false
export THEME_CLOCK_FORMAT="%a %b %d - %H:%M"
# END ATOMIC-MOD SETTINGS
 
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

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

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

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
#if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
#    . /etc/bash_completion
#fi
 
# BEGIN BASH-IT LOADER
if [[ -r "$BASH_IT/bash_it.sh" ]]; then
export BASH_IT_THEME="zork-mod"
    source "$BASH_IT/bash_it.sh"
fi
# END BASH-IT LOADER
 
# BEGIN SET-THEME
set-theme() {
    local theme="${1:-}"
    local theme_directory=""
    local temporary_file=""
 
    if [[ -z "$theme" ]]; then
        printf 'Usage: set-theme THEME_NAME\n'
        printf 'Example: set-theme atomic-mod\n\n'
        printf 'Available themes:\n'
 
        find "$BASH_IT/themes" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            -printf '  %f\n' 2>/dev/null |
            sort
 
        return 1
    fi
 
    theme_directory="$BASH_IT/themes/$theme"
 
    if [[ ! -d "$theme_directory" ]]; then
        printf 'ERROR: Bash-it theme not found: %s\n' "$theme" >&2
        printf 'Run "bash-it preview" to preview available themes.\n' >&2
        return 1
    fi
 
    if ! find "$theme_directory" \
        -maxdepth 1 \
        -type f \
        -name '*.theme.bash' |
        grep -q .; then
 
        printf 'ERROR: No theme file was found in: %s\n' \
            "$theme_directory" >&2
        return 1
    fi
 
    cp -a "$HOME/.bashrc" \
        "$HOME/.bashrc.before-theme-change.$(date +%Y%m%d-%H%M%S)"
 
    temporary_file="$(mktemp)"
 
    awk -v selected_theme="$theme" '
        BEGIN {
            changed = 0
        }
 
        /^[[:space:]]*export BASH_IT_THEME=/ && changed == 0 {
            printf "export BASH_IT_THEME=\"%s\"\n", selected_theme
            changed = 1
            next
        }
 
        {
            print
        }
 
        END {
            if (changed == 0) {
                printf "\nexport BASH_IT_THEME=\"%s\"\n", selected_theme
            }
        }
    ' "$HOME/.bashrc" > "$temporary_file"
 
    mv "$temporary_file" "$HOME/.bashrc"
 
    printf 'Bash-it theme changed to: %s\n' "$theme"
    exec bash
}
# END SET-THEME
bind '"\C-l": clear-screen'


# ZORK CUSTOM PROMPT START
if [[ "$BASH_IT_THEME" == "zork" ]]; then
    [[ -f /root/.zork-gold-prompt.sh ]] && source /root/.zork-gold-prompt.sh
    [[ -f /root/.zork-mod-finalize.sh ]] && source /root/.zork-mod-finalize.sh
fi
# ZORK CUSTOM PROMPT END

