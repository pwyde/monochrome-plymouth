# Monochrome Plymouth - CHANGELOG

## First Release - 2 February 2019

- First release of Monochrome Plymouth.

## Arch Linux Build Hook Improvements - 3 February 2019

- Added self-checks to build hook. Exit if file dependencies are not found, i.e. font files.
- Automatically includes Plymouth label plugin and its dependencies.

## Major Release Update - 11 February 2019

- Complete rewrite of installation script:
  - Added support for distro identifcation.
  - Added support for installation of distro specific build hooks depending on identified distro.
  - Added automatic change of distro logo depending on identified distro.
  - Added optional custom font support.
- Added build hooks:
  - KDE Neon
- Added distro logos:
  - Debian
  - Fedora
  - KDE Neon
  - Kubuntu
  - Manjaro
  - Tux (used for generic or unidentifiable distro)
  - Ubuntu
- Updated README:
  - Added technical details.
  - Added information about limitations.
    - List of supported distributions.
  - Added installation instructions:
    - Install script.
    - Specific instructions for Arch Linux.
    - Specific instructions for KDE Neon.
  - Updated credits.
  - Updated todo list.
