# TiZoomTransition 1.0.0

Native iOS 18+ fluid zoom transitions for Titanium modal windows and navigation pushes.

## Methods

### `isSupported()`

Returns whether the current iOS version supports `UIViewController.Transition.zoom`.

### `prepareWindow(window, options)`

Applies the native zoom transition to a destination window. `options.sourceView` is required. `options.scrollView` may reference a `Ti.UI.ScrollView`, `Ti.UI.TableView`, or `Ti.UI.ListView` to gate downward interactive dismissal at its adjusted top edge.

Optional properties are `interactiveDismiss` (`true`), `onlyWhenScrollAtTop` (`true`), `scrollTopTolerance` (`1` point), and `fullScreen` (`false`).

### `setSourceView(window, sourceView)`

Updates the visible source to use for the reverse zoom of an already prepared window.

### `clearWindow(window)`

Removes the prepared transition from the destination controller.

See the repository README, `example/app.js`, and `example/alloy/` for Classic and Alloy usage.
