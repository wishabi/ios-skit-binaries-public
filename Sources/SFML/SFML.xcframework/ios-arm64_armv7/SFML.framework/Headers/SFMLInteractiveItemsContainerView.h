
//  Copyright © 2018 Flipp. All rights reserved.

#import <Foundation/Foundation.h>

/**
 Objects conforming to this protocol should recalculate any item rects or
 accessibility elements for the given container.
 */
@protocol SFMLInteractiveItemsContainerViewDelegate <NSObject>

- (void)containerViewDidLayoutSubviews:(nullable NSString *)containerID;

@end

/**
 Views conforming to this protocol contain subviews representing "interactive items".
 E.g. Flyer views, item atoms, views/controls that should be accessible (such as the
 collapse/expand button in a collapsible layout view), etc.
 
 On layoutSubviews, these views should tell its `containerViewDelegate` so item rects or
 accessibility element rects can be re-computed.
 */
@protocol SFMLInteractiveItemsContainerView <NSObject>

/// The container ID for this view.
/// This ID is assigned automatically by the layout manager.
@property (nullable, nonatomic, strong) NSString *containerID;

/// The delegate for this container view who should be notified on
/// layout changes.
@property (nullable, nonatomic, weak) id<SFMLInteractiveItemsContainerViewDelegate> containerViewDelegate;

@end
