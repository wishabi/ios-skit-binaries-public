//
//  AnnotationViewExample.m
//  StorefrontsKitSample
//
//  Created by Yurii Balashkevych on 25.09.2020.
//  Copyright © 2020 Flipp. All rights reserved.
//

#import "AnnotationViewExample.h"
@import SFML;

@implementation AnnotationViewExample

- (void)testMethod {
    SFMLAnnotationView *view = [[SFMLAnnotationView alloc] init];
    [view insertAnnotationViewWithAnimated: YES];
    [view removeAnnotationViewWithAnimated: NO];
    [view handleZoomChangeWithZoomScale: 0];
}

@end
