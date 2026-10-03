P2Pirate Linux Tor transport source and licenses

lib/tor is the unmodified /usr/bin/tor from Ubuntu 24.04 amd64 package
tor 0.4.9.11-0ubuntu0.24.04.1. This Ubuntu build was configured with
--enable-gpl and reports GNU GPL version 3 in its --version output.
Its copyright and component notices are in lib/TOR_COPYRIGHT; the full
GPL version 3 text is at the root of this AppImage in LICENSE.

lib/libtorsocks.so is the unmodified libtorsocks.so.0 from Ubuntu 24.04
amd64 package torsocks 2.4.0-1. It is GPL version 2 or later.
Its copyright notice is in lib/TORSOCKS_COPYRIGHT and the full GPL
version 2 text is in lib/GPL-2.0.txt.

The six exact corresponding Ubuntu source package files are in
lib/tor-source/. Each .dsc lists the upstream archive and the Ubuntu or
Debian packaging changes needed to reconstruct its package source tree.

Tor: https://packages.ubuntu.com/source/noble-updates/net/tor
torsocks: https://packages.ubuntu.com/source/noble/net/torsocks

The binary, notice and source SHA-256 values are recorded in
docs/LINUX_ASSET_PROVENANCE.md of the P2Pirate-ALPHA source repository.
