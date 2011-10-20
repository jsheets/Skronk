//
//  TrackViewController.m
//  SkronkSpike
//
//  Created by John Sheets on 10/20/11.
//  Copyright (c) 2011 JAMF Software. All rights reserved.
//

#import "TrackViewController.h"

@implementation TrackViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        // Initialization code here.
    }
    
    return self;
}

- (id)init
{
    if ((self = [self initWithNibName:@"TrackViewController" bundle:nil]))
    {
        // Initializations
    }
    
    return self;
}

- (BOOL)acceptsFirstResponder
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

@end
