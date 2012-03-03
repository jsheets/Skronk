//
//  RoundedView.m
//  SkronkMini
//
//  Created by John Sheets on 3/2/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import "RoundedView.h"

@implementation RoundedView

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

    [[NSColor darkGrayColor] set];
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:[self bounds] xRadius:10 yRadius:10];
    [path fill];

    [NSGraphicsContext restoreGraphicsState];
}

@end
