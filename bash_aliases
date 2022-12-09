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

alias nocolor='sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g ; s/\x0f//g"'
alias nogarbage='tr -cd "[:print:]\n"'

LESS_VERSION="$(less --version | sed -n -e 's/less \([0-9]\+\) .*/\1/p')"
LESS_F=$( [ "$LESS_VERSION" -ge 530 ] && echo "less --quit-if-one-screen" || echo "less")

unalias l
l() {
    if [ -t 1 ] ; then
        $LESS_F -R
    else
        nocolor
    fi
}

g() {
    `which grep` --color=always "$@" | l
}

gr() {
    g -r "$@"
}

GRE_EXCLUDE='--exclude *.pyc --exclude *.min.js --exclude *.min.css --exclude *.css.map --exclude *.log'
GRE_EXCLUDE_DIR='--exclude-dir venv --exclude-dir node_modules --exclude-dir .svn --exclude-dir .git'
gre() {
    # Need "set -f" to disable glob expansion for the "*.pyc" and other exclude patterns.
    # But we do need the word splitting though, this is why simple quoting "$GRE_EXCLUDE" won't work.
    # And you still can do the "gre *.txt" because the glob expansions happens earlier.
    (set -f; g -r $GRE_EXCLUDE $GRE_EXCLUDE_DIR "$@")
}

grh() {
    find $HOME -maxdepth 3 -name '.bash_history*' -print0 | xargs -0 `which grep` -h --color=always "$@" | sort -u | l
}

d() {
    colordiff "$@" | l
}

j() {
    jq --color-output "$@" | l
}

dj() {
    args=
    while [[ $1 = -* ]] ; do
        args="$args $1"
        shift
    done
    colordiff $args <(jq . "$1") <(jq . "$2") | l
}

dsorted() {
    args=
    while [[ $1 = -* ]] ; do
        args="$args $1"
        shift
    done
    colordiff $args <(sort "$1") <(sort "$2") | l
}

find0() {
    find "$@" -print0
}

# This is wild! A space in the end makes xargs work with aliases in simple cases, e.g "xargs lh"
# See https://stackoverflow.com/a/59843665/1635525 and "help alias"
alias xargs='xargs '
alias xargs0='xargs -0 '

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
    svn diff --diff-cmd=colordiff "$@" | l
}

svninf() {
    svn up --parents --set-depth=infinity "$@"
}

pastecol() {
    paste -d '|' "$@" | column -t -s '|'
}

# https://stackoverflow.com/a/20401674/1635525
faketty() {
    script --quiet --flush --return --command "$(printf "%q " "$@")" /dev/null
}

# sometimes loses random chars in the middle??
# better to use xsel when available
paste2file() {
    if [ -z "$1" ] ; then
        echo "Empty filename"
        return 1
    fi
    echo "Use Ctrl+C after a newline to end the input"
    stty cbreak
    cat > "$1"
    stty -cbreak
}

alias urlencode='perl -pe '\''s/([^A-Za-z0-9\n])/sprintf("%%%02X", ord($1))/seg'\'
alias urldecode='perl -pe '\''s/\+/ /g; s/%([[:xdigit:]]{2})/chr(hex($1))/ge'\'

alias cgidecode='perl -pe '\''s/[?&]/\n/g'\'' | urldecode'

alias pullrc=". $HOME/.bashrc"

alias dug='( shopt -s dotglob ; du -csh * | grep G )'

# python stuff

# to avoid misuse in debian/ubuntu
python() {
    echo "Use python3"
    false
}

epp() {
    newp="$PWD"
    if [ ! -z "$1" ] ; then
        if [ ! -d "$1" ] ; then
            echo "directory '$1' doesn't exist'"
            return 1
        fi
        newp="$1"
    fi
    export PYTHONPATH=$(readlink -f "$newp")
}

vhich() {
    echo VIRTUAL_ENV=$VIRTUAL_ENV
}

vactivate() {
    if [ ! -z "$1" ] ; then
        if [ ! -d "$1" ] ; then
            echo "directory '$1' doesn't exist'"
            return 1;
        fi
        export VIRTUAL_ENV="$1"
    fi
    if [ -n "$VIRTUAL_ENV" -a -f "$VIRTUAL_ENV/bin/activate" ] ; then
        source "$VIRTUAL_ENV/bin/activate"
    elif [ -f "$PWD/venv/bin/activate" ] ; then
        source "$PWD/venv/bin/activate"
    else
        echo "Can't find virtual environment"
        return 1
    fi
}

mkvenv() {
    python3 -m venv ./venv && vactivate ./venv && vhich
}


# docker stuff

dshell() {
    container=${1:-$(docker ps -q -l)}
    docker exec -it "$container" /bin/bash
}

drun() {
    image=${1:-$(docker image ls -q | head -1)}
    docker run -d "$image" /bin/bash
    dshell
}


# AWS stuff

awsprofile() {
    if [ -z "$1" ] ; then
        echo "AWS_PROFILE=$AWS_PROFILE"
    else
        export AWS_PROFILE="$1"
    fi
}

complete -W "$(grep '^\[' ~/.aws/credentials | tr -d '[]')" awsprofile


# all branch-specific changes should be below this line
