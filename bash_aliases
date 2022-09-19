# Colorized prompt
if [ $UID != 0  ] ; then
	PS1="\[\e[32;1m\]\u@\[\e[31;1m\]\h\[\033[00m\]:\[\033[01;33m\]\w\[\033[00m\]\\$ "
else
	PS1="\[\e[31;1m\]\u@\[\e[31;1m\]\h\[\033[00m\]:\[\033[01;33m\]\w\[\033[00m\]\\$ "
fi

# append each command to the history
PROMPT_COMMAND="history -a; history -n"

# Colorized grep
alias grep='grep --color=auto'
export GREP_COLORS='mt=1;32:ne'

LESS_VERSION="$(less --version | sed -n -e 's/less \([0-9]\+\) .*/\1/p')"
LESS_F=$( [ "$LESS_VERSION" -ge 530 ] && echo "less --quit-if-one-screen" || echo "less")

g() {
    `which grep` --color=always "$@" | $LESS_F -R
}

gr() {
    g -r "$@"
}

gre() {
    g -r --exclude-dir venv --exclude-dir .svn --exclude-dir .git --exclude "*.pyc" "$@"
}

export EDITOR=vim
export VISUAL=vim

alias lh='ls -lh'
alias lth='ls -lth'
alias lth20='ls -lth | head -20'

alias dfh='df -h'

addpath() {
    if [ ! -d "$1" ] ; then
        echo "directory '$1' doesn't exist'"
        return 1
    fi
    newp=$(readlink -f "$1")
    if ! echo $PATH | grep -E -q "(^|:)$newp($|:)" ; then
        export PATH="$newp:$PATH"
    else
        echo "directory '$newp' is already present in PATH"
    fi
    return 0
}

rmpath() {
    p2del=$(readlink -f "$1")
    export PATH="$(echo $PATH | sed -e "s;\(^\|:\)$p2del\(:\|\$\);\1\2;g" -e 's;^:\|:$;;g' -e 's;::;:;g')"
}

mkscreen() {
    if [ ! -z "$1" ] ; then
        mkdir -p "$HOME/screen/$1" && cd "$HOME/screen/$1" && screen -S "$1"
    else
        screen -S "$(basename "$PWD")"
    fi
}

alias slist='screen -list'

pushsshsock() {
    [ -S "$SSH_AUTH_SOCK" ] && ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/shared_auth_sock"
}

pullsshsock() {
    export SSH_AUTH_SOCK="$HOME/.ssh/shared_auth_sock"
}

ssh-persist() {
    host="$1" ; shift
    if ! ssh -q -O check "$host" 2>/dev/null ; then
        ( set -x ; ssh -MNf "$host" )
    fi
}

svndiff() {
    svn diff --diff-cmd=colordiff "$@" | $LESS_F -R
}

svninf() {
    svn up --parents --set-depth=infinity "$@"
}

pastecol() {
    paste -d '|' "$@" | column -t -s '|'
}

alias nocolor='sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g ; s/\x0f//g"'
alias nogarbage='tr -cd "[:print:]\n"'

alias urlencode='perl -pe '\''s/([^A-Za-z0-9\n])/sprintf("%%%02X", ord($1))/seg'\'
alias urldecode='perl -pe '\''s/\+/ /g; s/%([[:xdigit:]]{2})/chr(hex($1))/ge'\'

alias cgidecode='perl -pe '\''s/[?&]/\n/g'\'' | urldecode'

alias pullrc=". $HOME/.bashrc"

alias dug='( shopt -s dotglob ; du -csh * | grep G )'
