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

@property (nonatomic,assign,readonly) LYDownloadState  state;
@property (nonatomic,retain,readonly) NSURL *url;
@property (nonatomic,copy,readonly) NSString *filePath;//保存文件路径
@property (nonatomic,copy,readonly) NSString *cachePath;//缓存路径
@property (nonatomic,assign,readonly) unsigned long long fileSize;//<!文件大小
@property (nonatomic,assign,readonly) unsigned long long finishedSize;//!<已完成的大小

@property (nonatomic,assign) id<LYDownloaderDelegate>delegate;

@property (nonatomic,assign) unsigned long long cacheCapacity;//!<缓存大小 以M为单位

- (id)initWithURL:(NSURL *)url filePath:(NSString *)filePath cachePath:(NSString *)cachePath cacheCapacity:(NSInteger)capacity;
- (void)start;
- (void)cancel;
@end


@interface LYDownloader (readonlyPropertyForGetMethods)

@property (nonatomic,assign,readonly) double progress;
@property (nonatomic,assign,readonly) BOOL isDownloading;
@property (nonatomic,assign,readonly) BOOL hasFinished;

@end

@protocol LYDownloaderDelegate <NSObject>

- (void)LYDownloaderDidStarted:(LYDownloader *)downloader;
- (void)LYDownloaderDidDownloadData:(LYDownloader *)downloader;
- (void)LYDownloaderDidChangeProgress:(LYDownloader *)downloader;
- (void)LYDownloaderDidFinished:(LYDownloader *)downloader;
- (void)LYDownloaderDidFailed:(LYDownloader *)downloader;



@end