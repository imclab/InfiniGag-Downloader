//
//  AppDelegate.m
//  InfiniGAG Downloader
//
//  Created by Phil Plückthun on 09.12.12.
//  Copyright (c) 2012 Phil Plückthun. All rights reserved.
//

#import "AppDelegate.h"

#define BASEAPIURL @"http://infinigag.eu01.aws.af.cm/"

@interface NSImage(saveAsJpegWithName)
- (void) saveAsJpegWithName:(NSString*) fileName;
@end

@implementation NSImage(saveAsJpegWithName)

- (void) saveAsJpegWithName:(NSString*) fileName
{
    NSData *imageData = [self TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
    [imageData writeToFile:fileName atomically:NO];
}

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [_drop setEnabled:false];
    [_take setEnabled:false];
    
    next = @"";
    
    if (![self hasInternet]) {
        [_title setStringValue:@"No Internet Connection!"];
    }
    
    NSString *baseURL = (BASEAPIURL @"?json=get_post&?section=hot");
    NSURL *url = [NSURL URLWithString:baseURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    _memesData = [[NSMutableArray alloc] init];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        [_memesData addObjectsFromArray:[JSON objectForKey:@"images"]];
        next = [[JSON objectForKey:@"attributes"] objectForKey:@"next"];
        
        [self nextPic];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [self updateImages];
    }];
    [operation start];
}

- (void)nextPic {
    if (_memesData.count > 0) {
        [_title setStringValue:[_memesData[0] objectForKey:@"title"]];
        [_memepreview setImage:[[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:[[_memesData[0] objectForKey:@"image"] objectForKey:@"thumb"]]]];
        _currentMeme = _memesData[0];
        NSLog(@"Current: %@", [_currentMeme objectForKey:@"id"]);
        NSLog(@"Should: %@", [_memesData[0] objectForKey:@"id"]);
        [_memesData removeObjectAtIndex:0];
        [_drop setEnabled:true];
        [_take setEnabled:true];
    } else {
        [self updateImages];
    }
}

- (void)updateImages {
    NSString *baseURLOne = (BASEAPIURL @"?json=get_post&?section=hot&page=");
    NSString *baseURL = [NSString stringWithFormat:@"%@%@", baseURLOne, next];
    NSURL *url = [NSURL URLWithString:baseURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    _memesData = [[NSMutableArray alloc] init];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        [_memesData addObjectsFromArray:[JSON objectForKey:@"images"]];
        next = [[JSON objectForKey:@"attributes"] objectForKey:@"next"];
        [self nextPic];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (![self hasInternet]) {
            [_title setStringValue:@"No Internet Connection!"];
        }
        [self nextPic];
    }];
    [operation start];
}

- (IBAction)takeButton:(id)sender {
    [_drop setEnabled:false];
    [_take setEnabled:false];
    [self downloadImageInBackground: _currentMeme];
    [self nextPic];
}

- (IBAction)dropButton:(id)sender {
    [_drop setEnabled:false];
    [_take setEnabled:false];
    [self nextPic];
}

- (void)downloadImageInBackground:(NSDictionary *)args{
    NSString *temp = [args objectForKey:@"title"];
    NSString *guideName;
    if ([temp hasSuffix:@"."]) {
        guideName = [NSString stringWithFormat:@"%@%@", [args objectForKey:@"title"], @"jpg"];
    } else {
        guideName = [NSString stringWithFormat:@"%@%@", [args objectForKey:@"title"], @".jpg"];
    }
    NSString *photourl = [NSString stringWithFormat: @"%@", [[args objectForKey:@"image"] objectForKey:@"big"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:photourl]];
    AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSImage *image) {
        NSString *documentsDirectory = nil;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsDirectory = [paths objectAtIndex:0];
        NSString *pathString = [NSString stringWithFormat:@"%@/%@",documentsDirectory, guideName];
        [image saveAsJpegWithName:pathString];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert setMessageText:[NSString stringWithFormat:@"Couldn't download image %@!", [args objectForKey:@"id"]]];
        [alert setInformativeText:@"Do you want to retry?"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:[[NSApplication sharedApplication] keyWindow] modalDelegate:self didEndSelector:@selector(DiscardAlertDidEnd:returnCode: contextInfo:) contextInfo:nil];
        _downloadMeme = args;
    }];
    
    [operation start];
}

- (void)DiscardAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == 1000) {
        [self downloadImageInBackground:_downloadMeme];
    }
}

- (bool)hasInternet {
    NSURL *url = [[NSURL alloc] initWithString:@"http://www.google.com"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5.0];
    BOOL connectedToInternet = NO;
    if ([NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil]) {
        connectedToInternet = YES;
    }
    internet = connectedToInternet;
    return connectedToInternet;
}

@end
