//
//  AppDelegate.h
//  SkronkMini
//
//  Created by John Sheets on 2/4/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PreferencesController;
@class RoundedView;
@class NowPlaying;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet RoundedView *roundedView;
@property (weak) IBOutlet NSMenu *statusMenu;
@property (strong) NSStatusItem *statusItem;
@property (weak) IBOutlet NSMenuItem *showHideMenuItem;
@property (weak) IBOutlet NSMenuItem *showHideStatusbarItem;
@property (weak) IBOutlet NSTextField *label;
@property (weak) IBOutlet NSTextField *icon;
@property (weak) IBOutlet NSImageView *art;
@property (weak) IBOutlet NSImageView *serviceIcon;

@property (assign) CGFloat backgroundWidth;
@property (strong) PreferencesController *preferencesController;
@property (strong) NSTimer *timer;
@property (strong) NowPlaying *currentlyPlaying;

@property (assign) BOOL isSleeping;

- (IBAction)preferencesClicked:(id)sender;
- (IBAction)openLastFmClicked:(id)sender;
- (IBAction)showHideClicked:(id)sender;

- (void)updateHotkeys;

@end
