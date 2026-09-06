# TiZoomTransition 1.0.0

Native iOS 18+ fluid zoom transitions for Titanium modal windows and navigation pushes.

## Methods

### `isSupported()`

Returns whether the current iOS version supports `UIViewController.Transition.zoom`.

### `prepareWindow(window, options)`

Applies the native zoom transition to a destination window. `options.sourceView` is required. `options.alignmentView` may reference a view inside the destination that the source should align with during the zoom. Its first valid alignment rectangle is cached so elastic table/list movement cannot shift the zoom target during interactive dismissal. `options.scrollView` may reference a `Ti.UI.ScrollView`, `Ti.UI.TableView`, or `Ti.UI.ListView` to gate downward interactive dismissal at its adjusted top edge.

Optional properties are `alignmentView`, `interactiveDismiss` (`true`), `onlyWhenScrollAtTop` (`true`), `scrollTopTolerance` (`1` point), and `fullScreen` (`false`).

For a table or list whose resting offset varies slightly because of elastic scrolling or adjusted insets, a `scrollTopTolerance` around `8` points can make the pull-to-dismiss handoff more reliable.

The module does not change the supplied scroll view's bounce configuration. Properties such as `disableBounce` remain under application control.

### `setSourceView(window, sourceView)`

Updates the visible source to use for the reverse zoom of an already prepared window.

### `setAlignmentView(window, alignmentView)`

Updates the destination alignment target and replaces its cached rectangle. Call this after a newly selected photo view is attached when each page uses a different Titanium view proxy.

### `refreshAlignmentRect(window)`

Invalidates and recaptures the alignment rectangle after a completed layout or orientation change. Do not call it continuously during scrolling or interactive dismissal.

### `clearWindow(window)`

Removes the prepared transition from the destination controller.

See the repository README, `example/app.js`, and `example/alloy/` for Classic and Alloy usage.
