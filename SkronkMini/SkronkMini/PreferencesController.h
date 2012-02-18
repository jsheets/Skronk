//
//  PreferencesController.h
//  SkronkMini
//
//  Created by John Sheets on 2/14/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSWindowController <NSToolbarDelegate>

@property (assign) IBOutlet NSToolbar *bar;
@property (assign) IBOutlet NSView *generalPreferenceView;
@property (assign) IBOutlet NSView *lastFmPreferenceView;

@property (assign) NSView *currentView;

- (IBAction)generalTabClicked:(id)sender;
- (IBAction)lastFmTabClicked:(id)sender;

@end
