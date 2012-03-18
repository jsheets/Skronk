//
//  RoundedWindow.m
//  SkronkFM
//
//  Created by John Sheets on 3/2/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import "RoundedWindow.h"

@implementation RoundedWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    if ((self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag]))
    {
        [self setMovableByWindowBackground:YES];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setOpaque:NO];
        [self setHasShadow:YES];
    }

    return self;
}

- (BOOL)canBecomeMainWindow
{
    return YES;
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

@end
