//
//  AppDelegate.h
//  SkronkSpike
//
//  Created by John Sheets on 10/2/11.
//  Copyright (c) 2011 JAMF Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    NSStatusItem *_statusItem;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenu *statusMenu;
@property (nonatomic, copy) NSArray *trackArray;

@end
