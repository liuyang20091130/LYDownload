//
//  LYDownloadManager.h
//
//  Created by LY on 15/3/6.
//  Copyright (c) 2015年 刘 洋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LYDownloader.h"

@protocol LYDownloadManagerDelegate;

@interface LYDownloadManager : NSObject

+ (LYDownloadManager *)sharedManager;
- (LYDownloader *)downloadFileWithURL:(NSURL *)url delegate:(id<LYDownloadManagerDelegate>)delegate;
- (void)stopDownloadFileWithURL:(NSURL *)url;


- (LYDownloader *)downloaderWithURL:(NSURL *)url;
- (LYDownloader *)downloaderWithDelegate:(id<LYDownloadManagerDelegate>)delegate forURL:(NSURL *)url;

- (void)cancelForDelegate:(id<LYDownloadManagerDelegate>)delegate;

- (NSString *)downloadedFilePathForURL:(NSURL *)url;

@end

@protocol LYDownloadManagerDelegate <NSObject>

@optional
- (void)LYDownloadManager:(LYDownloadManager *)manager didStartedOfURL:(NSURL *)url downloader:(LYDownloader *)downloader;
- (void)LYDownloadManager:(LYDownloadManager *)manager didDownloadDataOfURL:(NSURL *)url downloader:(LYDownloader *)downloader;
- (void)LYDownloadManager:(LYDownloadManager *)manager didChangedProgressOfURL:(NSURL *)url downloader:(LYDownloader *)downloader;
- (void)LYDownloadManager:(LYDownloadManager *)manager didFinishedOfURL:(NSURL *)url downloader:(LYDownloader *)downloader;
- (void)LYDownloadManager:(LYDownloadManager *)manager didDidFaileOfURL:(NSURL *)url downloader:(LYDownloader *)downloader;
- (void)LYDownloadManager:(LYDownloadManager *)manager didStopDownloadOfURL:(NSURL *)url downloader:(LYDownloader *)downloader;

@end
