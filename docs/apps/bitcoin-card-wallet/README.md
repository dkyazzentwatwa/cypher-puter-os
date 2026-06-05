# Bitcoin Card Wallet

## Cypher OS Package

| Field | Value |
| --- | --- |
| Catalog slug | `bitcoin-card-wallet` |
| SD binary | `/cypher-puter/apps/bitcoin-card-wallet.bin` |
| Source repo | https://github.com/dkyazzentwatwa/cardputer-app-bundle |
| Local source path | `/Users/cypher/Documents/GitHub/new-cardputer-apps/Bitcoin-Card-Wallet` |
| Build profile | `cardputer` |
| Extra SD paths | `/card-wallets.txt` |
| Return path | Choose Return to Cypher OS from the main menu. |
| Package note | Built from the public `cardputer-app-bundle` repo while the default local checkout remains `../new-cardputer-apps`. |

## Overview

Bitcoin Card Wallet is packaged as a standalone Cypher OS catalog app. The
Cypher OS build uses the bundle sketch profile plus the app's required linker
flag and copies only the sketch app binary into the SD catalog.

## Return To Cypher OS

Use the app's main menu item labeled `RETURN TO CYPHER OS`. It sets the
one-shot launcher return flag, selects `ota_0`, and restarts.
