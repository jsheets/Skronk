//
//  AppDelegate.m
//  Skronk
//
//  Created by John Sheets on 2/3/12.
//  Copyright (c) 2012 JAMF Software. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize label = _label;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.label.stringValue = @"Artist - Album - Track";
    [self.window setMovableByWindowBackground:YES];
}

@end
