# Turing Lab App Store Screenshot Mapping

This directory contains the Apple App Store screenshot set for the current Turing Lab release candidate asset pass.

Each device class includes 5 screenshots, one per supported module:

- `01-fsa`: Finite State Automata
- `02-grammar`: Context-Free Grammars
- `03-pda`: Pushdown Automata
- `04-tm`: Turing Machines
- `05-regex`: Regular Expressions

## Capture layout

- `iphone-6.9/`: 1320 x 2868 portrait
- `iphone-6.5/`: 1284 x 2778 portrait
- `iphone-5.5/`: 1242 x 2208 portrait
- `ipad-13/`: 2048 x 2732 portrait
- `macos/`: Current Turing Lab screenshots use 2880 x 1800 landscape. Apple accepts any 16:10 macOS screenshot size: 1280 x 800, 1440 x 900, 2560 x 1600, or 2880 x 1800.

## App Store Connect media slot mapping

### iPhone 6.9-inch

1. `screenshots/app_store/iphone-6.9/01-fsa.png`
2. `screenshots/app_store/iphone-6.9/02-grammar.png`
3. `screenshots/app_store/iphone-6.9/03-pda.png`
4. `screenshots/app_store/iphone-6.9/04-tm.png`
5. `screenshots/app_store/iphone-6.9/05-regex.png`

### iPhone 6.5-inch

1. `screenshots/app_store/iphone-6.5/01-fsa.png`
2. `screenshots/app_store/iphone-6.5/02-grammar.png`
3. `screenshots/app_store/iphone-6.5/03-pda.png`
4. `screenshots/app_store/iphone-6.5/04-tm.png`
5. `screenshots/app_store/iphone-6.5/05-regex.png`

### iPhone 5.5-inch

1. `screenshots/app_store/iphone-5.5/01-fsa.png`
2. `screenshots/app_store/iphone-5.5/02-grammar.png`
3. `screenshots/app_store/iphone-5.5/03-pda.png`
4. `screenshots/app_store/iphone-5.5/04-tm.png`
5. `screenshots/app_store/iphone-5.5/05-regex.png`

### iPad 13-inch

1. `screenshots/app_store/ipad-13/01-fsa.png`
2. `screenshots/app_store/ipad-13/02-grammar.png`
3. `screenshots/app_store/ipad-13/03-pda.png`
4. `screenshots/app_store/ipad-13/04-tm.png`
5. `screenshots/app_store/ipad-13/05-regex.png`

### Legacy 12.9-inch compatibility

Use the same `ipad-13/` screenshot set above. App Store Connect accepts the same `2048 x 2732` portrait assets for legacy 12.9-inch iPad classes.

### macOS

1. `screenshots/app_store/macos/01-fsa.png`
2. `screenshots/app_store/macos/02-grammar.png`
3. `screenshots/app_store/macos/03-pda.png`
4. `screenshots/app_store/macos/04-tm.png`
5. `screenshots/app_store/macos/05-regex.png`

## Notes

- Each device class satisfies the App Store requirement of 3-10 screenshots.
- The directory naming is stable enough for upload scripts or manual App Store Connect assignment.
- The macOS set currently uses the `2880 x 1800` size variant. Keep the upload
  ordering from the mapping above even if future screenshots use another
  accepted 16:10 macOS size.
