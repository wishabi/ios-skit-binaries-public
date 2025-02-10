// Copyright 2013 Wishabi, Inc. All rights reserved.
#import <UIKit/UIKit.h>

@protocol SFMLImageDownloadTaskProvider;
@protocol SFMLInteractiveItemsContainerView; 
@protocol SFMLInteractiveItemsContainerViewDelegate;


/**
 A view that displays a single slice from a flyer.
 */
@interface SFMLFlyerView : UIView

- (id)initWithScrollView:(UIScrollView *)scrollView
imageDownloadTaskProvider:(id<SFMLImageDownloadTaskProvider>)imageDownloadTaskProvider;
- (void)setFlyerWithResolutions:(NSArray *)resolutions
                    contentSize:(CGSize)contentSize
                   contentSlice:(CGRect)contentSlice
                           path:(NSString *)path;

// A reference to the scrollview to get zoom and bounds information from.
@property (nonatomic, weak, readonly) UIScrollView *scrollView;

// Scaling factors to display the content when the scroll view is at 1.0x zoom.
@property (nonatomic, assign) CGFloat horizontalScalingFactor;
@property (nonatomic, assign) CGFloat verticalScalingFactor;

// The slice rect of the flyer that this view is displaying.
@property (nonatomic, readonly) CGRect contentSlice;

// SFMLInteractiveItemsContainerView
@property (nonatomic, strong) NSString *containerID;
@property (nonatomic, weak) id<SFMLInteractiveItemsContainerViewDelegate> containerViewDelegate;

// SFMLImageLoading
@property (nonatomic, weak) id<SFMLImageDownloadTaskProvider> imageDownloadTaskProvider;

/**
 Tells the internal layers to do a tile render update.
 */
- (void)layout;

/**
 Pass-through method that sets zooming properties on internal layers.
 */
- (void)setZooming:(BOOL)zooming;

@end

@protocol SFMLTiledLayerDelegate;

@interface SFMLTiledLayer : CALayer
@property (nonatomic,assign) BOOL zooming;
@property (nonatomic,assign) BOOL cullByScreenBounds;
@property (nonatomic,strong) NSArray *imageHosts;
@property (nonatomic,assign) CGSize contentSize;
@property (nonatomic,assign) CGRect contentSlice;
@property (nonatomic,strong) NSArray *resolutions;
@property (nonatomic,weak) id<SFMLTiledLayerDelegate> tiledLayerDelegate;
@property (nonatomic,strong) NSString *basePath;

- (void)resetVisibleRows;

@end

@protocol SFMLImageDownloadTaskProvider;
@protocol SFMLImageDownloadTask;

@protocol SFMLTiledLayerDelegate <NSObject>
- (CGRect)visibleBoundsForTiledLayer:(SFMLTiledLayer *)tiledLayer;
- (CGRect)fetchBoundsForTiledLayer:(SFMLTiledLayer *)tiledLayer;
- (CGFloat)tilingZoomScaleForTiledLayer:(SFMLTiledLayer *)tiledLayer;
- (CGFloat)resolutionZoomScaleForTiledLayer:(SFMLTiledLayer *)tiledLayer;
- (CGFloat)horizontalScalingFactorForTiledLayer:(SFMLTiledLayer *)tiledLayer;
- (CGFloat)verticalScalingFactorForTiledLayer:(SFMLTiledLayer *)tiledLayer;
- (CALayer *)windowLayer;
- (id<SFMLImageDownloadTask>)downloadTaskForTiledLayer:(SFMLTiledLayer *)tiledLayer;
@end

/*
 * A Core Animation layer for a single tile that is downloaded and decoded
 * asynchronously.
 */
@interface SFMLTileLayer : CALayer

@property (nonatomic,strong) CATextLayer *debugLabel;
@property (nonatomic,assign) NSUInteger row;
@property (nonatomic,assign) NSUInteger col;
@property (nonatomic,strong) NSString *ID;
@property (nonatomic,assign) size_t resolutionIndex;
@property (nonatomic,strong) id<SFMLImageDownloadTask> imageFetch;

- (void)clearImage;
- (void)setImageWithURL:(NSURL *)url
           downloadTask:(id<SFMLImageDownloadTask>)task;
@end

@interface SFMLLayerCache : NSObject
+ (instancetype)sharedCache;

- (void)addLayer:(CALayer *)layer;
- (CALayer *)removeLayer;
@end
