# App Store capture font

`WorkSans-Regular.ttf` is loaded only by the headless App Store capture
harness. It supplies the Unicode arrow (`U+2192`) requested through the app's
monospace fallback list; the default Flutter test fonts render that character
as `.notdef`. The app's text and production font configuration remain
unchanged.

Source: `flutter_gallery_assets` 1.0.2, originally published from the Flutter
Gallery assets repository. SHA-256:
`402d5a357b1775e1c389c78fbe3f640c1a66de6ec6da7c49ffda3fc8602774c1`.

Work Sans is distributed under the SIL Open Font License 1.1. See `OFL.txt`.
