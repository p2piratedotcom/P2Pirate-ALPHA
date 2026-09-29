# P2Pirate branding provenance

This PR changes the visible Flutter name and menu/theme logo. The P icon in
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
The Linux branding follow-up copies this same icon, unchanged, to
`linux/PirateWallet.png`, installs it in the Flutter bundle, and uses it for
the GTK window and desktop entry. The visible window and launcher title become
P2Pirate. The technical executable name `CheetahDEX` and GTK application ID
remain unchanged until their data and packaging compatibility is reviewed.
Branding on other platforms, data folder migration, and release packaging
are tracked separately.
