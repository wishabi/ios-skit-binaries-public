
import UIKit
import SFML
import SDWebImage

class StorefrontViewController: UIViewController {
  fileprivate var storefrontView: StorefrontSFMLView!
  let sfmlURL: String
  let flyerID: Int

  private let headerView = UILabel()
  private let footerView = UILabel()
  
  fileprivate var flyerItems: [SFMLItemID: [String: Any]] = [:]
  fileprivate var clippings = NSMutableSet()
  
  init(sfmlURL: String, flyerID: Int) {
    self.sfmlURL = sfmlURL
    self.flyerID = flyerID
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = "Storefront"
    
    // Set up app cycle notifications so we know when to set `storefrontView`'s
    // visibility appropriately (i.e. we don't want analytics timers to continue
    // in the background when the app is not active).
    setupAppLifecycleNotifications()

    // Set up example custom header and footer views to render above and below the storefront
    setupCustomHeaderAndFooterViews()
    
    // Set up the view
    setupSFMLView()
    
    // Obtain the SFML data and pass it to the view to be rendered
    loadSFML()
    
    // Obtain flyer item data so we have data backing the view for interactions
    // (taps/long presses/etc.)
    loadFlyerItems()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    // Set visibility to true when the view appears
    storefrontView.isVisible = true

    // Restore the previously focused element for re-appearance via view
    // lifecycle methods
    storefrontView.restoreFocusOnPreviouslyFocusedAccessibilityElement()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Set visibility to false when the view disappears
    storefrontView.isVisible = false
  }
  
  private func setupAppLifecycleNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationDidEnterBackground(_:)),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationDidBecomeActive(_:)),
      name: UIApplication.didBecomeActiveNotification,
      object: nil)
  }

  private func setupCustomHeaderAndFooterViews() {
    headerView.backgroundColor = UIColor.lightGray
    headerView.text = "This is a custom non-SFML header view."
    headerView.font = UIFont.systemFont(ofSize: 25, weight: .semibold)

    footerView.backgroundColor = UIColor.lightGray
    footerView.text = "This is a custom non-SFML footer view."
    footerView.font = UIFont.systemFont(ofSize: 25, weight: .semibold)
  }
  
  private func setupSFMLView() {
    // Create the view and pass in self as the image download task provider
    storefrontView = StorefrontSFMLView(imageDownloadTaskProvider: self)
    storefrontView.delegate = self

    // Optionally disable the wayfinder
//    storefrontView.enableWayfinder = false

    storefrontView.wayfinderDelegate = self
    storefrontView.analytics.delegate = self
    storefrontView.accessibilityDelegate = self
    storefrontView.customFontName = "Raleway"
    storefrontView.wayfinderCategoryTitleHighlightedColor = UIColor.yellow
    storefrontView.wayfinderCategoryTitleColor = UIColor.red
    storefrontView.wayfinderCategoryTitleSelectedColor = UIColor.green
    storefrontView.wayfinderCategorySelectedColor = UIColor.purple
    storefrontView.wayfinderBackgroundColor = UIColor.cyan.withAlphaComponent(0.5)
    storefrontView.wayfinderScrollButtonImage = #imageLiteral(resourceName: "dude")
    storefrontView.wayfinderPadding = 8.0
    
    storefrontView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(storefrontView)
    
    storefrontView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    storefrontView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    storefrontView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    storefrontView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
  }
  
  private func loadSFML() {
    guard let url = URL(string: sfmlURL) else {
      return
    }
    
    // Get data from the provided SFML url and pass it into the view to render
    let session = URLSession.shared
    session.dataTask(with: url) { (data, response, error) in
      guard let data = data else {
        return
      }
      
      self.storefrontView.load(
        sfml: data,
        headerView: self.headerView,
        footerView: self.footerView,
        titlePreload: { (title, subtitle) -> (Void) in
          self.title = title
      },
        completion: { (error) -> (Void) in
          guard error == nil else {
            print("Error loading storefront: \(error!)")
            return
          }
          
          self.storefrontView.isVisible = true
      })
      }.resume()
  }
  
  private func loadFlyerItems() {
    flyerItems.removeAll()
    
    // Get the flyer item information for the flyer
    // Note: you must add the display types that you support to the API call
    let itemsUrl = "\(ROOT_URL)flyerkit/\(API_VERSION)/publication/\(flyerID)/products?access_token=\(ACCESS_TOKEN)&display_type=1,5,3,25,7,15&postal_code=\(POSTAL_CODE)"
    print("Flyer Items URL: " + itemsUrl)
    guard let itemsNSURL = URL(string: itemsUrl) else { return }
    
    URLSession.shared.dataTask(with: itemsNSURL, completionHandler: {
      data, response, error in
      
      if (response as! HTTPURLResponse).statusCode != 200 {
        return
      }
      
      guard let data = data else { return }
      
      let items =
        try! JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]]
      
      for item in items {
        guard let itemID = item["id"] as? Int else {
          continue
        }

        let sfmlItemID = SFMLItemID(sourceID: "\(itemID)", source: .flyer)
        
        self.flyerItems[sfmlItemID] = item
      }
    }).resume()
  }
  
  // MARK: - Notification Handling
  
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
  
  // MARK: - Navigation
  
  // Opens the flyer item view (display_type = 1)
  private func openFlyerItemView(_ flyerItemId: Int) {
    let flyerItemController = FlyerItemViewController()
    navigationController?.pushViewController(flyerItemController, animated: true)
    flyerItemController.setFlyerItem(flyerItemId)
  }
  
  // Opens the coupon item view (display_type = 25)
  private func openCouponItemView(_ flyerItemId: Int) {
    let couponController = CouponViewController()
    couponController.loadCouponWithFlyerItemId(flyerItemId)
    navigationController?.pushViewController(couponController, animated: true)
  }
  
  // Opens the video item view (display_type = 3)
  private func openVideoItemView(_ flyerItemId: Int) {
    let videoController = VideoViewController()
    videoController.flyerItemId = flyerItemId
    navigationController?.pushViewController(videoController, animated: true)
  }
  
  // Opens the iframe item view (display_type = 15)
  private func openIframeItemView(_ flyerItemId: Int) {
    let iframeController = IframeViewController()
    iframeController.flyerItemId = flyerItemId
    navigationController?.pushViewController(iframeController, animated: true)
  }
  
  // MARK: - Rotation
  
  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    
    let contentOffsetPercentage = storefrontView.contentOffsetPercentage
    
    coordinator.animate(
      alongsideTransition: { (context) in
        self.storefrontView.contentOffsetPercentage = contentOffsetPercentage
    },
      completion: nil)
  }
}

// MARK: - SFMLImageDownloadTaskProvider

// We make StorefrontViewController be an SFMLImageDownloadTaskProvider and
// it will return instances of ImageDownloadTask which conform to SFMLImageDownloadTask.
extension StorefrontViewController: SFMLImageDownloadTaskProvider {
  func newImageDownloadTask() -> SFMLImageDownloadTask {
    return ImageDownloadTask()
  }
}

// MARK: - ImageDownloadTask

// A custom class that conforms to SFMLImageDownloadTask. Here we are using
// SDWebImage to do our image loading.
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

// MARK: - SFMLViewDelegate

extension StorefrontViewController: SFMLViewDelegate {
  func sfmlViewVisibilityChanged(_ view: SFMLView, isVisible: Bool) {
    
  }
  
  func sfmlViewDidZoom(_ view: SFMLView) {
    
  }
  
  func sfmlViewDidScroll(_ view: SFMLView) {
    
  }
  
  func sfmlViewDidScrollToTop(_ view: SFMLView) {
    
  }
  
  func sfmlViewDidEndDecelerating(_ view: SFMLView) {
    
  }
  
  func sfmlViewDidEndScrollingAnimation(_ view: SFMLView) {
    
  }
  
  func sfmlViewDidEndZooming(_ view: SFMLView, atScale scale: CGFloat) {
    
  }
  
  func sfmlViewDidEndDragging(_ view: SFMLView, willDecelerate decelerate: Bool) {
    
  }
  
  func sfmlView(_ view: SFMLView, doubleTappedPoint point: CGPoint, didZoomIn: Bool) {
    
  }
  
  func sfmlView(_ view: SFMLView, didTapItemWithAttributes attributes: SFMLItemAttributes) {
    guard let flyerItem = flyerItems[attributes.itemID] else { return }
    
    // switch based on item display type
    guard let itemDisplayType = flyerItem["item_type"] as? Int else { return }
    
    switch itemDisplayType {
    // video
    case FlyerItemType.video.rawValue:
      guard let flyerItemId = flyerItem["id"] as? Int else { return }
      openVideoItemView(flyerItemId)
    // external link
    case FlyerItemType.link.rawValue:
      let itemUrl = flyerItem["web_url"] as! String
      UIApplication.shared.openURL(URL(string:itemUrl)!)
    // page anchor
    case FlyerItemType.anchor.rawValue:
      guard let anchor = attributes.targetAnchorID else {
        break
      }
      
      view.scrollToAnchor(anchorID: anchor.intValue, animated: true)
    // Iframe
    case FlyerItemType.iframe.rawValue:
      guard let flyerItemId = flyerItem["id"] as? Int else { return }
      openIframeItemView(flyerItemId)
    // coupon
    case FlyerItemType.coupon.rawValue:
      guard let flyerItemId = flyerItem["id"] as? Int else { return }
      openCouponItemView(flyerItemId)
    default:
      guard let flyerItemId = flyerItem["id"] as? Int else { return }
      openFlyerItemView(flyerItemId)
    }
  }
  
  func sfmlView(_ view: SFMLView, didLongPressItemWithAttributes attributes: SFMLItemAttributes) {
    guard let flyerItem = flyerItems[attributes.itemID] else { return }

    let sourcedItemID = SFMLItemID(sourceID: attributes.itemID.sourceID, source: attributes.itemID.source)
    
    // circle item
    if clippings.contains(flyerItem) {
      clippings.remove(flyerItem)
      view.removeClippingAnnotations(itemIDs: [sourcedItemID], animated: true)
    } else {
      clippings.add(flyerItem)
      view.addClippingAnnotations(itemIDs: [sourcedItemID], animated: true)
    }
  }

  func couponAnnotationView(for id: SFMLItemID, in view: SFMLView) -> SFMLAnnotationView? {
    return nil
  }
  
  func clippingAnnotationView(forSFMLView view: SFMLView) -> SFMLAnnotationView? {
    return ClippingAnnotationView()
  }
}

// MARK: - SFMLViewWayfinderDelegate

extension StorefrontViewController: SFMLViewWayfinderDelegate {
  func storefrontSFMLViewDidStartWayfinderScroll(_ storefrontView: StorefrontSFMLView) {
    
  }
  
  func storefrontSFMLViewDidEndWayfinderScroll(_ storefrontView: StorefrontSFMLView) {
    
  }
  
  func storefrontSFMLViewWayfinderWillAppear(_ storefrontView: StorefrontSFMLView) {
    
  }
  
  func storefrontSFMLViewWayfinderDidAppear(_ storefrontView: StorefrontSFMLView,
                                            highlightedCategory category: String?) {
    
  }
  
  func storefrontSFMLView(_ storefrontView: StorefrontSFMLView,
                          didSelectWayfinderCategory category: String,
                          categoryIndex index: Int) {
    
  }
}

// MARK: - ClippingAnnotationView

fileprivate class ClippingAnnotationView: SFMLAnnotationView {
  private let animatedImageView = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  @objc required dynamic init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  override func insertAnnotationView(animated: Bool) {
    animatedImageView.animationDuration = 0.2;
    animatedImageView.animationRepeatCount = 1;
    animatedImageView.animationImages = [#imageLiteral(resourceName: "circle0"),
                                         #imageLiteral(resourceName: "circle1"),
                                         #imageLiteral(resourceName: "circle2"),
                                         #imageLiteral(resourceName: "circle3"),
                                         #imageLiteral(resourceName: "circle4")];
    animatedImageView.image = animatedImageView.animationImages?.last
    animatedImageView.layer.opacity = 0.9;
    animatedImageView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(animatedImageView)
    
    animatedImageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    animatedImageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    animatedImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    animatedImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    
    if animated {
      animatedImageView.startAnimating()
    }
  }
  
  override func removeAnnotationView(animated: Bool) {
    animatedImageView.animationImages = [#imageLiteral(resourceName: "circle4"),
                                         #imageLiteral(resourceName: "circle3"),
                                         #imageLiteral(resourceName: "circle2"),
                                         #imageLiteral(resourceName: "circle1"),
                                         #imageLiteral(resourceName: "circle0")]
    animatedImageView.image = animatedImageView.animationImages?.last;
    
    if animated {
      animatedImageView.startAnimating()
    }
  }
  
  override func handleZoomChange(zoomScale: CGFloat) {
    
  }
}

// MARK: - SFMLViewAnalyticsDelegate

extension StorefrontViewController: SFMLViewAnalyticsDelegate {
  func additionalViewportInsetsForSFMLView(_ view: StorefrontSFMLView) -> UIEdgeInsets {
    print("ANALYTICS: additional viewport insets")
    return .zero
  }

  func sfmlViewDidOpenAnalyticsEvent(_ view: StorefrontSFMLView) {
    print("ANALYTICS: open event")
  }
  
  func sfmlViewEngagedVisitAnalyticsEvent(_ view: StorefrontSFMLView) {
    print("ANALYTICS: EV event")
  }
  
  func sfmlViewItemImpressionsAnalyticsEvent(_ view: StorefrontSFMLView, visibleItemIDs: Set<SFMLItemID>) {
    print("ANALYTICS: item impressions event: \(visibleItemIDs)")
  }

  func sfmlViewItemViewableImpressionsAnalyticsEvent(_ view: StorefrontSFMLView, visibleItemIDs: Set<SFMLItemID>) {
    print("ANALYTICS: item viewable impressions event: \(visibleItemIDs)")
  }

  func sfmlViewWayfinderDidOpenAnalyticsEvent(_ view: StorefrontSFMLView, highlightedCategory: String?) {
    print("ANALYTICS: wayfinder open event: \(highlightedCategory ?? "")")
  }
  
  func sfmlViewDidSelectWayfinderCategoryAnalyticsEvent(_ view: StorefrontSFMLView, selectedCategory: String) {
    print("ANALYTICS: wayfinder did select event: \(selectedCategory)")
  }
}

// MARK: - SFMLAccessibilityElementDelegate

extension StorefrontViewController: SFMLAccessibilityElementDelegate {
  func sfmlAccessibilityHint(element: SFMLAccessibilityElement) -> String? {
    guard let flyerAccessibilityElement = element as? SFMLFlyerViewAccessibilityElement,
      let flyerItem = flyerItems[flyerAccessibilityElement.itemID] else {
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

  func sfmlAccessibilityLabelPrefix(element: SFMLAccessibilityElement) -> String? {
    return nil
  }
}
