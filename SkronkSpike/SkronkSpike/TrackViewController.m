//
//  TrackViewController.m
//  SkronkSpike
//
//  Created by John Sheets on 10/20/11.
//  Copyright (c) 2011 JAMF Software. All rights reserved.
//

#import "TrackViewController.h"
#import "Track.h"

static NSString* const kCustomURLScheme = @"x-com-fourfringe-skronknow";

@implementation TrackViewController
@synthesize authLabel;

@synthesize trackArray, arrayController, lastFm, username;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        // Initialization code here.
        self.trackArray = [NSMutableArray array];
    }
    
    return self;
}

- (id)init
{
    if ((self = [self initWithNibName:@"TrackViewController" bundle:nil]))
    {
        // Initializations
    }
    
    return self;
}

- (void)configureLastFm
{
    self.username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    self.lastFm = [SNRLastFMEngine lastFMEngineWithUsername:self.username];
    
    NSString *authString = self.username ? [NSString stringWithFormat:@"Authenticated as: %@", self.username] : @"Not authenticated";
    self.authLabel.stringValue = authString;
}

- (void)registerCustomURLSchemeHandler
{
    // Register for Apple Events
    NSAppleEventManager *em = [NSAppleEventManager sharedAppleEventManager];
    [em setEventHandler:self andSelector:@selector(getURL:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    // Set app as the default handler
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    LSSetDefaultHandlerForURLScheme((CFStringRef)kCustomURLScheme, (CFStringRef)bundleID);
}


- (void)awakeFromNib
{
    [self registerCustomURLSchemeHandler];
    [self configureLastFm];
    
    NSURL *tracksURL = [[NSBundle mainBundle] URLForResource:@"sample-tracks" withExtension:@"plist"];
    NSLog(@"Tracks URL: %@", tracksURL);
    
    if (tracksURL)
    {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:tracksURL];
        NSArray *tracks = [dict valueForKey:@"tracks"];
        NSLog(@"Tracks: %@", tracks);
        
        for (NSDictionary *trackDict in tracks)
        {
            Track *track = [[[Track alloc] initWithDictionary:trackDict] autorelease];
            NSLog(@"Adding track: %@", [track valueForKey:@"track"]);
            [self.arrayController addObject:track];
        }
    }
    
    self.arrayController.selectionIndex = 0;
    NSLog(@"Array Controller selected track: %@", [self.arrayController.selection valueForKey:@"track"]);
}

- (IBAction)authenticate:(id)sender
{
    NSLog(@"Authenticating with last.fm\nAPI_KEY = %@\nAPI_SECRET = %@", API_KEY, API_SECRET);
    NSString *callback = [NSString stringWithFormat:@"%@://auth/", kCustomURLScheme];
    NSURL *callbackURL = [NSURL URLWithString:callback];
    [[NSWorkspace sharedWorkspace] openURL:[SNRLastFMEngine webAuthenticationURLWithCallbackURL:callbackURL]];
}

- (void)getURL:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSLog(@"Returned from last.fm authentication");
    
    NSString *prefix = [NSString stringWithFormat:@"%@://auth/?token=", kCustomURLScheme];
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSString *token = [urlString substringFromIndex:[prefix length]];
    [self.lastFm retrieveAndStoreSessionKeyWithToken:token completionHandler:^(NSString *user, NSError *error)
     {
         NSLog(@"Storing last.fm session for user: %@", user);
         self.username = user;
         if (error)
         { 
             NSLog(@"%@ %@", error, [error userInfo]);
         }
         
         [[NSUserDefaults standardUserDefaults] setObject:self.username forKey:@"username"];
         self.authLabel.stringValue = [NSString stringWithFormat:@"Authenticated as: %@", self.username];
     }];
}

- (IBAction)update:(id)sender
{
    if ([self.lastFm isAuthenticated])
    {
        NSLog(@"Updating to current last.fm track for user: %@", self.username);
        NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:self.username, @"user", nil];
        [self.lastFm callMethod:@"user.getRecentTracks" withParameters:parameters requireAuth:NO HTTPMethod:SNRHTTPMethodGET completionBlock:^(NSDictionary *response, NSError *error)
        {
            NSArray *tracks = [response valueForKeyPath:@"recenttracks.track"];
            
            NSDictionary *currentTrackDict = [tracks objectAtIndex:0];
            NSLog(@"Most Recent Track: %@", currentTrackDict);
            Track *currentTrack = [[[Track alloc] initWithLastFm:currentTrackDict] autorelease];
            
            [self.arrayController insertObject:currentTrack atArrangedObjectIndex:0];
        }];
    }
    else
    {
        NSLog(@"last.fm not yet authorized");
    }
}

@end
