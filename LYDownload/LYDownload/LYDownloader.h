//
//  LYDownloader.h
//
//  Created by LY on 15/3/6.
//  Copyright (c) 2015年 刘 洋. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(int, LYDownloadState) {
    LYDownloadState_New,
    LYDownloadState_Downloading,
    LYDownloadState_Canceled,
    LYDownloadState_Finished,
    LYDownloadState_Failed,
};
@protocol LYDownloaderDelegate;
@interface LYDownloader : NSObject

@property (nonatomic,retain) NSURL *url;
@property (nonatomic,copy) NSString *filePath;//保存文件路径
@property (nonatomic,copy) NSString *cachePath;//缓存路径
@property (nonatomic) unsigned long long cacheCapacity;//!<缓存大小 以M为单位
@property (nonatomic,retain) NSURLConnection *connection;//!<下载连接
@property (nonatomic) unsigned long long fileSize;//<!文件大小
@property (nonatomic) unsigned long long finishedSize;//!<已完成的大小
@property (nonatomic,readonly) double progress;
@property (nonatomic,readonly) BOOL isDownloading;
@property (nonatomic,readonly) BOOL hasFinished;
@property (nonatomic,readonly) LYDownloadState  state;


@property (nonatomic,assign) id<LYDownloaderDelegate>delegate;

- (id)initWithURL:(NSURL *)url filePath:(NSString *)filePath cachePath:(NSString *)cachePath cacheCapacity:(NSInteger)capacity;
- (void)start;
//- (void)pause;
- (void)cancel;
@end

@protocol LYDownloaderDelegate <NSObject>

- (void)LYDownloaderDidStarted:(LYDownloader *)downloader;
- (void)LYDownloaderDidDownloadData:(LYDownloader *)downloader;
- (void)LYDownloaderDidChangeProgress:(LYDownloader *)downloader;
- (void)LYDownloaderDidFinished:(LYDownloader *)downloader;
- (void)LYDownloaderDidFailed:(LYDownloader *)downloader;



@end