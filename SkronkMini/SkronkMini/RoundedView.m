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
    // Drawing code here.
    [[NSColor windowBackgroundColor] set];

    [NSGraphicsContext saveGraphicsState];

    // Clip view to rounded corners.
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:10 yRadius:10];
    path.lineWidth = 3.0;
    [path addClip];

    // Concrete background.
    [self.backgroundImage compositeToPoint:NSZeroPoint fromRect:self.bounds operation:NSCompositeSourceOver];

    // Gray border.
    [[NSColor grayColor] set];
    [path stroke];

    [NSGraphicsContext restoreGraphicsState];
}

@end
