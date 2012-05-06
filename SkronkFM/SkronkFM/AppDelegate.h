//
//  AppDelegate.h
//  SkronkFM
//
//  Created by John Sheets on 2/4/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iTunes.h"
#import "Spotify.h"
#import "Mog.h"
#import "Rdio.h"
#import "Last.fm.h"

@class PreferencesController;
@class RoundedView;
@class NowPlaying;

@interface AppDelegate : NSObject <NSApplicationDelegate, SBApplicationDelegate>

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
@property (strong) NSURL *currentAlbumArtURL;
@property (strong) NSImage *currentAlbumArt;
@property (strong) NSImage *missingArt;

@property (assign) BOOL isSleeping;

- (IBAction)preferencesClicked:(id)sender;
- (IBAction)openLastFmClicked:(id)sender;
- (IBAction)openUserClicked:(id)sender;
- (IBAction)showHideClicked:(id)sender;
- (IBAction)showHelpClicked:(id)sender;

- (void)updateHotkeys;
- (BOOL)windowIsVisible;

@end
