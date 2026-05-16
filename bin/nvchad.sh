#!/usr/bin/env bash

set -euo pipefail

# INIT GLOBAL VARIABLES:
_CONF_HOME="${HOME}/.config"
_CONF_DIR="${_CONF_HOME}/nvim"
_CONF_FILE="${_CONF_DIR}/init.lua"


init_config() {
    local nvchad_bin
    nvchad_bin="$(readlink -f "$0")"
    local store_path
    store_path="$(dirname "${nvchad_bin%/*}")"
    local backup
    backup="${_CONF_HOME}/nvim_$(date +'%Y_%m_%d_%H_%M_%S').bak"

    if [ -d "$_CONF_DIR" ]; then
        mv "$_CONF_DIR" "$backup"
    fi
    mkdir -p "$_CONF_DIR"

    cp -r "$store_path/config/"* "$_CONF_DIR"

    find "$_CONF_DIR" -type d -exec chmod 755 {} +
    find "$_CONF_DIR" -not -type d -exec chmod 664 {} +
}


check_init() {
    if ! [ -f "$_CONF_FILE" ]; then
        init_config
    fi
}


wrapper() {
    nvim -u "$_CONF_FILE" "$@"
}


cleanup_lock() {
    if ! [ -s "${_CONF_DIR}/lazy-lock.json" ]; then
        if [ -e "${_CONF_DIR}/lazy-lock.json" ]; then
            rm "$_CONF_DIR/lazy-lock.json"
        fi
    fi
}


main() {
    check_init
    cleanup_lock
    wrapper "$@"
}


# RUN IT:
main "$@"
