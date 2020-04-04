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

TRAPWINCH() {
  #minimal_render_vi_mode
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

preexec(){
  export TIMER=$(date +%s)
}

minimal_renderer(){
  prompt_reset
  PROMPT='%~ $  '
  if [[ `tput colors` == 256 ]] ; then
    async_register_callback "minimal" set_prompt

    local MINIMAL_VERSION_VALUES=()
    for _var in $(echo "${MINIMAL_ENVVAR_PROMPT}"); do
      if [ ${(P)_var} ]; then
        MINIMAL_VERSION_VALUES+=(${(P)_var})
      else
        MINIMAL_VERSION_VALUES+=(" ")
      fi
    done
    local CURRENT_PATH=`pwd`
    local VIRTUAL_ENV=$VIRTUAL_ENV
    local TIMER=$TIMER
    if [[ ! $TIMER ]]; then
      TIMER=$(date +%s)
    fi

    prompt_reset
    async_worker_eval "minimal" __import_env "`env`"
    async_job "minimal" version_prompt $MINIMAL_VERSION_PROMPT
    async_job "minimal" envvar_prompt $MINIMAL_ENVVAR_PROMPT $MINIMAL_VERSION_VALUES ${#MINIMAL_ENVVAR_PROMPT[@]}
    async_job "minimal" git_prompt $CURRENT_PATH
    async_job "minimal" prompt $VIRTUAL_ENV
    async_job "minimal" rprompt $TIMER $(plib_bg_count)
  fi
}

precmd(){
  async_start_worker "minimal" -n -u
  minimal_renderer
}