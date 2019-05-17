//
//  VideoDecoder.h
//  Tutorial01
//
//  Created by heyonly on 2019/5/6.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>

#import <libavformat/avformat.h>
#import <libavcodec/avcodec.h>
#import <libswscale/swscale.h>
#import <libswresample/swresample.h>
#import <libavutil/pixdesc.h>

#import "Frame.h"
#import "AudioFrame.h"
#import "VideoFrame.h"
#import "BuriedPoint.h"

NS_ASSUME_NONNULL_BEGIN



@interface VideoDecoder : NSObject
{
    AVFormatContext         *_formatCtx;
    BOOL                    _isOpenInputSuccess;
    BuriedPoint             *_buriedPoint;
    int                     totalVideoFramecount;
    long long               decodeVideoFrameWasteTimeMills;
    NSArray                 *_videoStreams;
    NSArray                 *_audioStreams;
    NSInteger               _videoStreamIndex;
    NSInteger               _audioStreamIndex;
    AVCodecContext          *_videoCodecCtx;
    AVCodecContext          *_audioCodecCtx;
    CGFloat                 _videoTimeBase;
    CGFloat                 _audioTimeBase;
}

- (BOOL)openFile:(NSString *)path parameter:(NSDictionary *)parameters error:(NSError **)perror;

- (NSArray *)decodeFrames:(CGFloat)minDuration decodeVideoErrorState:(int *)decodeVideoErrorState;

- (NSUInteger)frameWidth;
- (NSUInteger)frameHeight;
- (CGFloat)sampleRate;
- (NSUInteger)channels;
- (BOOL)validVideo;
- (BOOL)validAudio;
- (CGFloat)getVideoFPS;
- (CGFloat)getDuration;
- (BOOL)isEOF;
@end

NS_ASSUME_NONNULL_END
