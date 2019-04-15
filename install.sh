#!/usr/bin/env bash

# Install script for Monochrome Plymouth.
# Copyright (C) 2019 Patrik Wyde <path@wyde.se>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Configure script variables.
git_repo="monochrome-plymouth"
git_desc="Monochrome Plymouth"
prefix="/usr/share"
tag="master"
install="false"
uninstall="false"

temp_file="$(mktemp -u)"
temp_dir="$(mktemp -d)"

_print_header() {
echo "                                             
 _____                 _                     
|     |___ ___ ___ ___| |_ ___ ___ _____ ___ 
| | | | . |   | . |  _|   |  _| . |     | -_|
|_|_|_|___|_|_|___|___|_|_|_| |___|_|_|_|___|
                                             
 _____ _                   _   _             
|  _  | |_ _ _____ ___ _ _| |_| |_           
|   __| | | |     | . | | |  _|   |          
|__|  |_|_  |_|_|_|___|___|_| |_|_|          
        |___|                                
                                                                  
  $git_desc
  https://gitlab.com/pwyde/$git_repo
" >&2
}

_print_help() {
echo "
Description:
  Install script for the ${git_desc} theme.
  Script will automatically download the latest version from the Git repository
  and copy the required files to '${prefix}'.

Examples:
  Install: ${0} --install
  Uninstall: ${0} --uninstall
  Install with specified font: ${0} --install --font <path>
 
Options:
  -i, --install      Install theme in default location (${prefix}).
 
  -u, --uninstall    Uninstall theme.
  
  -f, --font         If not specified, 'Noto Sans' will be used as the default
                     font. Install theme with specified font instead, i.e.
                     '/usr/share/fonts/TTF/DejaVuSans.ttf'.
" >&2
}

# Print help if no argument is specified.
if [[ "${#}" -le 0 ]]; then
    _print_header
    _print_help
    exit 1
fi
 
# Loop as long as there is at least one more argument.
while [[ "${#}" -gt 0 ]]; do
    arg="${1}"
    case "${arg}" in
        # This is an arg value type option. Will catch both '-i' or
        # '--install' value.
        -i|--install) install="true" ;;
        # This is an arg value type option. Will catch both '-u' or
        # '--uninstall' value.
        -u|--uninstall) uninstall="true" ;;
        # This is an arg value type option. Will catch both '-f' or
        # '--font' value.
        -f|--font) shift; font_path="${1}" ;;
        # This is an arg value type option. Will catch both '-h' or
        # '--help' value.
        -h|--help) _print_header; _print_help; exit ;;
        *) echo "Invalid option '${arg}'." >&2; _print_header; _print_help; exit 1 ;;
    esac
    # Shift after checking all the cases to get the next option.
    shift
done

_print_msg() {
    echo "=>" "${@}" >&2
}

# Delete parent directories if empty.
_delete_dir() {
    sudo rm -rf "${1}"
    sudo rmdir -p "$(dirname "${1}")" 2>/dev/null || true
}

_cleanup() {
    rm -rf "${temp_file}" "${temp_dir}"
    _print_msg "Completed!"
}

_download_pkg() {
    _print_msg "Downloading latest version from master branch..."
    wget -O "${temp_file}" "https://gitlab.com/pwyde/${git_repo}/-/archive/${tag}/${git_repo}-${tag}.tar.gz"
    _print_msg "Extracting archive ..."
    tar -xzf "${temp_file}" -C "${temp_dir}"
}

# Try to identify distro.
_get_distro() {
    if [[ -f "/etc/os-release" ]]; then
        # freedesktop.org and systemd
        source /etc/os-release
        os="${NAME}"
        ver="${VERSION_ID}"
    elif type lsb_release >/dev/null 2>&1; then
        # Linux Standard Base (LSB), linuxbase.org
        os=$(lsb_release -si)
        ver=$(lsb_release -sr)
    elif [[ -f "/etc/lsb-release" ]]; then
        # For some versions of Debian/Ubuntu without lsb_release command.
        source /etc/lsb-release
        os="${DISTRIB_ID}"
        ver="${DISTRIB_RELEASE}"
    elif [[ -f "/etc/debian_version" ]]; then
        # Older Debian/Ubuntu/etc.
        os=Debian
        ver=$(cat /etc/debian_version)
    else
        # Fall back to uname, i.e. "Linux <version>", also works for BSD, etc.
        os=$(uname -s)
        ver=$(uname -r)
    fi
}

# Configure theme with identified distro.
# Note: At the moment only Arch Linux and KDE neon is supported.
_set_distro() {
    if [[ -n "${os}" ]]; then
        if [[ "${os}" = "Arch Linux" ]]; then
            sed -i "s/<distro name>/${os}/" "${temp_dir}/${git_repo}-${tag}/monochrome/monochrome.script"
            sed -i "s/<distro logo>/arch-linux/" "${temp_dir}/${git_repo}-${tag}/monochrome/monochrome.script"
        elif [[ "${os}" = "KDE neon" ]]; then
            sed -i "s/<distro name>/${os}/" "${temp_dir}/${git_repo}-${tag}/monochrome/monochrome.script"
            sed -i "s/<distro logo>/kde-neon/" "${temp_dir}/${git_repo}-${tag}/monochrome/monochrome.script"
        else
            sed -i "s/<distro logo>/tux/" "${temp_dir}/${git_repo}-${tag}/monochrome/monochrome.script"
        fi
    else
        sed -i "s/<distro>//" "${temp_dir}/${git_repo}-${tag}/monochrome/monochrome.script"
    fi
}

# Configure theme with custom font if specified.
_install_font() {
    if [[ -f "$font_path" ]]; then
        _print_msg "Adding custom font '${font_path}'..."
        font_name=$(fc-list | grep "${font_path}" | awk -F ":" '{print $2}' | sed "s/ //")
        sed -i "s/Noto Sans/${font_name}/g" "${temp_dir}/${git_repo}-${tag}/monochrome/monochrome.script"
        # Configure build hooks with specified custom font.
        for filename in "${temp_dir}"/"${git_repo}"-"${tag}"/hooks/*; do
            sed -i "s|<font path>|${font_path}|" "${filename}"
            sed -i "s/###//" "${filename}"
        done
    else
        _print_msg "The specified font '${font_path}' is missing!"
        _print_msg "Skipping custom font installation..."
        _clean_hooks
    fi
}

# Remove custom font preperation in build hooks.
_clean_hooks() {
    for filename in "${temp_dir}"/"${git_repo}"-"${tag}"/hooks/*; do
        sed -i "/custom_font_path/d" "${filename}"
        sed -i "/Add custom font/d" "${filename}"
        sed -i "/###/d" "${filename}"
    done
}

_install_pkg() {
    _print_msg "Installing ${git_desc} to '${prefix}'..."
    sudo cp -R "${temp_dir}/${git_repo}-${tag}/monochrome" "${prefix}/plymouth/themes"
}

# Install build hooks.
# Note: At the moment only Arch Linux and KDE neon is supported.
_install_hooks() {
    if [[ -n "${os}" ]]; then
        # Install build hook for Arch Linux.
        if [[ "${os}" = "Arch Linux" ]]; then
            sudo cp "${temp_dir}/${git_repo}-${tag}/hooks/monochrome-plymouth" "/etc/initcpio/install"
        # Install build hook for KDE Neon.
        elif [[ "${os}" = "KDE neon" ]]; then
            sudo cp "${temp_dir}/${git_repo}-${tag}/hooks/plymouth_monochrome" "/usr/share/initramfs-tools/hooks"
        fi
    else
        _print_msg "Could not identify distribution. Unable to install build hook!"
        _print_msg "Monochrome Plymouth may not work properly!"
    fi
}

_uninstall_pkg() {
    if [[ -d "${prefix}/plymouth/themes/monochrome" ]]; then
        _print_msg "Uninstalling ${git_desc}..."
        _delete_dir "${prefix}/plymouth/themes/monochrome"
    else
        _print_msg "Could not find ${git_desc}! Probably not installed."
    fi
}

if [[ "${uninstall}" = "false" && "${install}" = "true" ]]; then
    _print_header
    _download_pkg
    _get_distro
    _set_distro
    if [[ -n "$font_path" ]]; then
        _install_font
    else
        _clean_hooks
    fi
    _install_pkg
    _install_hooks
    _cleanup
elif [[ "${uninstall}" = "true" && "${install}" = "false" ]]; then
    _print_header
    _download_pkg
    _uninstall_pkg
    _cleanup
else
    _print_msg "Missing or invalid options, see help below."
    _print_header
    _print_help
    exit 1
fi
