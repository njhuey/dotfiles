# If you come from bash you might have to change your $PATH.
export PATH=".:${HOME}/bin:/usr/local/bin:${PATH}"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Aliases
alias fman="compgen -c | fzf | xargs man"
alias cpwd="pwd | awk '{printf \"%s\", \$0}' | pbcopy"
alias digitbio="conda activate digitbio"


# 100M lines / 2Gb 
HISTSIZE=100000000
HISTFILESIZE=2000000000

# Digital Biology worktree
WORKTREE_ROOT="${HOME}/dev/digital_biology/dbSDK"
INITIAL_TARGET="//tools:workspace_test"

# Convenience no-op function for when we want to print a message only in bash
# debug---i.e., `set -x`--- mode. Basically a more semantically-reasonable way
# to do something like `echo "Debug message" >/dev/null`.
_INFO() {
    # shellcheck disable=SC2317
    unused() {
        :
    }
}

if [[ -d "${WORKTREE_ROOT}" ]]; then
    _cad() {
        if [[ ! -n "$CONDA_DEFAULT_ENV" ]]; then
            conda activate digitbio
        fi
    }

    gtw() {
        _cad
        cd "${WORKTREE_ROOT}"
        ls
    }

    # Implementation of `hgd`. Executes in a subshell in order to use `set`, and
    # prints *only* the final directory that should be `cd`'d to to stdout on
    # success---which means we must be careful to redirect the output of all
    # commands when updating this function!
    _hgd() { echo "$(
        worktree_path="${WORKTREE_ROOT}/$1"
        main_path="${WORKTREE_ROOT}/main"
        requested_ref="refs/heads/$1"
        main_ref="refs/heads/main"
        set -euo pipefail
        if [[ -d "${worktree_path}" ]]; then
            _INFO "Worktree exists, taking you there!" &&
                cd "${worktree_path}" &&
                pwd
            exit $?
        fi
        _INFO "Fetching 'origin' to ensure we know if the branch exists!"
        git fetch origin >/dev/null
        if git show-ref --verify --quiet "${requested_ref}"; then
            _INFO "Checking out existing branch...$1" &&
                git worktree add "${worktree_path}" "$1" >/dev/null
        else
            if ! git show-ref --verify --quiet "${main_ref}"; then
                _INFO "There does not seem to be a 'main' branch...please make one!"
                exit 1
            fi
            if [[ ! -d "${main_path}" ]]; then
                _INFO "There does not appear to be a worktree for the main branch...please make one!"
                exit 2
            fi
            _INFO "Pulling upstream changes to main before creating new branch!"
            if ! { cd "${main_path}" && git pull upstream main >/dev/null; }; then
                _INFO "Failed to pull upstream changes to main, please update 'main' then re-run 'hgd'!"
                exit 3
            fi
            _INFO "Creating new worktree on fresh branch based on 'main'!"
            if ! git worktree add "${worktree_path}" main -b "$1" >/dev/null; then
                _INFO "Failed to create worktree!"
                exit 4
            fi
        fi
        cd "${worktree_path}"

        _INFO "Pulling/updating all submodules..."
        git submodule update --init --recursive >/dev/null 2>&1

        _INFO "Kicking off some slow repository rules in the background..."
        _INFO "...it may take up to 5min for these to finish!"
        bazel build $INITIAL_TARGET >/dev/null 2>&1 &
        pwd
    )"; }
    hgd() {
        local worktree_path
        local subshell_exit_code
        worktree_path="$(_hgd "$1")"
        subshell_exit_code="$?"
        [[ -d "${worktree_path}" ]] &&
            echo "Taking you to ${worktree_path} in this shell..." &&
            cd "${worktree_path}"
        _cad
        return "${subshell_exit_code}"
    }

    _exists_pr() {
        [[ "$#" -eq 2 ]] || return 255
        gh pr list --search "is:pr $2 head:$1" --json headRefName |
            python -c 'import sys, json; [print(o["headRefName"]) for o in json.load(sys.stdin)]' |
            grep -q "^$1$"
        return $?
    }
    hgdelete() {
        local worktree_path
        worktree_path="${WORKTREE_ROOT}/$1"
        if [[ "$2" != "-f" ]]; then
            local failed=false
            if _exists_pr "$1" "is:open"; then
                failed=true
                echo "ERROR: Found open PR with 'gh pr list --search \"is:pr is:open head:$1\"'"
            fi
            if ! _exists_pr "$1" "is:closed"; then
                failed=true
                echo "ERROR: Closed PR not found with 'gh pr list --search \"is:pr is:closed head:$1\"'"
            fi
            if [[ "$failed" = true ]]; then
                echo "Pass \"-f\" flag to ignore this and still attempt removal."
                echo "WARNING: \"-f\" flag FORCES worktree and local branch+remote deletion!"
                return 1
            fi
        fi
        if [[ -d "${worktree_path}" ]]; then
            echo -n "Attempting to remove git worktree at ${worktree_path}..."
            if ! git worktree remove "$2" "${worktree_path}"; then
                echo "FAILED. Pass '-f' to force."
                return 2
            else
                echo "Success!"
            fi
        fi
        [[ "$2" == "-f" ]] && d_flag="-D" || d_flag="-d"
        echo -n "Attempting to force-delete local branch with 'git branch $d_flag $1'..."
        if ! git branch "$d_flag" "$1"; then
            echo "FAILED. Pass '-f' to upgrade to use 'git branch -D'."
            return 3
        else
            echo "Success!"
        fi
        echo -n "Attempting to delete corresponding upstream branch: origin/$1..."
        if ! git push -d origin "$1"; then
            return 4
        fi
        echo "Successfully scrubbed all references to $1"
    }
fi


# zsh autocomplete
# znap source marlonrichert/zsh-autocomplete

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(bazel colored-man-pages fzf git python)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias python="python3"

eval "$(conda "shell.$(basename "${SHELL}")" hook)"

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
