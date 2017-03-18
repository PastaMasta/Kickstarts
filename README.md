pxe-builds
======================

This repo contains kickstart files and helper scripts to build boxes via pxe.

Current builds are:

* CentOS 6
* CentOS 6 with chef
* CentOS 7
* CentOS 7 with chef

Intended to be used with the chef-master cookbook.

Most of the helper scripts are interactive allowing for a mostly-automated build.

set-hostname.sh will ask for a hostname and update the relevent files.
find-disks.sh Will confirm the disk for rootvg if there is more than one detected.
setup-chef.sh Installs chef-client and bootstraps.

License and Authors
-------------------
Authors: PastaMasta  
See [LICENSE](LICENSE.md) for license rights and limitations (GNU GPLv3).
