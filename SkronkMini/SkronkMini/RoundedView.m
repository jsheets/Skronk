//
//  RoundedView.m
//  SkronkMini
//
//  Created by John Sheets on 3/2/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import "RoundedView.h"

@implementation RoundedView

@synthesize backgroundImage = _backgroundImage;

- (id)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor windowBackgroundColor] set];

    [NSGraphicsContext saveGraphicsState];

    // Clip view to rounded corners.
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:10 yRadius:10];
    [path addClip];
    path.lineWidth = 2.0;

    // Concrete background.
    [self.backgroundImage compositeToPoint:NSZeroPoint fromRect:self.bounds operation:NSCompositeSourceOver];

    NSRect insetRect = NSInsetRect(self.bounds, 4, 4);
    NSBezierPath *insetPath = [NSBezierPath bezierPathWithRoundedRect:insetRect xRadius:8 yRadius:8];

    // Slightly darker text background.
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.15] set];
    [insetPath fill];

    // Border around text background.
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.4] set];
    [insetPath stroke];

    // Outer border.
    [path stroke];

    [NSGraphicsContext restoreGraphicsState];
}

@end
