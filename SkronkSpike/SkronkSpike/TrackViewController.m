//
//  TrackViewController.m
//  SkronkSpike
//
//  Created by John Sheets on 10/20/11.
//  Copyright (c) 2011 JAMF Software. All rights reserved.
//

#import "TrackViewController.h"
#import "Track.h"

@implementation TrackViewController

@synthesize trackArray, arrayController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        // Initialization code here.
        self.trackArray = [NSMutableArray array];
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

- (void)awakeFromNib
{
    NSURL *tracksURL = [[NSBundle mainBundle] URLForResource:@"sample-tracks" withExtension:@"plist"];
    NSLog(@"Tracks URL: %@", tracksURL);
    
    if (tracksURL)
    {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:tracksURL];
        NSArray *tracks = [dict valueForKey:@"tracks"];
        NSLog(@"Tracks: %@", tracks);
        
        for (NSDictionary *trackDict in tracks)
        {
            Track *track = [[[Track alloc] initWithDictionary:trackDict] autorelease];
            [self.trackArray addObject:track];
        }
    }
    
    self.arrayController.selectionIndex = 0;
    NSLog(@"Array Controller selected track: %@", [self.arrayController.selection valueForKey:@"track"]);
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
