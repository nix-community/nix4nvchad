# █▄░█ █░█ █ █▀▄▀█   █░█░█ █▀█ ▄▀█ █▀█ █▀█ █▀▀ █▀█ ▀
# █░▀█ ▀▄▀ █ █░▀░█   ▀▄▀▄▀ █▀▄ █▀█ █▀▀ █▀▀ ██▄ █▀▄ ▄
# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

# INIT GLOBAL VARIABLES:
_CONF_HOME="${HOME}/.config"
_CONF_DIR="${_CONF_HOME}/nvim"
_CONF_FILE="${_CONF_DIR}/init.lua"


init_config() {
    local nvchad_bin="$(readlink -f $0)"
    local store_path="$(dirname ${nvchad_bin%/*})"
    local backup="${_CONF_HOME}/nvim_$(date +'%Y_%m_%d_%H_%M_%S').bak"

    if [ -d "$_CONF_DIR" ]; then
        mv $_CONF_DIR $backup
        mkdir -p $_CONF_DIR
    else
        mkdir -p $_CONF_DIR
    fi
    
    cp -r $store_path/config/* $_CONF_DIR
    for file_or_dir in $(find "$_CONF_DIR"); do
        if [ -d "$file_or_dir" ]; then
            chmod 755 $file_or_dir
        else
            chmod 664 $file_or_dir
        fi
    done
}


check_init() {
    if ! [ -f "$_CONF_FILE" ]; then
        init_config
    fi
}


wrapper() {
    nvim -u $_CONF_FILE "$@"
}


main() {
    check_init
    if ! [ -s "${_CONF_DIR}/lazy-lock.json" ]; then
      if [ -e "${_CONF_DIR}/lazy-lock.json" ]; then
        rm "$_CONF_DIR/lazy-lock.json" 
      fi
    fi
    wrapper "$@"
}


# RUN IT:
main "$@"
