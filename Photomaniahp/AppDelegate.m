//
//  AppDelegate.m
//  Photomaniahp
//
//  Created by hp ios on 12/20/17.
//  Copyright © 2017 hp ios. All rights reserved.
//

#import "AppDelegate.h"
#import "ServerAPI.h"
#import "User+Data.h"
#import "AppDelegate+MOC.h"
#import "PhotoDatabaseAvailability.h"

@interface AppDelegate () <NSURLSessionDownloadDelegate>
@property (copy, nonatomic) void (^flickrDownloadBackgroundURLSessionCompletionHandler)();
@property (strong, nonatomic) NSURLSession *userDownloadSession;
@property (strong, nonatomic) NSTimer *flickrForegroundFetchTimer;
@property (strong, nonatomic) NSManagedObjectContext *userDatabaseContext;
@end
#define USER_FETCH @"User Just Uploaded Fetch"

// how often (in seconds) we fetch new photos if we are in the foreground
#define FOREGROUND_FLICKR_FETCH_INTERVAL (20*60)

// how long we'll wait for a Flickr fetch to return when we're in the background
#define BACKGROUND_FLICKR_FETCH_TIMEOUT (10)

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.userDatabaseContext = [self createMainQueueManagedObjectContext];
    [self startUserFetch];
    return YES;
}

-(void)setUserDatabaseContext:(NSManagedObjectContext *)userDatabaseContext
{
    _userDatabaseContext=userDatabaseContext;
    NSDictionary *userInfo = self.userDatabaseContext ? @{ PhotoDatabaseAvailabilityContext : self.userDatabaseContext } : nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:PhotoDatabaseAvailabilityNotification
                                                        object:self
                                                      userInfo:userInfo];

    
}


- (void)startUserFetch
{
    // getTasksWithCompletionHandler: is ASYNCHRONOUS
    // but that's okay because we're not expecting startFlickrFetch to do anything synchronously anyway
    [self.userDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        // let's see if we're already working on a fetch ...
        if (![downloadTasks count]) {
            // ... not working on a fetch, let's start one up
            NSURLSessionDownloadTask *task = [self.userDownloadSession
                                              downloadTaskWithURL:[ServerAPI URLForServerData]];
            task.taskDescription = USER_FETCH;
            [task resume];
        } else {
            // ... we are working on a fetch (let's make sure it (they) is (are) running while we're here)
            for (NSURLSessionDownloadTask *task in downloadTasks) [task resume];
        }
    }];
}

- (NSURLSession *)userDownloadSession // the NSURLSession we will use to fetch Flickr data in the background
{
    if (!_userDownloadSession) {
        static dispatch_once_t onceToken; // dispatch_once ensures that the block will only ever get executed once per application launch
        dispatch_once(&onceToken, ^{
            // notice the configuration here is "backgroundSessionConfiguration:"
            // that means that we will (eventually) get the results even if we are not the foreground application
            // even if our application crashed, it would get relaunched (eventually) to handle this URL's results!
         
            NSURLSessionConfiguration *urlSessionConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:USER_FETCH];
            _userDownloadSession = [NSURLSession sessionWithConfiguration:urlSessionConfig
                                                                   delegate:self    // we MUST have a delegate for background configurations
                                                              delegateQueue:nil];   // nil means "a random, non-main-queue queue"
        });
    }
    return _userDownloadSession;
}
- (NSArray *)flickrPhotosAtURL:(NSURL *)url
{
    NSArray *flickrPropertyList;
    
    NSData *userJSONData = [NSData dataWithContentsOfURL:url];  // will block if url is not local!
    if (userJSONData)
    {
        flickrPropertyList = [NSJSONSerialization JSONObjectWithData: userJSONData
                                                         options:NSJSONReadingMutableContainers
                                                          error:NULL];
    }
     return flickrPropertyList ;

 }


#pragma mark - NSURLSessionDownloadDelegate
    
 - (void)loadFlickrPhotosFromLocalURL:(NSURL *)localFile
                         intoContext:(NSManagedObjectContext *)context
                 andThenExecuteBlock:(void(^)())whenDone
{
    if (context)
    {
        NSArray *photos = [self flickrPhotosAtURL:localFile];
        [context performBlock:^{
            [User loadInfoFromUserArray:photos intoManagedObjectContext:context];
            [context save:NULL]; // NOT NECESSARY if this is a UIManagedDocument's context
            if (whenDone) whenDone();
            
        }];
    }
    else
    {
        if (whenDone) whenDone();
    }
}

    // required by the protocol
    - (void)URLSession:(NSURLSession *)session
downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)localFile
    {
        // we shouldn't assume we're the only downloading going on ...
        if ([downloadTask.taskDescription isEqualToString:USER_FETCH]) {
            // ... but if this is the Flickr fetching, then process the returned data
            [self loadFlickrPhotosFromLocalURL:localFile
                                   intoContext:self.userDatabaseContext
                           andThenExecuteBlock:^{
                             
                               [self flickrDownloadTasksMightBeComplete];
                               
                               
                               
                           }
             ];
        }
    }
    
    
// required by the protocol
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    // we don't support resuming an interrupted download task
}

// required by the protocol
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    // we don't report the progress of a download in our UI, but this is a cool method to do that with
}


- (void)flickrDownloadTasksMightBeComplete
{
    if (self.flickrDownloadBackgroundURLSessionCompletionHandler) {
        [self.userDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            // we're doing this check for other downloads just to be theoretically "correct"
            //  but we don't actually need it (since we only ever fire off one download task at a time)
            // in addition, note that getTasksWithCompletionHandler: is ASYNCHRONOUS
            //  so we must check again when the block executes if the handler is still not nil
            //  (another thread might have sent it already in a multiple-tasks-at-once implementation)
            if (![downloadTasks count]) {  // any more Flickr downloads left?
                // nope, then invoke flickrDownloadBackgroundURLSessionCompletionHandler (if it's still not nil)
                void (^completionHandler)() = self.flickrDownloadBackgroundURLSessionCompletionHandler;
                self.flickrDownloadBackgroundURLSessionCompletionHandler = nil;
                if (completionHandler) {
                    completionHandler();
                }
            } // else other downloads going, so let them call this method when they finish
        }];
    }
}


  
    @end

