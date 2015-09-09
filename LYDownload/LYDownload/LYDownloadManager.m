//
//  LYDownloadManager.m
//
//  Created by LY on 15/3/6.
//  Copyright (c) 2015年 刘 洋. All rights reserved.
//

#import "LYDownloadManager.h"
#import <CommonCrypto/CommonDigest.h>
#import "LYDownloader.h"
@interface LYDownloadManager()<LYDownloaderDelegate>  {
    
    NSString *_fileFloderPath;
    NSString *_cacheFloderPath;
    
    NSMutableArray *_downloaders;
    NSMutableDictionary *_downloaderForURL;
    NSMutableArray *_downloadDelegates;
    NSMutableArray *_downloadURLs;
}
- (NSString *)filePathForURL:(NSURL *)url;
- (NSString *)cachePathForURL:(NSURL *)url;
@end

@implementation LYDownloadManager

#pragma mark NSObject
- (id)init
{
    if ((self = [super init]))
    {
        _downloaders = [[NSMutableArray alloc] init];
        _downloaderForURL = [[NSMutableDictionary alloc] init];
        _downloadDelegates =[[NSMutableArray alloc] init];
        _downloadURLs = [[NSMutableArray alloc] init];
        
        NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _fileFloderPath = [[[cachePaths objectAtIndex:0] stringByAppendingPathComponent:@"LYDownloadCache"] copy];
        [self creatFloderAtPath:_fileFloderPath];
        
        NSArray *tempPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _cacheFloderPath = [[[tempPaths objectAtIndex:0] stringByAppendingPathComponent:@"LYDownloadTemp"] copy];
        [self creatFloderAtPath:_cacheFloderPath];
        
    }
    return self;
}

- (void)dealloc
{
#if !__has_feature(objc_arc)
    [_downloaders release];
    [_downloaderForURL release];
    [_downloadDelegates release];
    [_downloadURLs release];
    
    [_fileFloderPath release];
    [_cacheFloderPath release];
    
    [super dealloc];
#endif
    
}

#pragma mark LYDownloadManager(class methods)

+(LYDownloadManager *)sharedManager {
    static LYDownloadManager *_shareManager = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _shareManager = [[LYDownloadManager alloc] init];
    });
    return _shareManager;
}
#pragma mark LYDownloadManager(Privite)
- (BOOL)creatFloderAtPath:(NSString *)floderPath {
    BOOL success = NO;
    BOOL isDir = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:floderPath isDirectory:&isDir]) {
        if (!isDir) {
            NSError *error = nil;
           success = [[NSFileManager defaultManager] createDirectoryAtPath:floderPath withIntermediateDirectories:YES attributes:nil error:&error];
        } else {
            success = YES;
        }
    } else {
        NSError *error = nil;
       success = [[NSFileManager defaultManager] createDirectoryAtPath:floderPath withIntermediateDirectories:YES attributes:nil error:&error];
    }
    return success;
}

- (NSString *)fileNameForKey:(NSString *)key
{
    const char *str = [key UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return filename;
}
- (NSString *)filePathForURL:(NSURL *)url {
    if (!url) {
        return nil;
    }
    return [_fileFloderPath stringByAppendingPathComponent:[self fileNameForKey:[url absoluteString]]];
}
- (NSString *)cachePathForURL:(NSURL *)url {
    if (!url) {
        return nil;
    }
    return [_cacheFloderPath stringByAppendingPathComponent:[self fileNameForKey:[url absoluteString]]];
}

#pragma mark LYDownloadManager
- (LYDownloader *)downloadFileWithURL:(NSURL *)url delegate:(id<LYDownloadManagerDelegate>)delegate {
    if (!url||!delegate) {
        return nil;
    }
    LYDownloader *downloader = [_downloaderForURL objectForKey:url];
    
    if (!downloader) {
        downloader = [[LYDownloader alloc] initWithURL:url filePath:[self filePathForURL:url] cachePath:[self cachePathForURL:url] cacheCapacity:1];
        downloader.delegate = self;
        [_downloaderForURL setObject:downloader forKey:url];
        [downloader start];
        
        [_downloadDelegates addObject:delegate];
        [_downloaders addObject:downloader];
#if !__has_feature(objc_arc)
        [downloader autorelease];
#endif
    } else {
        if (![self downloaderWithDelegate:delegate forURL:url]) {
            [_downloadDelegates addObject:delegate];
            [_downloaders addObject:downloader];
        }
    }
    return downloader;
}

- (void)stopDownloadFileWithURL:(NSURL *)url {
    LYDownloader *downloader = [self downloaderWithURL:url];
    NSUInteger idx;
    while ((idx = [_downloaders indexOfObjectIdenticalTo:downloader]) != NSNotFound)
    {
        if ([_downloaders objectAtIndex:idx]==downloader) {
            id delegate = [_downloadDelegates objectAtIndex:idx];
            if (delegate&&[delegate respondsToSelector:@selector(LYDownloadManager:didStopDownloadOfURL:downloader:)]) {
                [delegate LYDownloadManager:self didStopDownloadOfURL:downloader.url downloader:downloader];
            }
        }
        [_downloadDelegates removeObjectAtIndex:idx];
        [_downloaders removeObjectAtIndex:idx];
        
        if (![_downloaders containsObject:downloader])
        {
            // No more delegate are waiting for this download, cancel it
            [downloader cancel];
            [_downloaderForURL removeObjectForKey:downloader.url];
        }
    }
}

- (LYDownloader *)downloaderWithURL:(NSURL *)url {
    
    return [_downloaderForURL objectForKey:url];
}

- (LYDownloader *)downloaderWithDelegate:(id<LYDownloadManagerDelegate>)delegate forURL:(NSURL *)url {
    LYDownloader *downloader = [_downloaderForURL objectForKey:url];
    if (downloader) {
        NSUInteger idx = [_downloadDelegates indexOfObject:delegate];
        if (idx != NSNotFound) {
            return [_downloaders objectAtIndex:idx];
        }
        for (NSInteger i=0; i<[_downloaders count]; i++) {
            if ([_downloaders objectAtIndex:i]==downloader&&[_downloadDelegates objectAtIndex:i]==delegate) {
                return downloader;
            }
        }
    }
    return nil;
}

- (void)cancelForDelegate:(id<LYDownloadManagerDelegate>)delegate {
    NSUInteger idx;
    while ((idx = [_downloadDelegates indexOfObjectIdenticalTo:delegate]) != NSNotFound)
    {
        LYDownloader *downloader = [_downloaders objectAtIndex:idx];
        
        [_downloadDelegates removeObjectAtIndex:idx];
        [_downloaders removeObjectAtIndex:idx];
        
        if (![_downloaders containsObject:downloader])
        {
            // No more delegate are waiting for this download, cancel it
            [downloader cancel];
            [_downloaderForURL removeObjectForKey:downloader.url];
        }
    }
}

- (NSString *)downloadedFilePathForURL:(NSURL *)url {
    NSString *filePath = [self filePathForURL:url];
    BOOL finished = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    return finished?filePath:nil;
}

#pragma mark LYDownloaderDelegate
- (void)LYDownloaderDidStarted:(LYDownloader *)downloader {
    for (NSUInteger idx =0; idx<_downloaders.count; idx++) {
        if ([_downloaders objectAtIndex:idx]==downloader) {
            id delegate = [_downloadDelegates objectAtIndex:idx];
            if (delegate&&[delegate respondsToSelector:@selector(LYDownloadManager:didStartedOfURL:downloader:)]) {
                [delegate LYDownloadManager:self didStartedOfURL:downloader.url downloader:downloader];
            }
        }
    }
    
}

- (void)LYDownloaderDidDownloadData:(LYDownloader *)downloader {
    for (NSUInteger idx =0; idx<_downloaders.count; idx++) {
        if ([_downloaders objectAtIndex:idx]==downloader) {
            id delegate = [_downloadDelegates objectAtIndex:idx];
            if (delegate&&[delegate respondsToSelector:@selector(LYDownloadManager:didDownloadDataOfURL:downloader:)]) {
                [delegate LYDownloadManager:self didDownloadDataOfURL:downloader.url downloader:downloader];
            }
        }
    }
}

- (void)LYDownloaderDidChangeProgress:(LYDownloader *)downloader {
    for (NSUInteger idx =0; idx<_downloaders.count; idx++) {
        if ([_downloaders objectAtIndex:idx]==downloader) {
            id delegate = [_downloadDelegates objectAtIndex:idx];
            if (delegate&&[delegate respondsToSelector:@selector(LYDownloadManager:didChangedProgressOfURL:downloader:)]) {
                [delegate LYDownloadManager:self didChangedProgressOfURL:downloader.url downloader:downloader];
            }
        }
    }
}

- (void)LYDownloaderDidFinished:(LYDownloader *)downloader {
    NSUInteger idx;
    while ((idx = [_downloaders indexOfObjectIdenticalTo:downloader]) != NSNotFound)
    {
        if ([_downloaders objectAtIndex:idx]==downloader) {
            id delegate = [_downloadDelegates objectAtIndex:idx];
            if (delegate&&[delegate respondsToSelector:@selector(LYDownloadManager:didFinishedOfURL:downloader:)]) {
                [delegate LYDownloadManager:self didFinishedOfURL:downloader.url downloader:downloader];
            }
        }
        
        [_downloadDelegates removeObjectAtIndex:idx];
        [_downloaders removeObjectAtIndex:idx];
        
        if (![_downloaders containsObject:downloader])
        {
            // No more delegate are waiting for this download, cancel it
            [downloader cancel];
            [_downloaderForURL removeObjectForKey:downloader.url];
        }
        
        
    }
}
- (void)LYDownloaderDidFailed:(LYDownloader *)downloader {
    NSUInteger idx;
    while ((idx = [_downloaders indexOfObjectIdenticalTo:downloader]) != NSNotFound)
    {
        if ([_downloaders objectAtIndex:idx]==downloader) {
            id delegate = [_downloadDelegates objectAtIndex:idx];
            if (delegate&&[delegate respondsToSelector:@selector(LYDownloadManager:didDidFaileOfURL:downloader:)]) {
                [delegate LYDownloadManager:self didDidFaileOfURL:downloader.url downloader:downloader];
            }
        }
        [_downloadDelegates removeObjectAtIndex:idx];
        [_downloaders removeObjectAtIndex:idx];
        
        if (![_downloaders containsObject:downloader])
        {
            // No more delegate are waiting for this download, cancel it
            [downloader cancel];
            [_downloaderForURL removeObjectForKey:downloader.url];
        }
    }
}


@end
