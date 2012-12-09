//
//  AppDelegate.h
//  InfiniGAG Downloader
//
//  Created by Phil Plückthun on 09.12.12.
//  Copyright (c) 2012 Phil Plückthun. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "AFNetworking.h"
#import "AFImageRequestOperation.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSAlertDelegate> {
    NSString *next;
    BOOL internet;
    NSAlert *alert;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, strong) IBOutlet NSImageView *memepreview;
@property (nonatomic, strong) IBOutlet NSButton *take;
@property (nonatomic, strong) IBOutlet NSButton *drop;
@property (nonatomic, strong) IBOutlet NSTextField *title;

@property (nonatomic, strong) NSMutableArray *memesData;
@property (nonatomic, strong) NSDictionary *currentMeme;
@property (nonatomic, strong) NSDictionary *downloadMeme;

- (void)nextPic;
- (void)updateImages;
- (void)downloadImageInBackground:(NSDictionary *)args;
- (bool)hasInternet;

- (IBAction)takeButton:(id)sender;
- (IBAction)dropButton:(id)sender;

@end
