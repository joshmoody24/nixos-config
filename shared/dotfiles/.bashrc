# .bashrc

# Source home-manager session variables (EDITOR, VISUAL, etc.)
if [ -f ~/.nix-profile/etc/profile.d/hm-session-vars.sh ]; then
    . ~/.nix-profile/etc/profile.d/hm-session-vars.sh
fi

# Include nix profile in data dirs so bash-completion can find
# completions for nix-installed packages (e.g. git)
if [ -d ~/.nix-profile/share ]; then
    export XDG_DATA_DIRS="$HOME/.nix-profile/share${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}:/usr/local/share:/usr/share"
fi

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
elif [ -f /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

# Enable bash completion (commented out in Ubuntu's /etc/bash.bashrc by default)
if [ -z "$BASH_COMPLETION_VERSINFO" ] && [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# Function to set cursor shape
function set_cursor_shape() {
  case "$1" in
    block)
      echo -ne "\e[2 q" ;; # Block cursor
    line)
      echo -ne "\e[6 q" ;; # Line cursor
  esac
}

set -o vi
bind '"jk":vi-movement-mode'

# custom colors
PS1='\[\e[32m\]\u\[\e[32m\] \[\e[34m\]\W\[\e[0m\] \$ '

# allow for extensions at the host level
[ -f ~/.bashrc.local ] && source ~/.bashrc.local
