# Keep Zap's Git info, but place the path and branch above the input.
PROMPT='%B%F{cyan}%~%f%b${vcs_info_msg_0_}
%B%F{yellow}⚡%f %(?:%F{green}➜:%F{red}➜)%f%b '
_transient_prompt_full=$PROMPT

_transient_prompt_line_finish() {
  PROMPT='%B%F{yellow}⚡%f%b '
  RPROMPT=''
  zle reset-prompt
}

_transient_prompt_precmd() {
  PROMPT=$_transient_prompt_full
}

command -v azenv >/dev/null && eval "$(azenv init zsh)"

# Read local CLI configuration once; call _cloud_context_refresh after switching contexts.
_cloud_context_refresh() {
  local context namespace region profile_file config_dir config_name config_file line section
  local project account stackit_file stackit_project stackit_region
  _cloud_context_k8s=''
  _cloud_context_azure=''
  _cloud_context_aws=''
  _cloud_context_gcp=''
  _cloud_context_stackit=''
  _cloud_context_argocd=''

  if command -v kubectl >/dev/null; then
    context=$(command kubectl config current-context 2>/dev/null)
    if [[ -n $context ]]; then
      namespace=$(command kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
      _cloud_context_k8s="$context:${namespace:-default}"
    fi
  fi

  profile_file="${AZURE_CONFIG_DIR:-$HOME/.azure}/azureProfile.json"
  if [[ -r $profile_file ]] && command -v jq >/dev/null; then
    context=$(command jq -r '.subscriptions[]? | select(.isDefault == true) | .name' "$profile_file" 2>/dev/null)
    [[ -n $context ]] && _cloud_context_azure="${AZENV_CONTEXT:+$AZENV_CONTEXT | }$context"
  fi

  region=${AWS_REGION:-${AWS_DEFAULT_REGION:-}}
  _cloud_context_aws="${AWS_PROFILE:-${AWS_DEFAULT_PROFILE:-default}}${region:+@$region}"

  config_dir=${CLOUDSDK_CONFIG:-$HOME/.config/gcloud}
  config_name=${CLOUDSDK_ACTIVE_CONFIG_NAME:-}
  if [[ -z $config_name && -r $config_dir/active_config ]]; then
    IFS= read -r config_name < "$config_dir/active_config"
  fi
  config_file=$config_dir/configurations/config_${config_name:-default}
  project='' account='' section=''
  if [[ -r $config_file ]]; then
    while IFS= read -r line; do
      case $line in
        '[core]') section=core ;;
        '['*) section='' ;;
        'project = '*|'account = '*)
          if [[ $section == core ]]; then
            case $line in
              'project = '*) project=${line#*= } ;;
              'account = '*) account=${line#*= } ;;
            esac
          fi
          ;;
      esac
    done < "$config_file"
  fi
  project=${CLOUDSDK_CORE_PROJECT:-$project}
  account=${CLOUDSDK_CORE_ACCOUNT:-$account}
  [[ -n $project || -n $account ]] && _cloud_context_gcp="${project:-no project}${account:+ :: $account}"

  stackit_project=${STACKIT_PROJECT_ID:-}
  stackit_region=${STACKIT_REGION:-}
  if [[ -z $STACKIT_CLI_PROFILE || $STACKIT_CLI_PROFILE == default ]]; then
    stackit_file="$HOME/Library/Application Support/stackit/cli-config.json"
    if [[ -r $stackit_file ]] && command -v jq >/dev/null; then
      [[ -n $stackit_project ]] || stackit_project=$(command jq -r '.project_id // empty' "$stackit_file" 2>/dev/null)
      [[ -n $stackit_region ]] || stackit_region=$(command jq -r '.region // empty' "$stackit_file" 2>/dev/null)
    fi
  fi
  [[ -n $stackit_project || -n $stackit_region || -n $STACKIT_CLI_PROFILE ]] &&
    _cloud_context_stackit="${STACKIT_CLI_PROFILE:+$STACKIT_CLI_PROFILE | }${stackit_project:-no project}${stackit_region:+@$stackit_region}"

  config_file=${ARGOCD_CONFIG:-$HOME/.config/argocd/config}
  if [[ -r $config_file ]]; then
    while IFS= read -r line; do
      if [[ $line == 'current-context:'* ]]; then
        context=${line#current-context:}
        context=${context##[[:space:]]#}
        _cloud_context_argocd=$context
        break
      fi
    done < "$config_file"
  fi
  [[ -n $ARGOCD_SERVER ]] && _cloud_context_argocd=$ARGOCD_SERVER

  _cloud_context_terraform_refresh
  _cloud_context_command=''
  RPROMPT=''
}

_cloud_context_terraform_refresh() {
  local workspace_file
  _cloud_context_terraform=${TF_WORKSPACE:-}
  if [[ -z $_cloud_context_terraform ]]; then
    workspace_file=${TF_DATA_DIR:-.terraform}/environment
    if [[ -r $workspace_file ]]; then
      IFS= read -r _cloud_context_terraform < "$workspace_file"
    elif [[ -d ${TF_DATA_DIR:-.terraform} ]]; then
      _cloud_context_terraform=default
    fi
  fi
  _cloud_context_command=''
}

# Show cloud context only while editing a relevant command.
_cloud_context_hint() {
  local cmd=${BUFFER##[[:space:]]#}
  cmd=${cmd%%[[:space:]]*}
  [[ $cmd == "$_cloud_context_command" ]] && return
  _cloud_context_command=$cmd

  local hint='' color=''
  case $cmd in
    k|kubectl|kubecolor|kx|kubectx|ks|kubens|kux|kubie|kgp|kgs|kgd|kgi|klog|kdesc|helm)
      hint=$_cloud_context_k8s color='#326CE5'
      ;;
    az|azenv|ax|azfs|azfg|azfl|azc|azl)
      hint=$_cloud_context_azure color='#3CCBF4'
      ;;
    aws)
      hint=$_cloud_context_aws color='#FF9900'
      ;;
    gcloud)
      hint=$_cloud_context_gcp color='#47888d'
      ;;
    stackit|sk|skp|skctx)
      hint=$_cloud_context_stackit color='#E60000'
      ;;
    argocd)
      hint=$_cloud_context_argocd color='#FFA400'
      ;;
    terraform|tf|tfa|tfp|tfi|tfw)
      hint=$_cloud_context_terraform color='#844FBA'
      ;;
  esac

  RPROMPT=${hint:+"%F{$color}${hint//\%/%%}%f"}
  zle reset-prompt
}

_cloud_context_line_init() {
  _cloud_context_command=''
  RPROMPT=''
}

_cloud_context_refresh
autoload -Uz add-zle-hook-widget add-zsh-hook
add-zle-hook-widget zle-line-init _cloud_context_line_init
add-zle-hook-widget zle-line-pre-redraw _cloud_context_hint
add-zle-hook-widget zle-line-finish _transient_prompt_line_finish
add-zsh-hook precmd _transient_prompt_precmd
add-zsh-hook chpwd _cloud_context_terraform_refresh
