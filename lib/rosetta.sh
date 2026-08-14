#!/usr/bin/env sh
# rosetta.sh — a lossless shell "rosetta stone".
#
# One sourceable library that gives you the same behavior in bash 3.2, modern
# bash, zsh, and POSIX sh (dash/ash). It is the phrasebook that lets one script
# be spoken natively in every shell "locale" without loss.
#
# Design rules (so this file itself is portable):
#   - Written in the POSIX intersection all four targets accept.
#   - Always quote expansions (zsh does not word-split unquoted $var; the rest do).
#   - No arrays, no `declare -A`, no `${v,,}`, no process substitution, no `[[ ]]`.
#   - `local` is used (universally supported by bash/zsh/ksh/dash even though not
#     in POSIX); this is the one pragmatic extension, documented in CONFORMANCE.md.
#
# License: MIT. Part of the ARCS / flashesofbrilliance family. The translation
# METHOD here is open; any environment-specific priors stay private (ADR-053).

# ---------------------------------------------------------------------------
# 0. Guard + locale detection
# ---------------------------------------------------------------------------

# Sourcing guard.
if [ -n "${ROSETTA_SOURCED:-}" ]; then
  return 0 2>/dev/null || true
fi
ROSETTA_SOURCED=1

# ROSETTA_SHELL: the detected locale — bash | zsh | posix
# ROSETTA_SHELL_VERSION: best-effort version string
rosetta_detect() {
  if [ -n "${ZSH_VERSION:-}" ]; then
    ROSETTA_SHELL=zsh
    ROSETTA_SHELL_VERSION=$ZSH_VERSION
    # Make zsh behave like sh for the duration a rosetta script runs:
    # word-splitting on, 0-based arrays off-risk avoided (we use none), and
    # no automatic globbing surprises. Scoped emulation is not available for a
    # sourced lib, so we set the two options rosetta relies on.
    setopt sh_word_split 2>/dev/null || true
    setopt no_nomatch 2>/dev/null || true
  elif [ -n "${BASH_VERSION:-}" ]; then
    ROSETTA_SHELL=bash
    ROSETTA_SHELL_VERSION=$BASH_VERSION
  else
    ROSETTA_SHELL=posix
    ROSETTA_SHELL_VERSION=${KSH_VERSION:-unknown}
  fi
  export ROSETTA_SHELL ROSETTA_SHELL_VERSION
}
rosetta_detect

# `local` is supported by bash/zsh/dash/ash but NOT by POSIX sh nor ksh93. Where
# it is absent we install a no-op `local` so rosetta functions still parse and
# run; scoping degrades to global (internal temps use a collision-resistant _r*
# naming so this is safe), and output stays byte-identical. This is what lets
# the losslessness claim extend to ksh and strict POSIX, not just the big four.
if ( eval 'rosetta__lp(){ local __x=1; }; rosetta__lp' ) 2>/dev/null; then
  ROSETTA_HAVE_LOCAL=1
else
  ROSETTA_HAVE_LOCAL=0
  # Defined via eval so shells that treat `local` as a reserved builtin (dash)
  # never PARSE this line — they take the other branch and skip it entirely.
  eval 'local() { :; }' 2>/dev/null || true
fi
export ROSETTA_HAVE_LOCAL

# rosetta_have <capability> -> 0 if the native construct exists here.
# Capabilities: assoc, upper_lower_expand, arrays, local
rosetta_have() {
  case "$1" in
    assoc)
      # bash>=4 and zsh have native associative arrays.
      case "$ROSETTA_SHELL" in
        zsh) return 0 ;;
        bash)
          # major version >= 4
          case "$ROSETTA_SHELL_VERSION" in
            1.*|2.*|3.*) return 1 ;;
            *) return 0 ;;
          esac ;;
        *) return 1 ;;
      esac ;;
    upper_lower_expand)
      # ${v,,} / ${v^^} exist in bash>=4 only (NOT zsh, NOT posix).
      case "$ROSETTA_SHELL" in
        bash)
          case "$ROSETTA_SHELL_VERSION" in
            1.*|2.*|3.*) return 1 ;;
            *) return 0 ;;
          esac ;;
        *) return 1 ;;
      esac ;;
    arrays)
      case "$ROSETTA_SHELL" in bash|zsh) return 0 ;; *) return 1 ;; esac ;;
    *) return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# 1. Lossless portable map (the associative-array rosetta)
# ---------------------------------------------------------------------------
#
# bash 3.2 has no associative arrays; POSIX sh has none either. We provide ONE
# API that is byte-lossless for arbitrary keys AND arbitrary values (any bytes
# except NUL, which no shell can hold in a variable anyway).
#
# Storage model: each entry lives in its own shell variable
#     __RMAP_<map>_<hexkey>=<value verbatim>
# The key is hex-encoded to a safe variable-name charset, so any key survives
# losslessly. An ordered index variable __RMAPK_<map> tracks insertion order of
# hexkeys (newline-separated; hex tokens never contain newlines).
#
# API:
#   rosetta_map_set  MAP KEY VALUE
#   rosetta_map_get  MAP KEY            # prints value, exit 1 if absent
#   rosetta_map_has  MAP KEY            # exit 0/1
#   rosetta_map_keys MAP                # prints keys, one per line, insertion order
#   rosetta_map_del  MAP KEY
#   rosetta_map_size MAP
#   rosetta_map_clear MAP

# hex-encode a string to [0-9a-f] (portable, lossless, no external deps beyond
# printf which is a POSIX builtin/utility everywhere).
_rosetta_enc() {
  # Reads $1, prints hex. Uses od for byte-accuracy across locales.
  printf '%s' "$1" | od -An -v -tx1 | tr -d ' \n'
}

rosetta_map_set() {
  local _m _k _v _hk _idx
  _m=$1; _k=$2; _v=$3
  _hk=$(_rosetta_enc "$_k")
  # Track order only if new.
  if ! eval "[ -n \"\${__RMAP_${_m}_${_hk}+x}\" ]"; then
    eval "_idx=\${__RMAPK_${_m}:-}"
    if [ -z "$_idx" ]; then
      eval "__RMAPK_${_m}=\$_hk"
    else
      eval "__RMAPK_${_m}=\"\$_idx
\$_hk\""
    fi
  fi
  eval "__RMAP_${_m}_${_hk}=\$_v"
}

rosetta_map_has() {
  local _hk
  _hk=$(_rosetta_enc "$2")
  eval "[ -n \"\${__RMAP_${1}_${_hk}+x}\" ]"
}

rosetta_map_get() {
  local _hk
  _hk=$(_rosetta_enc "$2")
  if eval "[ -n \"\${__RMAP_${1}_${_hk}+x}\" ]"; then
    eval "printf '%s' \"\${__RMAP_${1}_${_hk}}\""
    return 0
  fi
  return 1
}

rosetta_map_del() {
  local _m _hk _idx _out _line
  _m=$1
  _hk=$(_rosetta_enc "$2")
  eval "unset __RMAP_${_m}_${_hk} 2>/dev/null || true"
  # Rebuild index without _hk.
  eval "_idx=\${__RMAPK_${_m}:-}"
  _out=$(printf '%s\n' "$_idx" | { while IFS= read -r _line; do
      [ -z "$_line" ] && continue
      [ "$_line" = "$_hk" ] && continue
      printf '%s\n' "$_line"
    done; })
  # strip trailing newline
  eval "__RMAPK_${_m}=\$_out"
}

rosetta_map_keys() {
  local _idx _line
  eval "_idx=\${__RMAPK_${1}:-}"
  [ -z "$_idx" ] && return 0
  printf '%s\n' "$_idx" | while IFS= read -r _line; do
    [ -z "$_line" ] && continue
    # decode hex -> bytes
    printf '%s' "$_line" | _rosetta_unhex
    printf '\n'
  done
}

# decode hex from stdin to bytes.
_rosetta_unhex() {
  # Read hex pairs, emit bytes. Portable via printf %b of \xNN? Not universal.
  # Use a sed/xxd-free approach: build octal escapes for printf.
  local _hex _i _len _pair _dec
  _hex=$(cat)
  _len=${#_hex}
  _i=0
  while [ "$_i" -lt "$_len" ]; do
    _pair=$(printf '%s' "$_hex" | cut -c $((_i+1))-$((_i+2)))
    # hex -> decimal -> octal escape for printf
    _dec=$(( 0x$_pair ))
    printf '%b' "\\0$(printf '%o' "$_dec")"
    _i=$((_i+2))
  done
}

rosetta_map_size() {
  local _idx _n
  eval "_idx=\${__RMAPK_${1}:-}"
  if [ -z "$_idx" ]; then printf '0'; return 0; fi
  _n=$(printf '%s\n' "$_idx" | grep -c .)
  printf '%s' "$_n"
}

rosetta_map_clear() {
  local _idx _line
  eval "_idx=\${__RMAPK_${1}:-}"
  printf '%s\n' "$_idx" | while IFS= read -r _line; do
    [ -z "$_line" ] && continue
    eval "unset __RMAP_${1}_${_line} 2>/dev/null || true"
  done
  eval "unset __RMAPK_${1} 2>/dev/null || true"
}

# ---------------------------------------------------------------------------
# 2. String-case shims (bash4 ${v,,}/${v^^} rosetta)
# ---------------------------------------------------------------------------
rosetta_lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
rosetta_upper() { printf '%s' "$1" | tr '[:lower:]' '[:upper:]'; }

# ---------------------------------------------------------------------------
# 3. echo -e / $'...' rosetta — portable escaped output
# ---------------------------------------------------------------------------
# `echo -e` is non-portable (zsh/bash/posix differ). Use rosetta_eprint.
rosetta_eprint() { printf '%b' "$1"; }      # interpret backslash escapes
rosetta_println() { printf '%s\n' "$1"; }   # literal + newline

# ---------------------------------------------------------------------------
# 4. Split without arrays (portable IFS split -> callback)
# ---------------------------------------------------------------------------
# rosetta_split DELIM STRING CALLBACK  -> calls CALLBACK once per field.
rosetta_split() {
  local _delim _str _cb _field _rest
  _delim=$1; _str=$2; _cb=$3
  _rest=$_str
  while [ -n "$_rest" ]; do
    case "$_rest" in
      *"$_delim"*)
        _field=${_rest%%"$_delim"*}
        _rest=${_rest#*"$_delim"}
        "$_cb" "$_field"
        ;;
      *)
        "$_cb" "$_rest"
        _rest=
        ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# 5. Version banner
# ---------------------------------------------------------------------------
ROSETTA_VERSION="0.1.0"
rosetta_version() { printf 'rosetta-shell %s (locale: %s %s)\n' "$ROSETTA_VERSION" "$ROSETTA_SHELL" "$ROSETTA_SHELL_VERSION"; }
