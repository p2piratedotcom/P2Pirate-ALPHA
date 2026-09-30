# P2Pirate branding provenance

The local P2Pirate customization changes the visible Flutter name and menu/theme logo. The P icon in
`assets/logo/pirate_icon.png` is an unmodified copy of
[`P Logo/PNG/Pirate_Logo_P_Gold.png`](https://github.com/PirateNetwork/mediakit/blob/7cda2529b4a5b61b7cf80ebf8994ee9bbd8eab30/P%20Logo/PNG/Pirate_Logo_P_Gold.png)
from the official Pirate Chain media kit at commit
`7cda2529b4a5b61b7cf80ebf8994ee9bbd8eab30`. The media kit's MIT license
and copyright notice are preserved at `licenses/pirate-mediakit/LICENSE`.

The current [Pirate Chain branding guide](https://piratechain.com/canvas/)
promotes the P logo and advises against ship and skull logos. The
[official media kit](https://github.com/PirateNetwork/mediakit) offers P logos
for community use. This repository does not claim ownership of Pirate Chain
marks or imply official endorsement.

The Flutter wallet code retains its upstream GPL license and attribution.
The original P icon remains in `assets/logo/pirate_icon.png` for provenance.
The application identity now uses artwork supplied by the P2Pirate project:
`assets/logo/p2pirate_wordmark.png` is the unchanged supplied image, while
`assets/logo/p2pirate_emblem.png` is a square, transparent derivative made by
removing the wordmark and completing the circular rim. The simplified
`assets/logo/p2pirate_mark.png` was generated from that emblem for legibility at
small sizes. It has a larger portrait and heavier shapes, with no wordmark or
fine decorative lines. The mark appears above the P2Pirate name in the desktop
menu and is copied to `linux/PirateWallet.png` for the GTK window and Linux
desktop icon. This artwork is a P2Pirate identity, not the official
Pirate Chain P mark; the application does not claim official endorsement.

The app theme follows the [Pirate Chain canvas](https://piratechain.com/canvas/):
gold `#BB9645` for actions and selection, black and white surfaces and text,
and Roboto as the main typeface. The six theme files under `app_theme/lib/src/`
use the color treatment present in the supplied ZIP as a starting point.
Navigation SVGs now use gold for active states and neutral gray for inactive
states. Widgets that had used `onSurface` as a background use `surface`, so
the dark theme can keep `onSurface` white for readable text. Protocol-specific
coin colors remain unchanged. The theme change does not alter KDF or wallet
logic.

For Linux, `scripts/install_linux_desktop.sh BUNDLE_DIR [LAUNCHER]` installs
the icon and a per-user desktop entry. The optional launcher can set the
separately installed KDF path. The desktop entry filename matches the current
GTK application ID `com.shorelinecrypto.CheetahDEX`, which allows GNOME to
associate the running window with the icon. The technical executable name
`CheetahDEX` and GTK application ID remain unchanged to preserve compatibility.
The installer refreshes the per-user GTK icon cache after copying the icon.
Branding on other platforms, data folder migration, and release packaging are
tracked separately.

The Settings navigation now contains only P2Pirate relevant pages. The old
GLEEC Privacy Notice and KYC pages, GLEEC EULA/terms acceptance widgets, and
their bundled legal files were removed. Wallet creation and import still use
their existing form validation. Support text points to the P2Pirate repository.
Unreferenced GLEEC logo files were removed from `assets/logo/`. Historical
upstream attribution remains in documentation. Some GLEEC API endpoints and
the GLEEC coin ticker remain in source because they are live dependencies or
asset identifiers; changing them requires separate functional review.
