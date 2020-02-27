#!/usr/bin/env bash

# Install script for Monochrome Plymouth.
# Copyright (C) 2019 Patrik Wyde <patrik@wyde.se>
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
status=""
git_hosting="gitlab.com"
git_repo="monochrome-plymouth"
git_desc="Monochrome Plymouth"
prefix="/usr/share"
tag="dev"
install="false"
uninstall="false"
## Colorize output.
# shellcheck disable=SC2034
red="\033[91m"
# shellcheck disable=SC2034
green="\033[92m"
# shellcheck disable=SC2034
blue="\033[94m"
# shellcheck disable=SC2034
yellow="\033[93m"
# shellcheck disable=SC2034
cyan="\033[96m"
# shellcheck disable=SC2034
magenta="\033[95m"
# shellcheck disable=SC2034
white="\033[1m"
# shellcheck disable=SC2034
no_color="\033[0m"

temp_file="$(mktemp -u)"
temp_dir="$(mktemp -d)"

print_header() {
echo -e "
 ${blue}_____                 _
|     |___ ___ ___ ___| |_ ___ ___ _____ ___
| | | | . |   | . |  _|   |  _| . |     | -_|
|_|_|_|___|_|_|___|___|_|_|_| |___|_|_|_|___|

 _____ _                   _   _
|  _  | |_ _ _____ ___ _ _| |_| |_
|   __| | | |     | . | | |  _|   |
|__|  |_|_  |_|_|_|___|___|_| |_|_|
        |___|${no_color}

  ${yellow}${git_desc}${no_color}
  https://${git_hosting}/pwyde/${git_repo}
" >&2
}

print_help() {
echo -e "
${white}Description:${no_color}
  Install script for the ${git_desc} theme.
  Script will automatically download the latest version from the Git repository
  and copy the required files to '${prefix}'.

${white}Examples:${no_color}
  Install: ${0} --install
  Uninstall: ${0} --uninstall
  Install with specified font: ${0} --install --font <path>

${white}Options:${no_color}
  ${cyan}-i${no_color}, ${cyan}--install${no_color}      Install theme in default location (${prefix}).

  ${cyan}-u${no_color}, ${cyan}--uninstall${no_color}    Uninstall theme.

  ${cyan}-f${no_color}, ${cyan}--font${no_color}         If not specified, 'Noto Sans' will be used as the default
                     font. Install theme with specified font instead, i.e.
                     '/usr/share/fonts/TTF/DejaVuSans.ttf'.
" >&2
}

# Print help if no argument is specified.
if [[ "${#}" -le 0 ]]; then
    print_header
    print_help
    exit 1
fi

# Loop as long as there is at least one more argument.
while [ "${#}" -gt 0 ]; do
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
        -h|--help) print_header; print_help; exit ;;
        *) echo "Invalid option '${arg}'." >&2; print_header; print_help; exit 1 ;;
    esac
    # Shift after checking all the cases to get the next option.
    shift > /dev/null 2>&1;
done

print_msg() {
    echo -e "$green=>$no_color$white" "$@" "$no_color" >&1
}

print_error() {
    echo -e "$red=> ERROR:$no_color$white" "$@" "$no_color" >&1
}

print_status() {
    if [ -z "${status}" ]; then
        print_msg "Completed!"
    else
        print_error "Completed with errors!"
    fi
}

# Delete parent directories if empty.
delete_dir() {
    sudo rm -rf "${1}"
    sudo rmdir -p "$(dirname "${1}")" 2>/dev/null || true
}

cleanup() {
    rm -rf "${temp_file}" "${temp_dir}"
    if [ -e "${temp_file}" ]; then
        print_error "Unable to delete temporary file '${temp_file}'!"
        status=1
    fi
    if [ -e "${temp_dir}" ]; then
        print_error "Unable to delete temporary directory '${temp_dir}'!"
        status=1
    fi
}

download_pkg() {
    # Test if Git hosting provider is reachable.
    print_msg "Verifying that Git hosting provider ($git_hosting) is reachable..."
    if ping -c 5 "${git_hosting}" >/dev/null 2>&1; then
        print_msg "Downloading latest version from $tag branch..."
    wget --progress=bar:force --output-document "${temp_file}" "https://${git_hosting}/pwyde/${git_repo}/-/archive/${tag}/${git_repo}-${tag}.tar.gz"
        print_msg "Extracting archive..."
        tar -xzf "${temp_file}" -C "${temp_dir}"
    else
        print_error "Unable to communicate with Git hosting provider ($git_hosting)! Exiting..."
        exit 1
    fi
}

# Try to identify distro.
get_distro() {
    if [ -f "/etc/os-release" ]; then
        # freedesktop.org and systemd
        # shellcheck disable=SC1091
        source /etc/os-release
        os="${NAME}"
        ver="${VERSION_ID}"
    elif type lsb_release >/dev/null 2>&1; then
        # Linux Standard Base (LSB), linuxbase.org
        os=$(lsb_release -si)
        ver=$(lsb_release -sr)
    elif [ -f "/etc/lsb-release" ]; then
        # For some versions of Debian/Ubuntu without lsb_release command.
        # shellcheck disable=SC1091
        source /etc/lsb-release
        os="${DISTRIB_ID}"
        ver="${DISTRIB_RELEASE}"
    elif [ -f "/etc/debian_version" ]; then
        # Older Debian/Ubuntu/etc.
        os=Debian
        ver=$(cat /etc/debian_version)
    else
        # Fall back to uname, i.e. "Linux <version>", also works for BSD, etc.
        os=$(uname -s)
        # shellcheck disable=SC2034
        ver=$(uname -r)
    fi
}

# Configure theme with identified distro.
# Note: Not all distributions are supported!
conf_theme() {
    if [ -n "${os}" ]; then
        if [ "${os}" = "Arch Linux" ]; then
            print_msg "Identified supported distribution as '${os}'..."
            sed -i "s/<distro name>/${os}/" "${temp_dir}/${git_repo}-${tag}/monochrome/monochrome.script"
            sed -i "s/<distro logo>/arch-linux/" "${temp_dir}/${git_repo}-${tag}/monochrome/monochrome.script"
        elif [ "${os}" = "KDE neon" ]; then
            print_msg "Identified supported distribution as '${os}'..."
            sed -i "s/<distro name>/${os}/" "${temp_dir}/${git_repo}-${tag}/monochrome/monochrome.script"
            sed -i "s/<distro logo>/kde-neon/" "${temp_dir}/${git_repo}-${tag}/monochrome/monochrome.script"
        else
            print_error "Identified un-supported distribution as '${os}'..."
            sed -i "s/<distro logo>/tux/" "${temp_dir}/${git_repo}-${tag}/monochrome/monochrome.script"
        fi
    else
        print_error "Could not identify distribution!"
        sed -i "s/<distro>//" "${temp_dir}/${git_repo}-${tag}/monochrome/monochrome.script"
    fi
    # Check if custom font is specified.
    if [ -n "$font_path" ]; then
        # Configure theme with custom font if specified.
        if [ -f "$font_path" ]; then
            print_msg "Adding custom font '${font_path}'..."
            font_name=$(fc-list | grep "${font_path}" | awk -F ":" '{print $2}' | sed "s/ //")
            sed -i "s/Noto Sans/${font_name}/g" "${temp_dir}/${git_repo}-${tag}/monochrome/monochrome.script"
            # Configure build hooks with specified custom font.
            for filename in "${temp_dir}"/"${git_repo}"-"${tag}"/hooks/*; do
                sed -i "s|<font path>|${font_path}|" "${filename}"
                sed -i "s/###//" "${filename}"
            done
        else
            print_error "The specified font '${font_path}' is missing!"
            print_msg "Skipping custom font installation..."
            clean_hooks
        fi
    else
        clean_hooks
    fi
}

# Remove custom font preperation in build hooks.
clean_hooks() {
    for filename in "${temp_dir}"/"${git_repo}"-"${tag}"/hooks/*; do
        sed -i "/custom_font_path/d" "${filename}"
        sed -i "/Add custom font/d" "${filename}"
        sed -i "/###/d" "${filename}"
    done
}

install_theme() {
    print_msg "Installing ${git_desc} to '${prefix}'..."
    sudo cp -R "${temp_dir}/${git_repo}-${tag}/monochrome" "${prefix}/plymouth/themes"
    if [ ! -d "${prefix}/plymouth/themes/monochrome" ]; then
        print_error "Unable to install '${prefix}/plymouth/themes'!"
        status=1
    fi
}

# Install build hooks.
# Note: Not all distributions are supported!
install_hooks() {
    if [ -n "${os}" ]; then
        # Install build hook for Arch Linux.
        if [ "${os}" = "Arch Linux" ]; then
            print_msg "Installing build hook for '${os}'..."
            sudo cp "${temp_dir}/${git_repo}-${tag}/hooks/monochrome-plymouth" "/etc/initcpio/install"
        # Install build hook for KDE Neon.
        elif [ "${os}" = "KDE neon" ]; then
            print_msg "Installing build hook for '${os}'..."
            sudo cp "${temp_dir}/${git_repo}-${tag}/hooks/plymouth_monochrome" "/usr/share/initramfs-tools/hooks"
        else
            print_error "Un-supported distribution identified. Unable to install build hook!"
            print_error "Monochrome Plymouth may not work properly!"
            status=1
        fi
    else
        print_error "Could not identify distribution. Unable to install build hook!"
        print_error "Monochrome Plymouth may not work properly!"
        status=1
    fi
}

uninstall_theme() {
    if [ -d "${prefix}/plymouth/themes/monochrome" ]; then
        print_msg "Uninstalling ${git_desc}..."
        delete_dir "${prefix}/plymouth/themes/monochrome"
    else
        print_error "Could not find ${git_desc}! Probably not installed."
        status=1
    fi
}

uninstall_hooks() {
    # Uninstall build hook for Arch Linux.
    if [ -f "/etc/initcpio/install/monochrome-plymouth" ]; then
        print_msg "Uninstalling build hook 'monochrome-plymouth'..."
        delete_dir "/etc/initcpio/install/monochrome-plymouth"
    # Uninstall build hook for KDE Neon.
    elif [ -f "/usr/share/initramfs-tools/hooks/plymouth_monochrome" ]; then
        print_msg "Uninstalling build hook 'plymouth_monochrome'..."
        delete_dir "/usr/share/initramfs-tools/hooks/plymouth_monochrome"
    else
        print_error "Could not find build hook! Probably not installed."
        status=1
    fi
}

if [ "${uninstall}" = "false" ] && [ "${install}" = "true" ]; then
    print_header
    download_pkg
    get_distro
    conf_theme
    install_theme
    install_hooks
    cleanup
    print_status
elif [ "${uninstall}" = "true" ] && [ "${install}" = "false" ]; then
    print_header
    download_pkg
    get_distro
    uninstall_theme
    uninstall_hooks
    cleanup
    print_status
else
    print_msg "Missing or invalid options, see help below."
    print_header
    print_help
    exit 1
fi
