Buildroot Weston + custom WebKitGTK browser
###########################################

Author: P. Geiser

Targets
-------
- Raspberry Pi 4 (64-bit)
- Raspberry Pi 5 (64-bit)

Build
-----
::

    ./build.sh

By default, runs all steps: buildroot, apt, defconfig, sdk, build, release.

Individual steps can be specified::

    ./build.sh buildroot defconfig build release

Packages
--------
- **PaGBrowser**: Modified WebKit browser (WebKitGTK)

Output
------
Release images are created in the ``release/`` directory:
- ``sdcard.img.zst``: SD card image
- ``squash.img.zst``: SquashFS image
