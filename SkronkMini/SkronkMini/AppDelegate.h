//
//  AppDelegate.h
//  SkronkMini
//
//  Created by John Sheets on 2/4/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *label;
@property (assign) IBOutlet NSTextField *icon;
@property (assign) IBOutlet NSImageView *art;
@property (assign) IBOutlet NSProgressIndicator *progress;
@property (assign) IBOutlet NSTimer *timer;

@property (retain) NSString *username;
@property (assign) BOOL hideWhenNotPlaying;

@end
