//
//  TrackViewController.h
//  SkronkSpike
//
//  Created by John Sheets on 10/20/11.
//  Copyright (c) 2011 JAMF Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TrackViewController : NSViewController

@property (nonatomic, retain) NSMutableArray *trackArray;
@property (assign) IBOutlet NSArrayController *arrayController;

@end
