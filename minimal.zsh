#!/usr/bin/env zsh
export KEYTIMEOUT=1
export ZLE_RPROMPT_INDENT=1

THEME_ROOT=${0:A:h}
source "${THEME_ROOT}/libs/promptlib/activate"
source "${THEME_ROOT}/libs/zsh-async/async.zsh"
source "${THEME_ROOT}/modules/consts.zsh"
source "${THEME_ROOT}/modules/funcs.zsh"

bindkey '^M' minimal-accept-line
zle -N minimal-accept-line
zle -N zle-line-init
zle -N zle-keymap-select
setopt prompt_subst
async_start_worker "minimal_renderer" -n -u
autoload -Uz add-zsh-hook
add-zsh-hook preexec reset_timer
add-zsh-hook precmd minimal_renderer

TRAPWINCH() {
  preexec
  zle && zle reset-prompt
}

zle-line-init(){
  minimal_render_vi_mode
  zle && zle reset-prompt
}

zle-keymap-select(){
  minimal_render_vi_mode
  preexec
  zle && zle reset-prompt
}

minimal_renderer(){
  if [[ ${MINIMAL_SPACE_PROMPT} == 1 ]] && echo
  if [[ `tput colors` == 256 ]] ; then
    async_register_callback "minimal_renderer" set_prompt

    local MINIMAL_VERSION_VALUES=()
    for _var in $(echo "${MINIMAL_ENVVAR_PROMPT}"); do
      if [ ${(P)_var} ]; then
        MINIMAL_ENVVAR_VALUES+=(${(P)_var})
      else
        MINIMAL_ENVVAR_VALUES+=(" ")
      fi
    done
    local CURRENT_PATH=`pwd`
    local VIRTUAL_ENV=$VIRTUAL_ENV
    local TIMER=$TIMER
    if [[ ! $TIMER ]]; then
      TIMER=$(date +%s)
    fi

    prompt_reset
    async_job "minimal_renderer" prompt $VIRTUAL_ENV
    async_job "minimal_renderer" rprompt $TIMER $(plib_bg_count)
    async_job "minimal_renderer" envvar_prompt $MINIMAL_ENVVAR_PROMPT $MINIMAL_ENVVAR_VALUES ${#MINIMAL_ENVVAR_PROMPT[@]}
    async_job "minimal_renderer" git_prompt $CURRENT_PATH
    async_job "minimal_renderer" version_prompt "$MINIMAL_VERSION_PROMPT" "$(env | grep --color=never "${MINIMAL_VERSION_REGEX}")"
  else
    prompt_reset
    PROMPT='%~ $  '
  fi
}