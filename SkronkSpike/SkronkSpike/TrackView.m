//
//  TrackView.m
//  SkronkSpike
//
//  Created by John Sheets on 10/20/11.
//  Copyright (c) 2011 FourFringe. All rights reserved.
//

#import "TrackView.h"

@implementation TrackView

- (id)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        // Initialization code here.
    }
    
    return self;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)canBecomeKeyView
{
    return YES;
}

- (void)keyDown:(NSEvent *)event
{
    NSLog(@"A key has been pressed");
    switch([event keyCode])
    {
        case 126:       // up arrow
        case 125:       // down arrow
        case 124:       // right arrow
        case 123:       // left arrow
            NSLog(@"Arrow key pressed!");
            break;
        default:
            NSLog(@"Key pressed: %@", event);
            break;
    }
}

//- (void)drawRect:(NSRect)dirtyRect
//{
//    // Drawing code here.
//}

@end
