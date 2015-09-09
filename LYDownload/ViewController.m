//
//  ViewController.m
//  LYDownload
//
//  Created by 刘洋 on 15/9/9.
//  Copyright (c) 2015年 刘洋. All rights reserved.
//

#import "ViewController.h"
#import "LYDownloadManager.h"
#define NSLogLine  NSLog(@"%s",__func__)

@interface ViewController ()<LYDownloadManagerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString *url = @"http://music.baidu.com/data/music/file?link=http://yinyueshiting.baidu.com/data2/music/134378685/2230211441771261128.mp3?xcode=4a26a666b7c146ca3d7cab37c0a62272&song_id=223021";
    [[LYDownloadManager sharedManager] downloadFileWithURL:[NSURL URLWithString:url] delegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 
- (void)LYDownloadManager:(LYDownloadManager *)manager didStartedOfURL:(NSURL *)url downloader:(LYDownloader *)downloader {
    NSLogLine;
}
- (void)LYDownloadManager:(LYDownloadManager *)manager didDownloadDataOfURL:(NSURL *)url downloader:(LYDownloader *)downloader {
    NSLogLine;
}
- (void)LYDownloadManager:(LYDownloadManager *)manager didChangedProgressOfURL:(NSURL *)url downloader:(LYDownloader *)downloader {
    NSLogLine;
    NSLog(@"progress = %f",(double)downloader.finishedSize/(double)downloader.fileSize);
}
- (void)LYDownloadManager:(LYDownloadManager *)manager didFinishedOfURL:(NSURL *)url downloader:(LYDownloader *)downloader {
    NSLogLine;
}
- (void)LYDownloadManager:(LYDownloadManager *)manager didDidFaileOfURL:(NSURL *)url downloader:(LYDownloader *)downloader {
    NSLogLine;
}
- (void)LYDownloadManager:(LYDownloadManager *)manager didStopDownloadOfURL:(NSURL *)url downloader:(LYDownloader *)downloader {
    NSLogLine;
}

@end
