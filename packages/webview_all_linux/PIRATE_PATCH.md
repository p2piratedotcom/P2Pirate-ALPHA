# Pirate Wallet Linux WebView changes

This directory is a local copy of `webview_all_linux` 1.4.1 from
https://pub.dev/packages/webview_all_linux. Its upstream MIT license and
copyright notices are preserved in `LICENSE` and the source files.

Pirate Wallet sets a process-local WebKit proxy at startup in
`linux/webview_proxy.cc`. The plugin patch forwards native libsoup POST
requests to that same proxy and disables WebRTC/media capture for embedded
WebViews. The proxy itself is a loopback-only HTTP-to-Tor-SOCKS bridge, which
forwards target hostnames without resolving them locally.

Do not replace this directory with a floating pub.dev version or remove its
path override without rechecking all native request paths and Tor leak tests.
