# Building TiZoomTransition

From the repository root, build and package the iOS module with an explicit project directory and Titanium SDK:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  ti build -p ios \
  --build-only \
  --target simulator \
  --project-dir ios \
  --sdk 13.3.1.v20260702183342 \
  --no-prompt \
  --no-banner
```

The packaged module is written to `dist/ti.zoomtransition-iphone-1.0.0.zip`.
