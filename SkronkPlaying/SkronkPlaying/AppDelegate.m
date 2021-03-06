//
//  AppDelegate.m
//  SkronkPlaying
//
//  Created by John Sheets on 10/2/11.
//  Copyright (c) 2011 JAMF Software. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize statusMenu = _statusMenu;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Allow dragging window from anywhere.
    [self.window setMovableByWindowBackground:YES];
    
    // Staple window to desktop layer.
    [self.window setLevel:kCGDesktopIconWindowLevel];
}

- (void)awakeFromNib
{
    _statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    _statusItem.menu = self.statusMenu;
    _statusItem.title = @"Skronk";
    _statusItem.highlightMode = YES;
    //    _statusItem.image = nil;
}

@end
