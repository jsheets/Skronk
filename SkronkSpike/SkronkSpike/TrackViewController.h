//
//  TrackViewController.h
//  SkronkSpike
//
//  Created by John Sheets on 10/20/11.
//  Copyright (c) 2011 JAMF Software. All rights reserved.
//

#define API_KEY @"3a36e88356d8d90aee7a012c6abccae1"
#define API_SECRET @"090d30da3a6172bbbecc7ad2e31a8d6e"

#import <Cocoa/Cocoa.h>
#import "SNRLastFMEngine.h"

@interface TrackViewController : NSViewController

@property (nonatomic, copy) NSString *user;
@property (nonatomic, retain) SNRLastFMEngine *lastFm;
@property (nonatomic, retain) NSMutableArray *trackArray;
@property (assign) IBOutlet NSArrayController *arrayController;
@property (assign) IBOutlet NSTextField *authLabel;

- (IBAction)authenticate:(id)sender;
- (IBAction)update:(id)sender;

@end
