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
alias lc='tr A-Z a-z'
alias uc='tr a-z A-Z'
alias quote4sql='sed -e "s/^/'\''/; s/$/'\'',/"'

trn() {
    tr "$@" '\n'
}

LESS_VERSION="$(less --version | sed -n -e 's/less \([0-9]\+\) .*/\1/p')"
LESS_F=$( [ "$LESS_VERSION" -ge 530 ] && echo "less --quit-if-one-screen" || echo "less")

unalias l
l() {
    if [ -t 1 ] ; then
        $LESS_F -R "$@"
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
GRE_EXCLUDE_DIR='--exclude-dir venv --exclude-dir node_modules --exclude-dir gems --exclude-dir .svn --exclude-dir .git'
gre() {
    # Need "set -f" to disable glob expansion for the "*.pyc" and other exclude patterns.
    # But we do need the word splitting though, this is why simple quoting "$GRE_EXCLUDE" won't work.
    # And you still can do the "gre *.txt" because the glob expansions happens earlier.
    (set -f; g -r $GRE_EXCLUDE $GRE_EXCLUDE_DIR "$@")
}

grepy() {
    (set -f; g -r $GRE_EXCLUDE_DIR --include '*.py' "$@")
}

x0g() {
    xargs -0 `which grep` --color=always "$@" | l
}

grhw() {
    where=$1; shift
    find "$where" -maxdepth 3 -name '.bash_history*' -print0 | xargs -0 `which grep` -h --color=always "$@" | sort | uniq -c | sort -n -r | l
}

grh() {
    grhw "$HOME" "$@"
}

grhs() {
    find "$SCREEN_DIR" -maxdepth 1 -name '.bash_history*' -print0 | xargs -0 `which grep` --color=always "$@"
}

d() {
    # The 'diff' command fails when run by mistake without arguments but 'colordiff' does not.
    # This is understandable (colordiff can color the stdin) but annoying, so we'll fail explicitly here.
    if [ -z "$1" ] ; then
        echo "d: missing operands"
        return 1
    fi
    colordiff "$@" | l
}

wd() {
    wdiff -n "$@" | colordiff | l
}

j() {
    jq --color-output "$@" | l
}

# Usage:
#   diffcmd one two -u -- jq .
#   diffcmd one two -u -- sort
#   diffcmd one two -- sed -e 's/#.*//'
#   diffcmd dir1 dir2 -- find {} -type f -printf "%P\n"
diffcmd() {
    local diffargs
    local extcmd
    local extcmdargs
    local left
    local right
    left="$1" ; shift
    right="$1" ; shift
    while [[ $1 != '--' && $1 != '' ]]; do
        diffargs+=("$1")
        shift
    done
    shift # skip the "--"

    while [[ $1 != '{}' && $1 != '' ]]; do
        extcmd+=("$1")
        shift
    done
    shift # skip the "{}"

    extcmdargs=("$@") # suffix args

    d "${diffargs[@]}" <("${extcmd[@]}" "$left" "${extcmdargs[@]}") <("${extcmd[@]}" "$right" "${extcmdargs[@]}")
}

dsorted() {
    diffcmd "$@" -u -- sort
}

duniqsorted() {
    diffcmd "$@" -u -- sort -u
}

dj() {
    diffcmd "$@" -u -- jq .
}

find0() {
    find "$@" -print0
}

f() {
    dir=$1; shift
    name=$1; shift
    find "$dir" -name "*${name}*" "$@"
}

f0() {
    f "$@" -print0
}

# This is wild! A space in the end makes xargs work with aliases in simple cases, e.g "xargs lh"
# See https://stackoverflow.com/a/59843665/1635525 and "help alias"
alias xargs='xargs '
alias xargs0='xargs -0 '
alias xargsn='xargs -d "\n"'

export EDITOR=vim
export VISUAL=vim

unalias lh lth lth20 2>/dev/null
lh() {
    ls -lh "$@" --color=always | l
}

lth() {
    ls -lth "$@" --color=always | l
}

lth20() {
    ls -lth "$@" --color=always | head -20
}

alias dfh='df -h'
alias bc='bc -l'

wcu() {
    sort -u "$@" | wc -l
}

wcl() {
    wc -l "$@"
}

sucs() {
    sort "$@" | uniq -c | sort -n
}

pstree() {
    $(which pstree) $@ | l
}

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

complete -W "$( [ -d $HOME/screen ] && ls $HOME/screen)" mkscreen

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

columnt() {
    column -t -s "$(echo -e '\t')" "$@"
}

xselcol() {
    (xsel -b; echo) | columnt | tee /dev/stderr | xsel -b
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

alias dug='( shopt -s dotglob ; du -csh -- * | grep -P "G\t" )'
alias dus='du -sh * | sort -h -r | l'

withlog() {
    if [[ ! -z "$2" && "$2" != -* ]] ; then
        cmd_name="${1}_${2}" # e.g. python script name or terraform command name
    else
        cmd_name="${1}"
    fi
    cmd_name=${cmd_name//[^a-zA-Z0-9_-.]/_}

    mkdir -p "$HOME/logs"
    logfile="$HOME/logs/${cmd_name}_$(date +'%Y%m%dT%H%M%S%z').log"

    echo -n "CMDLINE: " | tee -a "$logfile"
    printf "%q " "$@" | tee -a "$logfile"
    echo -ne "\nPWD:     $PWD" | tee -a "$logfile"
    echo -ne "\nLOGFILE: $logfile" | tee -a "$logfile"
    echo -ne "\nSTARTED: $(date --iso-8601=seconds)\n\n" | tee -a "$logfile"

    "$@" |& tee -a "$logfile"

    echo -e "\n\nFINISHED: $(date --iso-8601=seconds)" | tee -a "$logfile"
    echo "LOGFILE: $logfile" | tee -a "$logfile"
}

readlog() {
    l "$HOME/logs/$(ls -t "$HOME/logs" | head -1)"
}

b64cert2pem()
{
    echo '-----BEGIN CERTIFICATE-----'
    cat
    echo '-----END CERTIFICATE-----'
}

b64certdecode() {
	b64cert2pem | openssl x509 -text -noout | l
}

# python stuff

# to avoid misuse in debian/ubuntu
python() {
    echo "Use python3"
    false
}

p3() {
    withlog python3 -u "$@"
}

# https://stackoverflow.com/a/41386937/1635525
pyclean () {
    find . -type f -name '*.py[co]' -delete -o -type d -name __pycache__ -delete
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
    PYTHON=${1:-python3}
    $PYTHON -m venv --prompt $(basename $PWD) ./venv \
        && vactivate ./venv \
        && vhich \
        && pip3 install --upgrade pip \
        && python3 --version
}

pydict2json() {
    python3 -c 'import json; print(json.dumps(eval(input())))' | j . "$@"
}


# docker stuff

dps() {
    docker ps "$@" | l
}

dim() {
    docker image ls | l
}

dlast() {
    docker image ls -q | head -1
}

drunning() {
    docker ps -q | head -1
}

dshell() {
    container=${1:-$(drunning)}
    docker exec -it "$container" env TERM=xterm-256color /bin/bash
}

drun() {
    image=${1:-$(dlast)}
    docker run -d --init "$image" sleep inf && dshell
}

drundev() {
    image=${1:-$(dlast)}
    docker run -d --init --network=host --mount "type=bind,source=$HOME,target=/host_home" "$image" sleep inf && dshell
}

dstop() {
    container=${1:-$(drunning)}
    docker stop "$container"
}

dsetup() {
    container=${1:-$(drunning)}
    docker exec -it "$container" bash -c "apt-get update && apt-get -y install vim less iproute2 strace psmisc"
}

# https://stackoverflow.com/questions/21200304/docker-how-to-show-the-diffs-between-2-images
ddiff() {
    cmd="$1"; shift
    image1="$1"; shift
    image2="$1"; shift
    dir="${1:-/}"
    out1="/tmp/dockerfiles.$image1.txt"
    out2="/tmp/dockerfiles.$image2.txt"
    docker run "$image1" bash -c "find $dir -xdev -type f | sort | $cmd" > "$out1"
    docker run "$image2" bash -c "find $dir -xdev -type f | sort | $cmd" > "$out2"
    d "$out1" "$out2"
    echo d "$out1" "$out2"
}

dlistdiff() {
    ddiff "cat" "$@"
}

dhashdiff() {
    ddiff "xargs -n 1 --delimiter '\n' md5sum" "$@"
}

# AWS stuff

awsprofile() {
    if [ -z "$1" ] ; then
        echo "AWS_PROFILE=$AWS_PROFILE"
    else
        export AWS_PROFILE="$1"
    fi
    if ! aws sts get-caller-identity >/dev/null 2>&1 ; then
        aws sso login
    fi
    echo AWS_PROFILE="$AWS_PROFILE"
    aws sts get-caller-identity
}

file_or_null() {
    if [ -f "$1" ] ; then
        echo "$1"
    else
        echo "/dev/null"
    fi
}

AWS_PROFILE_COMPLETE=$(grep -h '\[' $(file_or_null ~/.aws/config) $(file_or_null ~/.aws/credentials) | sed -e 's/.* //;' | tr -d '[]' | sort -u)
complete -W "$AWS_PROFILE_COMPLETE" awsprofile

unalias awsssm 2>/dev/null
awsssm() {
    rlwrap -I aws ssm start-session --target "$@"
}


# all branch-specific changes should be below this line
