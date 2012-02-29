//
//  AppDelegate.h
//  SkronkMini
//
//  Created by John Sheets on 2/4/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PreferencesController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenu *statusMenu;
@property (retain) NSStatusItem *statusItem;
@property (weak) IBOutlet NSMenuItem *showHideMenuItem;
@property (weak) IBOutlet NSMenuItem *showHideStatusbarItem;
@property (retain) PreferencesController *preferencesController;

@property (assign) IBOutlet NSTextField *label;
@property (assign) IBOutlet NSTextField *icon;
@property (assign) IBOutlet NSImageView *art;
@property (assign) IBOutlet NSProgressIndicator *progress;
@property (assign) IBOutlet NSTimer *timer;

- (IBAction)preferencesClicked:(id)sender;
- (void)updateHotkeys;
- (IBAction)showHideClicked:(id)sender;

@end
