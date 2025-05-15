# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
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
