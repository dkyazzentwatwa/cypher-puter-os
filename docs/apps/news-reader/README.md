# News Reader

## Cypher OS Package

| Field | Value |
| --- | --- |
| Catalog slug | `news-reader` |
| SD binary | `/cypher-puter/apps/news-reader.bin` |
| Source repo | https://github.com/dkyazzentwatwa/cardputer-app-bundle |
| Local source path | `/Users/cypher/Documents/GitHub/new-cardputer-apps/News-Reader` |
| Build profile | `cardputer` |
| Extra SD paths | `/news-reader/config.txt` |
| Return path | Press `Fn+Del`. |
| Package note | The SD package ships `/news-reader/config.example.txt` with placeholder values only. |

## Overview

News Reader fetches Guardian headlines over Wi-Fi. Cypher OS does not compile
private Wi-Fi or API values into the app; runtime settings are read from the SD
card.

## SD Config

Copy `/news-reader/config.example.txt` to `/news-reader/config.txt` on the SD
card and set:

```text
NEWS_WIFI_SSID=your-home-wifi
NEWS_WIFI_PASSWORD=your-wifi-password
GUARDIAN_API_KEY=your-guardian-api-key
```

## Return To Cypher OS

Press `Fn+Del` to set the one-shot launcher return flag, select `ota_0`, and
restart.
