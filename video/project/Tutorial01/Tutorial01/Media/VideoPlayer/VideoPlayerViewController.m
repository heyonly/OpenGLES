//
//  VideoPlayerViewController.m
//  Tutorial01
//
//  Created by heyonly on 2019/5/6.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "VideoPlayerViewController.h"
#import <libavformat/avformat.h>
#import "VideoOutputView.h"
#import "AVSynchronizer.h"
#import "AudioOutput.h"
@interface VideoPlayerViewController ()<PlayerStateDelegate,FillDataDelegate>
@property (nonatomic, strong) AVSynchronizer *synchronizer;
@property (nonatomic, strong) NSString *videoPath;
@property (nonatomic, strong) VideoOutputView *videoView;
@property (nonatomic, strong) AudioOutput *audioOutput;
@end

@implementation VideoPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.videoPath = [[NSBundle mainBundle]pathForResource:@"sintel" ofType:@"mov"];
    
    [self start];
}

- (void)start {
    self.synchronizer = [[AVSynchronizer alloc] initWithPlayerStateDelegate:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        OpenState state = OPEN_FAILED;
        NSError *error;

        state = [self.synchronizer openFile:self.videoPath usingHWCodec:NO error:&error];
        if (state == OPEN_SUCCESS) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.videoView = [self createVideoOutputInstance];
                self.videoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
                [self.view addSubview:self.videoView];
            });
            
            NSInteger audioChannels = [self.synchronizer getAudioChannels];
            NSInteger audioSampleRate = [self.synchronizer getAudioSampleRate];
            NSInteger bytesPerSample = 2;
            self.audioOutput = [[AudioOutput alloc] initWithChannels:audioChannels sampleRate:audioSampleRate bytesPerSample:bytesPerSample filleDataDelegate:self];
            [self.audioOutput play];
        }
    });
}

- (NSInteger)fillAudioData:(SInt16 *)sampleBuffer numFrames:(NSInteger)frameNum numChannels:(NSInteger)channels {
    if (_synchronizer) {
        [_synchronizer audioCallbackFillData:sampleBuffer numFrames:(UInt32)frameNum numChannels:(UInt32)channels];
        VideoFrame *videoFrame = [_synchronizer getCorrectVideoFrame];
        if (videoFrame) {
            [_videoView presentVideoFrame:videoFrame];
        }
    }else {
        memset(sampleBuffer, 0, frameNum * channels * sizeof(SInt16));
    }
    
    return 1;
}

- (VideoOutputView *)createVideoOutputInstance {
    CGRect bounds = self.view.bounds;
    NSInteger textureWidth = [_synchronizer getVideoFrameWidth];
    NSInteger textureHeight = [_synchronizer getVideoFrameHeight];
//    bounds.size.width = textureWidth;
//    bounds.size.height = textureHeight;
    VideoOutputView *view = [[VideoOutputView alloc] initWithFrame:bounds textureWidth:textureWidth textureHeight:textureHeight usingHWCodec:NO];
    view.contentMode = UIViewContentModeScaleToFill;
    
    return view;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
