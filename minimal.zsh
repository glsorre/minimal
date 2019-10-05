#!/usr/bin/env zsh

MINIMAL_FADE_COLOR=black

MINIMAL_ENABLE_VI_PROMPT=1
MINIMAL_SPACE_PROMPT=1

MINIMAL_PROMPT_SEP="|"

MINIMAL_GIT_STASH_SYM='@'
MINIMAL_GIT_PUSH_SYM='↑'
MINIMAL_GIT_PULL_SYM='↓'
MINIMAL_GIT_UNSTAGE_SYM='+'
MINIMAL_GIT_STAGE_SYM='!'

MINIMAL_JAVA_SYM='☕ '
MINIMAL_PY_SYM='🐍 '
MINIMAL_RB_SYM='RB:'
MINIMAL_GO_SYM='GO:'
MINIMAL_ELIXIR_SYM='EX:'
MINIMAL_AM_CRYSTAL_SYM='CR:'
MINIMAL_NODE_SYM='⬢ '
MINIMAL_PHP_SYM='PHP:'

THEME_ROOT=${0:A:h}
source "${THEME_ROOT}/libs/promptlib/activate"

minimal_prompt_symbol_ins(){
  echo -ne "%F{green}%B%S  INS  %s%b%f"
}

minimal_prompt_symbol_nml(){
  echo -ne "%F{red}%B%S  CMD  %s%b%f"
}

function zle-line-init {
  minimal_render_vi_mode
  minimal_renderer
  zle && zle reset-prompt
}

function zle-keymap-select {
  minimal_render_vi_mode
  preexec
  minimal_renderer
  zle && zle reset-prompt
}

minimal_render_vi_mode(){
  MINIMAL_VI_PROMPT="$(minimal_vi_prompt)"
  export MINIMAL_VI_PROMPT
}

export KEYTIMEOUT=1
export ZLE_RPROMPT_INDENT=0

minimal_vi_prompt(){
  case ${KEYMAP} in
    (vicmd)      echo -n "$(minimal_prompt_symbol_nml)" ;;
    (main|viins) echo -n "$(minimal_prompt_symbol_ins)" ;;
  esac
}

zle -N zle-line-init
zle -N zle-keymap-select

minimal_git_left_right(){
  __git_left_right=$(plib_git_left_right)

  __pull=$(echo "$__git_left_right" | awk '{print $2}' | tr -d ' \n')
  __push=$(echo "$__git_left_right" | awk '{print $1}' | tr -d ' \n')

  [[ "$__pull" != 0 ]] && [[ "$__pull" != '' ]] && __pushpull="${__pull}${MINIMAL_GIT_PULL_SYM}"
  [[ -n "$__pushpull" ]] && __pushpull+=' '
  [[ "$__push" != 0 ]] && [[ "$__push" != '' ]] && __pushpull+="${__push}${MINIMAL_GIT_PUSH_SYM}"

  if [[ "$__pushpull" != '' ]]; then
    echo -ne "${__pushpull}"
  fi
}

prompt_length(){
  emulate -L zsh
  local COLUMNS=${2:-$COLUMNS}
  local -i x y=$#1 m
  if (( y )); then
    while (( ${${(%):-$1%$y(l.1.0)}[-1]} )); do
      x=y
      (( y *= 2 ));
    done
    local xy
    while (( y > x + 1 )); do
      m=$(( x + (y - x) / 2 ))
      typeset ${${(%):-$1%$m(l.x.y)}[-1]}=$m
    done
  fi
  echo $x
}

s_humanized(){
  local human total_seconds=$1
  local days=$(( total_seconds / 60 / 60 / 24 ))
  local hours=$(( total_seconds / 60 / 60 % 24 ))
  local minutes=$(( total_seconds / 60 % 60 ))
  local seconds=$(( total_seconds % 60 ))

  (( days > 0 )) && human+="${days}d "
  (( hours > 0 )) && human+="${hours}h "
  (( minutes > 0 )) && human+="${minutes}m "
  human+="${seconds}s"

  echo "$human"
}

function rprompt_execution_time(){
  elapsed=$((SECONDS-timer))
  if [[ elapsed -ge 5 ]] ; then
    echo "%F{green}%B%S $(s_humanized ${elapsed}) %s%b%f"
  else
    echo ""
  fi
}

rprompt_exit_code(){
  last_exit_code=$? 
  if [[ last_exit_code -gt 0 ]] ; then
    echo "%F{red}%B%S $last_exit_code %s%b%f"
  else
    echo " "
  fi
}

prompt_reset(){
  PROMPT=""
}

version_prompt(){
  version_prompt_val=""
  if [[ -n ${MINIMAL_VERSION_PROMPT} ]]; then
    local LOOP_INDEX=0
    for _v in $(echo "${MINIMAL_VERSION_PROMPT}"); do
      [[ ${LOOP_INDEX} != "0" ]] && version_prompt_val+="%F{$MINIMAL_FADE_COLOR}${MINIMAL_PROMPT_SEP}%f"
      [[ ${LOOP_INDEX} == "0" ]] && LOOP_INDEX=$((LOOP_INDEX + 1)) && version_prompt_val+="%F{$MINIMAL_FADE_COLOR}[%f"

      [[ ${_v} == "PYTHON" ]]    && version_prompt_val+="${MINIMAL_PY_SYM}$(plib_python_version)"
      [[ ${_v} == "RUBY" ]]      && version_prompt_val+="${MINIMAL_RB_SYM}$(plib_ruby_version)"
      [[ ${_v} == "JAVA" ]]      && version_prompt_val+="${MINIMAL_JAVA_SYM}$(plib_java_version)"
      [[ ${_v} == "GO" ]]        && version_prompt_val+="${MINIMAL_GO_SYM}$(plib_go_version)"
      [[ ${_v} == "ELIXIR" ]]    && version_prompt_val+="${MINIMAL_ELIXIR_SYM}$(plib_elixir_version)"
      [[ ${_v} == "CRYSTAL" ]]   && version_prompt_val+="${MINIMAL_CRYSTAL_SYM}$(plib_crystal_version)"
      [[ ${_v} == "NODE" ]]      && version_prompt_val+="${MINIMAL_NODE_SYM}$(plib_node_version)"
      [[ ${_v} == "PHP" ]]       && version_prompt_val+="${MINIMAL_PHP_SYM}$(plib_php_version)"
    done

    [[ "$LOOP_INDEX" != "0" ]] && version_prompt_val+="%F{$MINIMAL_FADE_COLOR}]%f"
  fi
  PROMPT="${PROMPT}${version_prompt_val}"
}

envvar_prompt(){
  envvar_prompt_val=""
  if [[ -n ${MINIMAL_ENVVAR_PROMPT} ]]; then
    local LOOP_INDEX=0
    for _var in $(echo "${MINIMAL_ENVVAR_PROMPT}"); do
      [[ ${LOOP_INDEX} != "0" ]] && envvar_prompt_val+="%F{$MINIMAL_FADE_COLOR}${MINIMAL_PROMPT_SEP}%f"
      [[ ${LOOP_INDEX} == "0" ]] && LOOP_INDEX=$((LOOP_INDEX + 1)) && envvar_prompt_val+="%F{$MINIMAL_FADE_COLOR}[%f"
      [[ ${_var} != "" ]] && envvar_prompt_val+="${_var}:${(P)_var}"
    done
    [[ "$LOOP_INDEX" != "0" ]] && envvar_prompt_val+="%F{$MINIMAL_FADE_COLOR}]%f"
  fi
  PROMPT="${PROMPT}${envvar_prompt_val}"
}

git_prompt(){
  git_prompt_val=""
  if [[ $(plib_is_git) == 1 ]]; then
    git_prompt_val+="%F{$MINIMAL_FADE_COLOR}[%f "
    git_prompt_val+="%B$(plib_git_branch)%b"

    git_status=$(plib_git_status)

    mod_st=$(plib_git_staged_mod "$git_status")
    add_st=$(plib_git_staged_add "$git_status")
    del_st=$(plib_git_staged_del "$git_status")
  
    mod_ut=$(plib_git_unstaged_mod "$git_status")
    add_ut=$(plib_git_unstaged_add "$git_status")
    del_ut=$(plib_git_unstaged_del "$git_status")

    [[ mod_st -gt 0 || add_st -gt 0 || del_st -gt 0 ]] && git_prompt_val+=" %B${MINIMAL_GIT_STAGE_SYM}%b"
    [[ mod_ut -gt 0 || add_ut -gt 0 || del_ut -gt 0 ]] && git_prompt_val+=" %B${MINIMAL_GIT_UNSTAGE_SYM}%b"
    [[ $(plib_git_stash) == 1 ]] && git_prompt_val+=" ${MINIMAL_GIT_STASH_SYM}"
    [[ ! -z $(minimal_git_left_right) ]] && git_prompt_val+=" %F{red}$(minimal_git_left_right)%f"
    git_prompt_val+=" %F{$MINIMAL_FADE_COLOR}]%f"
  fi
  escaped_prompt="$(prompt_length ${PROMPT})"
  escaped_git="$(prompt_length ${git_prompt_val})"
  right_width=$(($COLUMNS-$escaped_git-$escaped_prompt))
  if [[ ${right_width} -lt 0 ]] ; then
    PROMPT="${PROMPT}"$'\n'"${git_prompt_val}"
  else
    PROMPT="${PROMPT}${(l:$right_width:::)}${git_prompt_val}"
  fi
}

function preexec(){
  timer=$SECONDS
}

function prompt(){
  [[ ${MINIMAL_SPACE_PROMPT} == 1 ]] && echo

  venv=$(plib_venv)
  if [[ -v venv ]] && prompt_std="%F{$MINIMAL_FADE_COLOR}${venv}%f "
  prompt_std+="%f%F{$MINIMAL_FADE_COLOR}%~%f"
  prompt_vi='${MINIMAL_VI_PROMPT} '"${prompt_std}  "
  
  PROMPT=${PROMPT}$'\n'${prompt_vi}
  RPROMPT='$(rprompt_exit_code)$(rprompt_execution_time)'
}

function minimal_renderer(){
  prompt_reset
  version_prompt 
  envvar_prompt
  git_prompt
  prompt
}

function precmd(){
  minimal_renderer
}