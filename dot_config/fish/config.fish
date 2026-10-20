# Match Homebrew's shellenv without starting brew for each shell.
if test -x /opt/homebrew/bin/brew
    set -gx HOMEBREW_PREFIX /opt/homebrew
    set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
    set -gx HOMEBREW_REPOSITORY /opt/homebrew
    fish_add_path --global --move --path /opt/homebrew/bin /opt/homebrew/sbin
    if test -n "$MANPATH"
        set -gx MANPATH (string replace -r '^:*(.*?):*$' ':$1' -- "$MANPATH")
    end
    if not set -q INFOPATH
        set INFOPATH ''
    end
    set -gx INFOPATH /opt/homebrew/share/info $INFOPATH
end

set -gx PNPM_HOME "$HOME/Library/pnpm"
fish_add_path --global --path "$PNPM_HOME"
fish_add_path --global --append --path "$HOME/.cargo/bin"

if not status is-interactive
    return
end

set -g fish_greeting 'Hey Mika, welcome back... you gorgeous hunk 😏
Remember to drink some water today 😘'
set -g fish_color_command magenta

# Fish provides history sharing, autosuggestions, syntax highlighting, and
# case-insensitive substring completion (including directory completion).
# Abbreviations expand on space; aliases retain command behavior and completions.
function command_alias --argument-names name expansion
    alias "$name" "$expansion"
    abbr --add --position command -- "$name" "$expansion"
end

command_alias c clear

# Git
command_alias g git
command_alias gb 'git checkout -b'
command_alias gc 'git commit -am'
command_alias gp 'git push'
command_alias gfuck 'git reset --soft HEAD~'
command_alias gst 'git status'
command_alias gd 'git diff'

# Kubernetes
command_alias k kubectl
command_alias kubectl kubecolor
command_alias kx kubectx
command_alias ks kubens
command_alias kux 'kubie ctx'
command_alias kgp 'kubectl get pods'
command_alias kgs 'kubectl get svc'
command_alias kgd 'kubectl get deploy'
command_alias kgi 'kubectl get ingress'
command_alias klog 'kubectl logs -f'
command_alias kdesc 'kubectl describe'
command_alias debug-pod 'kubectl run debug-pod -i --tty --image busybox:latest'
command_alias attach-debug-pod 'kubectl attach debug-pod -c debug-pod -i -t'

# Terraform
command_alias tf terraform
command_alias tfa 'terraform apply'
command_alias tfp 'terraform plan'
command_alias tfi 'terraform init'
command_alias tfw 'terraform workspace'
command_alias tf-docs 'terraform-docs markdown table --output-file README.md --output-mode inject --sort-by required --lockfile=false ./'

# Docker
command_alias d docker
command_alias dc 'docker compose'
command_alias dps "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

# Azure
command_alias ax 'az fzf subscription'
command_alias azfs 'az fzf subscription'
command_alias azfg 'az fzf group'
command_alias azfl 'az fzf location'
command_alias azc 'az account set -s'
command_alias azl 'az account list -o table'

# AWS
function aws-profiles
    grep -o '\[[^]]*\]' ~/.aws/credentials
end
abbr --add --position command -- aws-profiles "grep -o '\\[[^]]*\\]' ~/.aws/credentials"

# StackIT
command_alias sk stackit
command_alias skp 'stackit config set -p'

function skctx
    set -l context dev
    if set -q argv[1]; and test -n "$argv[1]"
        set context "$argv[1]"
    end
    stackit ske kubeconfig create "$context" --login
end

# Other
command_alias myip 'curl -s https://ipv4.wtfismyip.com/json | jq .YourFuckingIPAddress'
command_alias sso-stuck 'pkill -f "Company Portal"'
functions --erase command_alias

function brewup
    brew update; and brew upgrade; and brew cleanup
end
abbr --add --position command -- brewup 'brew update && brew upgrade && brew cleanup'

function fix-git
    set -l current (git remote get-url origin 2>/dev/null)
    set -l repo "3as-cloud/"(basename "$PWD")
    if string match -q '*github.com*' -- "$current"
        set repo (string replace -r '\.git$' '' -- (string replace -r '^.*github\.com[:/]' '' -- "$current"))
    end

    set -l ssh_url (gh repo view "$repo" --json sshUrl -q .sshUrl); or return 1
    if test -z "$ssh_url"
        return 1
    end
    git remote set-url origin "$ssh_url"
end

function refresh-main
    set -l current (git branch --show-current 2>/dev/null)
    if test -z "$current"
        echo 'Not on a branch, or not inside a Git repository.' >&2
        return 1
    end

    if test "$current" = main
        git pull --ff-only
        return $status
    end

    git switch main; or return 1
    git pull --ff-only
    set -l result $status
    git switch "$current"; or return 1
    return $result
end

if command -q fzf
    fzf --fish | source
end
if command -q zoxide
    zoxide init fish | source
end
if command -q azenv
    azenv init fish | source
end

if command -q oh-my-posh; and test -f "$HOME/.config/oh-my-posh/zen.toml"
    oh-my-posh init fish --config "$HOME/.config/oh-my-posh/zen.toml" | source
end
