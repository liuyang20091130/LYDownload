//
//  LYDownloader.m
//
//  Created by LY on 15/3/6.
//  Copyright (c) 2015年 刘 洋. All rights reserved.
//

#import "LYDownloader.h"
@interface LYDownloader()<NSURLConnectionDataDelegate> {
    double lastProgress;
}
@property (nonatomic,assign) LYDownloadState  state;

@property (nonatomic,retain) NSURL *url;
@property (nonatomic,copy) NSString *filePath;//保存文件路径
@property (nonatomic,copy) NSString *cachePath;//缓存路径
@property (nonatomic,assign) unsigned long long fileSize;//<!文件大小
@property (nonatomic,assign) unsigned long long finishedSize;//!<已完成的大小

@property (nonatomic,retain) NSURLConnection *connection;//!<下载连接
@property (nonatomic,retain) NSFileHandle *outFile;
@property (nonatomic,retain) NSMutableData *cacheData;
@end

@implementation LYDownloader

#pragma mark NSObject
- (id)initWithURL:(NSURL *)url filePath:(NSString *)filePath cachePath:(NSString *)cachePath cacheCapacity:(NSInteger)capacity  {
    if (self = [super init]) {
        self.filePath = filePath;
        self.cachePath = cachePath;
        self.url = url;
        self.cacheCapacity = capacity*1024*1024;
        self.state = LYDownloadState_New;
        self.cacheData = [NSMutableData dataWithCapacity:self.cacheCapacity];
        
        BOOL finished = [[NSFileManager defaultManager] fileExistsAtPath:self.filePath];
        if (finished) {
            self.state = LYDownloadState_Finished;
            unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
            self.fileSize = fileSize;
            self.finishedSize = fileSize;
            [self performSelector:@selector(connectionDidFinishLoading:) withObject:nil afterDelay:0.01];
        } else {
            [self creatConnection];
        }
        
        lastProgress = 0.0f;
        if (self.fileSize>0) {
            lastProgress = (long  double)self.finishedSize/(long double)self.fileSize;
        }
        
    }
    return self;
}
- (void)dealloc {
    if (_outFile) {
        [self saveDataToFile];
        [self.outFile closeFile];
        self.outFile = nil;
    }
    
    if (_connection) {
        [self.connection cancel];
        self.connection = nil;
    }
    
    self.cacheData = nil;
    self.filePath = nil;
    self.cachePath = nil;
    self.url = nil;
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

#pragma mark LYDownloader(privite)
- (NSURLConnection *)connection {
    if (_connection==nil) {
        [self creatConnection];
    }
    return _connection;
}

- (void)creatConnection {
    // 记录文件起始位置
    unsigned long long from = 0;
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.cachePath]){ // 已经存在
        from = [[NSData dataWithContentsOfFile:self.cachePath] length];
    }else{ // 不存在，直接创建
        BOOL success = [[NSFileManager defaultManager] createFileAtPath:self.cachePath contents:nil attributes:nil];
        NSLog(@"creat cachePath:%@  : %@",success?@"success":@"faild",self.cachePath);
    }
    
    self.finishedSize = from;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:100.0f];//设置缓存和超时
    NSString *rangeValue = [NSString stringWithFormat:@"bytes=%llu-", from];
    [request addValue:rangeValue forHTTPHeaderField:@"Range"];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
}

- (void)saveDataToFile {
    if (_cacheData.length) {
        // 移动到文件结尾
        [_outFile seekToEndOfFile];
        // 写入文件
        [_outFile writeData:_cacheData];
        // 清空数据
        [_cacheData setLength:0];
    }
}

#pragma mark LYDownloader

- (void)start {
    if (self.state==LYDownloadState_New) {
        [self.connection start];
        self.state = LYDownloadState_Downloading;
    }
}
- (void)cancel {
    
    [self saveDataToFile];
    
    if (self.state == LYDownloadState_Downloading) {
        self.state = LYDownloadState_Canceled;
    }
    
    if (_connection) {
        [self.connection cancel];
        self.connection = nil;
    }
}

#pragma mark NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.outFile = [NSFileHandle fileHandleForWritingAtPath:self.cachePath];
    
    NSHTTPURLResponse*httpResponse=(NSHTTPURLResponse*)response;
    if(httpResponse&&[httpResponse respondsToSelector:@selector(allHeaderFields)]){
        NSDictionary *httpResponseHeaderFields = [httpResponse allHeaderFields];
        self.fileSize = self.finishedSize + [[httpResponseHeaderFields objectForKey:@"Content-Length"]longLongValue];
    }
     //NSLog(@"finishedSize = %lld ,fileSize = %lld , %.3Lf",self.finishedSize,self.fileSize,(long double)self.finishedSize/(long double)self.fileSize);
    if (_delegate&&[_delegate respondsToSelector:@selector(LYDownloaderDidStarted:)]) {
        [_delegate LYDownloaderDidStarted:self];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    // 保存数据
    [_cacheData appendData:data];
    if (_cacheData.length >= _cacheCapacity) {
        [self saveDataToFile];
    }
    unsigned long long fileLength = [_outFile seekToEndOfFile];
    self.finishedSize = fileLength + _cacheData.length;
    
    double progress = (long double)self.finishedSize/(long double)self.fileSize;
    if (progress-lastProgress>0.01||progress==1.0f) {
        if (_delegate&&[_delegate respondsToSelector:@selector(LYDownloaderDidChangeProgress:)]) {
            [_delegate LYDownloaderDidChangeProgress:self];
        }
        lastProgress = progress;
    }
    //NSLog(@"finishedSize = %lld ,fileSize = %lld , %.2f",self.finishedSize,self.fileSize,progress);
    if (_delegate &&[_delegate respondsToSelector:@selector(LYDownloaderDidDownloadData:)]) {
        [_delegate LYDownloaderDidDownloadData:self];
    }
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.outFile closeFile];
    self.outFile = nil;
    NSError *error = nil;
    [[NSFileManager defaultManager] moveItemAtPath:self.cachePath toPath:self.filePath error:&error];
     //NSLog(@"finishedSize = %lld ,fileSize = %lld , %.3Lf",self.finishedSize,self.fileSize,(long double)self.finishedSize/(long double)self.fileSize);
    //NSLog(@"filePath = %@",self.filePath);
    if (_delegate&&[_delegate respondsToSelector:@selector(LYDownloaderDidFinished:)]) {
        [_delegate LYDownloaderDidFinished:self];
    }
}



@end


@implementation LYDownloader (readonlyPropertyForGetMethods)

- (BOOL)isDownloading {
    return self.state == LYDownloadState_Downloading;
}

- (BOOL)hasFinished {
    return self.state == LYDownloadState_Finished;
}

- (double)progress {
    return (long  double)self.finishedSize/(long double)self.fileSize;
}

@end
