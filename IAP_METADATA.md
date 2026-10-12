# In-App Purchase metadata (App Store Connect)

All products are **Non-Consumable**. Product IDs must match `Pong/Theme.swift` exactly.
Display Name max is 30 characters and Description max is 45 characters in App Store Connect; every entry below fits.

| Product ID | Reference Name | Display Name | Description | Price |
|---|---|---|---|---|
| `com.white-oak-ai.pong.theme.neon` | Neon Theme | Neon Theme | Glowing cyan and magenta on midnight. | $0.99 |
| `com.white-oak-ai.pong.theme.terminal` | Terminal Theme | Terminal Theme | Green phosphor glow, old-school monitor. | $0.99 |
| `com.white-oak-ai.pong.theme.sunset` | Sunset Theme | Sunset Theme | Warm orange and pink over dusky purple. | $0.99 |
| `com.white-oak-ai.pong.theme.ocean` | Ocean Theme | Ocean Theme | Cool blues in a deep-sea court. | $0.99 |
| `com.white-oak-ai.pong.theme.gold` | Gold Theme | Gold Theme | Polished gold paddles on black. | $0.99 |
| `com.white-oak-ai.pong.theme.paper` | Paper Theme | Paper Theme | Ink on cream with a red ball. Light look. | $0.99 |
| `com.white-oak-ai.pong.theme.amber` | Amber Theme | Amber Theme | Retro amber CRT glow. | $0.99 |
| `com.white-oak-ai.pong.theme.blueprint` | Blueprint Theme | Blueprint Theme | White linework on engineer's blue. | $0.99 |
| `com.white-oak-ai.pong.theme.lava` | Lava Theme | Lava Theme | Molten red-orange on volcanic black. | $0.99 |
| `com.white-oak-ai.pong.theme.forest` | Forest Theme | Forest Theme | Mossy greens on a dark woodland court. | $0.99 |
| `com.white-oak-ai.pong.theme.candy` | Candy Theme | Candy Theme | Bubblegum pink and sky blue. Light look. | $0.99 |
| `com.white-oak-ai.pong.theme.cyberpunk` | Cyberpunk Theme | Cyberpunk Theme | Yellow, hot pink and cyan on deep indigo. | $0.99 |
| `com.white-oak-ai.pong.theme.all` | All Themes Bundle | All Themes | Unlock every theme, now and in future. | $2.99 |

## Review notes (paste into every product)

To see this item: launch the app, tap THEMES on the main menu, and find the theme card.
Tapping its price button starts the purchase. Purchases only change the colours of the
court; they do not affect gameplay. RESTORE PURCHASES is at the bottom of the same screen.

## Review screenshot

Required for each product. Take one screenshot of the THEMES screen (landscape) showing the
item. One shared image for all products is accepted.

## App-level notes

- Export compliance: `ITSAppUsesNonExemptEncryption` is set to `false` (no custom encryption).
- Add all 13 products to the app version under "In-App Purchases" before submitting for review.
- Paid Apps Agreement, banking and tax must be Active before products load.
