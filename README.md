# StorefrontsKit

StorefrontsKit (`SFML.xcframework`) is a library which renders SFML (Storefronts markup language) in an iOS app. StorefrontsKit is a wholly separate library from FlyerKit, requiring a new integration with a client app. Any classes or functionality coincentally shared between the two are not actively supported and may break at any time. This readme assumes it is being used as a standalone binary and not through a depedency management system like Carthage.

`SFMLStatic.xcframework` is a static version of the library. To correctly compile it in your project be sure to add '-lc++' under 'Other Linker Flags'. 

## StorefrontsKitSample App

The provided package imports `SFML.xcframework` from the `Sources` folder and uses `SDWebImage` for image loading through SPM.

See `StorefrontViewController.swift` in the StorefrontsKitSample to see a live example of how `StorefrontSFMLView` and its delegate protocols are used/implemented.

# Getting Started
There are several main features and functionalities that StorefrontsKit provides. They are as follows
- Rendering a storefront using `StorefrontSFMLView` or `SFMLView` (superclass without wayfinding capabilities – for 99% of use cases, use `StorefrontSFMLView`)
- Responding to wayfinder events via  `SFMLViewWayfinderDelegate`
- Being notified of analytics events via `SFMLViewAnalyticsDelegate`
- Responding to `SFMLView` events via `SFMLViewDelegate`

## Installation

### Swift Package Manager
Use this repo URL as the package URL and select the `SFML` package when prompted. You may have to add your GitHub credentials to Xcode.

### Manually
Link `SFML.xcframework` to your project by adding it under `Linked Frameworks and Libraries`. You may also need to add it under `Embedded Binaries` (if using the standalone binary).

## Quick start
To use StorefrontsKit, there are several integration points that you must implement:
- Creating a image download task provider `SFMLImageDownloadTaskProvider`
- Creating and laying out an instance of  `StorefrontSFMLView`
- Implementing accessibility
- Loading a storefront
- Providing app lifecycle hookups for `StorefrontSFMLView` for analytics to function

The following are modified snippets from `StorefrontsKitSample`.


### Creating an image download task provider

```
class DownloadTaskProvider: SFMLImageDownloadTaskProvider {
  func newImageDownloadTask() -> SFMLImageDownloadTask {
    return ImageDownloadTask()
  }
}

// A SFMLImageDownloadTask using SDWebImage for image loading
class ImageDownloadTask: NSObject, SFMLImageDownloadTask {
  private var task: SDWebImageOperation?
  
  func cancel() {
    task?.cancel()
  }
  
  func loadImage(withURL url: URL,
                 completion: @escaping (UIImage?, Error?) -> ()) {
    cancel()
    
    // Load the image and on completion we call the given completion block.
    task = SDWebImageManager.shared.loadImage(
      with: url,
      options: .retryFailed,
      progress: nil,
      completed: { (image, data, error, cacheType, finished, imageURL) in
        completion(image, error)
    })
  }
}
```


### Creating and laying out an instance of `StorefrontSFMLView`
```
// Assuming that self conforms to SFMLImageDownloadTaskProvider
let storefrontView = StorefrontSFMLView(imageDownloadTaskProvider: self)
storefrontView.translatesAutoresizingMaskIntoConstraints = false
view.addSubview(storefrontView)

// Layout the view
storefrontView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
storefrontView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
storefrontView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
storefrontView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
```

### Setting visibility on the `StorefrontSFMLView`

Set the `isVisible` property appropriately, for example on view lifecycle events of the 
the view controller the `StorefrontSFMLView` belongs to (`viewWillAppear(_:)`, etc.). This 
ensures certain analytics tracking methods are called correctly.

### Implementing accessibility
Every element that is accessible is represented by a `UIAccessibilityElement` (or subclass) object. This includes native elements (like `UIView`s, `UIButton`s, etc.). Their native accessibility properties are unused.

All accessiblity elements are then set as an array on the `accessibilityElements` property of the internal "body" view that represents all elements of the rendered SFML document. This is to have more control over the order and behaviour of all accessibility elements.

Wayfinder accessibility is provided through the system's accessibility rotor. `UIAccessibilityElement`s are created out of the wayfinding categories which are accessible via the Headings rotor.

On `SFMLView` or `StorefrontSFMLView`, assign the `accessibilityDelegate` property. Implement the `SFMLAccessibilityElementDelegate` protocol to provide custom accessibility hints or values. In order to reference a particular item, cast the given item as an `SFMLFlyerViewAccessibilityElement`.

```
extension StorefrontViewController: SFMLAccessibilityElementDelegate {
  func sfmlAccessibilityHint(element: SFMLAccessibilityElement) -> String? {
    guard let flyerAccessibilityElement = element as? SFMLFlyerViewAccessibilityElement,
      let flyerItem = flyerItems[flyerAccessibilityElement.sourcedItemID.itemID] else {
        return nil
    }
    
    var hint = "Double tap to clip."
    
    if clippings.contains(flyerItem) {
      hint = "Double tap to unclip."
    }
    
    return hint
  }
  
  func sfmlAccessibilityValue(element: SFMLAccessibilityElement) -> String? {
    return nil
  }
}

```

### Restoring the last focused accessibility element

When using VoiceOver, the most recent focused `UIAccessibilityElement` in the body
of the `SFMLView` is tracked and focus on it can be restored when the `SFMLView` 
becomes visible again. Two things are required to enable this functionality:

- `shouldTrackAccessibilityFocus` property on `SFMLView` which when `true`, observes
`UIAccessibility.elementFocusedNotification` and tracks the most recent element focused
in the SFML body. This property automatically mirrors `isVisible` but can be set
manually as well depending on the use case. See the code documentation for this property for details. The default value is `true`.
- `restoreFocusOnPreviouslyFocusedAccessibilityElement()` method on `SFMLView` which 
when called, attempts to focus on the most recently focused `UIAccessibilityElement` in the body
of the `SFMLView`. See code documentation for details on usage.

See the StorefrontsKitSample app for an example implementation.

### Loading a storefront

```
let data = // Downloaded data from network

// storefrontView is an instance of `StorefrontSFMLView`
storefrontView.load(
  sfml: data,
  titlePreload: { (title, subtitle) -> (Void) in
    self.title = title
},
  completion: { (error) -> (Void) in
    guard error == nil else {
      print("Error loading storefront: \(error!)")
      return
    }

    // Set visibility to true after load in case it hasn't loaded yet on `viewDidAppear(_:)`
    self.storefrontView.isVisible = true 
})
```

### Analytics hookups
Analytics hooks are provided via the `SFMLAnalytics` class. This class provides a couple customizable static properties (durations) as well as a `delegate` to receive analytics events. This delegate property is accessible via the `analytics` property of `StorefrontSFMLView`. 

```
storefrontView.analytics.delegate = self
```

See `SFMLViewAnalyticsDelegate` to see which events are available.

Note that in order for analytics events to be triggered correctly, **visibility** of the view must be set correctly via the `isVisible` property. Please see the documentation for this property for more detail. For any customization (such as timer durations), refer to the static properties in the `SFMLAnalytics` class.

The areas where visibility should be set are:

**On View Lifecycle Methods in `UIViewController`**
```
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    // Set visibility to true when the view appears
    storefrontView.isVisible = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Set visibility to false when the view disappears
    storefrontView.isVisible = false
  }
```

**On App Lifecycle Events**

We set up notification handlers for two app lifecycle events (when it goes into the background and when it becomes active):

```
  func setupAppLifecycleNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationDidEnterBackground(_:)),
      name: .UIApplicationDidEnterBackground,
      object: nil)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationDidBecomeActive(_:)),
      name: .UIApplicationDidBecomeActive,
      object: nil)
  }

  @objc func applicationDidEnterBackground(_ notification: NSNotification) {
    if isViewLoaded && view.window != nil {
      storefrontView.isVisible = false
    }
  }
  
  @objc func applicationDidBecomeActive(_ notification: NSNotification) {
    if isViewLoaded && view.window != nil {
      storefrontView.isVisible = true
    }
  }
```
