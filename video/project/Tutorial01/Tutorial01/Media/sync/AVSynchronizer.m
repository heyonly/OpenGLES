//
//  AVSynchronizer.m
//  Tutorial01
//
//  Created by heyonly on 2019/5/7.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "AVSynchronizer.h"
#import "VideoDecoder.h"
#import <pthread.h>


#define LOCAL_MIN_BUFFERED_DURATION                     0.5
#define LOCAL_MAX_BUFFERED_DURATION                     1.0
#define NETWORK_MIN_BUFFERED_DURATION                   2.0
#define NETWORK_MAX_BUFFERED_DURATION                   4.0
#define LOCAL_AV_SYNC_MAX_TIME_DIFF                     0.05
#define FIRST_BUFFER_DURATION                           0.5

NSString * const kMIN_BUFFERED_DURATION = @"Min_Buffered_Duration";
NSString * const kMAX_BUFFERED_DURATION = @"Max_Buffered_Duration";


@interface AVSynchronizer ()
{
    VideoDecoder                    *_decoder;
    BOOL                            _usingHWCodec;
    BOOL                            isOnDecoding;
    BOOL                            isInitializeDecodeThread;
    BOOL                            isDestroyed;
    BOOL                            isFirstScreen;
    
    pthread_mutex_t                 decodeFirstBufferLock;
    pthread_cond_t                  decodeFirstBufferCondition;
    pthread_t                       decodeFirstBufferThread;
    
    BOOL                            isDecodingFirstBuffer;
    
    pthread_mutex_t                 videoDecoderLock;
    pthread_cond_t                  videoDecoderCondition;
    pthread_t                       videoDecoderThread;
    
    
    NSMutableArray                  *_videoFrames;
    NSMutableArray                  *_audioFrames;
    
    NSData                          *_currentAudioFrame;
    NSUInteger                      _currentAudioFramePos;
    CGFloat                         _audioPosition;
    VideoFrame                      *_currentVideoFrame;
    
    
    BOOL                            _buffered;
    CGFloat                         _bufferedDuration;
    CGFloat                         _minBufferedDuration;
    CGFloat                         _maxBufferedDuration;
    
    CGFloat                         _syncMaxTimeDiff;
    NSInteger                       _firstBufferDuration;
    
    
    BOOL                            _completion;
    NSTimeInterval                  _bufferedBeginTime;
    NSTimeInterval                  _bufferedTotalTime;
    
    
    int                             _decodeVideoErrorState;
    NSTimeInterval                  _decodeVideoErrorBeginTime;
    NSTimeInterval                  _decodeVideoErrorTotalTime;
}
@end

@implementation AVSynchronizer

static BOOL isNetworkPath (NSString *path)
{
    NSRange r = [path rangeOfString:@":"];
    if (r.location == NSNotFound)
        return NO;
    NSString *scheme = [path substringToIndex:r.length];
    if ([scheme isEqualToString:@"file"])
        return NO;
    return YES;
}

- (id)initWithPlayerStateDelegate:(id<PlayerStateDelegate>)playerStateDelegate {
    if (self = [super init]) {
        _playerStateDelegate = playerStateDelegate;
    }
    return self;
}

- (OpenState)openFile:(NSString *)path usingHWCodec:(BOOL)usingHWCodec parameters:(NSDictionary *)parameters error:(NSError * _Nullable __autoreleasing *)perror
{
    _usingHWCodec = usingHWCodec;
    _decoder = [self decoderInstance];
    
    _currentVideoFrame = NULL;
    _currentAudioFramePos = 0;
    
    _bufferedBeginTime = 0;
    _bufferedTotalTime = 0;
    
    _decodeVideoErrorBeginTime = 0;
    _decodeVideoErrorTotalTime = 0;
    
    BOOL isNetwork = isNetworkPath(path);
    if (isNetwork) {
        _minBufferedDuration = NETWORK_MIN_BUFFERED_DURATION;
        _maxBufferedDuration = NETWORK_MAX_BUFFERED_DURATION;
    }else {
        _minBufferedDuration = LOCAL_MIN_BUFFERED_DURATION;
        _maxBufferedDuration = LOCAL_MAX_BUFFERED_DURATION;
    }
    
    _syncMaxTimeDiff = LOCAL_AV_SYNC_MAX_TIME_DIFF;
    _firstBufferDuration = FIRST_BUFFER_DURATION;
    
    BOOL openCode = [_decoder openFile:path parameter:parameters error:perror];
    
    if (!openCode) {
//        [self closeDecoder];
        return OPEN_FAILED;
    }
    
    NSUInteger videoWidth = [_decoder frameWidth];
    NSUInteger videoHeight = [_decoder frameHeight];
    
    if (videoWidth <= 0 || videoHeight <= 0) {
        return OPEN_FAILED;
    }
    
    _audioFrames = [NSMutableArray array];
    _videoFrames = [NSMutableArray array];
    [self startDecoderThread];
//    [self startDecoderFirstBufferThread];
    return OPEN_SUCCESS;
}

static void *decodeFirstBufferRunLoop(void *ptr) {
    AVSynchronizer *synchronizer = (__bridge AVSynchronizer *)ptr;
    [synchronizer decodeFirstBuffer];
    return NULL;
}

- (void)decodeFirstBuffer {
    double startDecodeFirstBufferTimeMills = CFAbsoluteTimeGetCurrent() * 1000;
    [self decodeFrameWithDuration:FIRST_BUFFER_DURATION];
    int wasteTimeMills = CFAbsoluteTimeGetCurrent() * 1000 - startDecodeFirstBufferTimeMills;
    NSLog(@"Decode First Buffer waste TimeMills is %d", wasteTimeMills);
    pthread_mutex_lock(&decodeFirstBufferLock);
    pthread_cond_signal(&decodeFirstBufferCondition);
    pthread_mutex_unlock(&decodeFirstBufferLock);
    isDecodingFirstBuffer = false;
}

- (void)decodeFrameWithDuration:(CGFloat)duration {
    BOOL good = YES;
    while (good) {
        good = NO;
        @autoreleasepool {
            if (_decoder && (_decoder.validVideo || _decoder.validAudio)) {
                int tmpDecodeVideoErrorState;
                NSArray *frames = [_decoder decodeFrames:0.0f decodeVideoErrorState:&tmpDecodeVideoErrorState];
                if (frames.count) {
                    good = [self addFrames:frames duration:duration];
                }
            }
        }
    }
}

- (void)startDecoderFirstBufferThread {
    pthread_mutex_init(&decodeFirstBufferLock, NULL);
    pthread_cond_init(&decodeFirstBufferCondition, NULL);
    isDecodingFirstBuffer = true;
    
    pthread_create(&decodeFirstBufferThread, NULL, decodeFirstBufferRunLoop, (__bridge void*)(self));
}

static void *runDecoderThread(void *ptr) {
    AVSynchronizer *synchronizer = (__bridge AVSynchronizer*)ptr;
    [synchronizer run];
    return NULL;
}

- (void)run {
    while (isOnDecoding) {
        pthread_mutex_lock(&videoDecoderLock);
        pthread_cond_wait(&videoDecoderCondition, &videoDecoderLock);
        
        pthread_mutex_unlock(&videoDecoderLock);
        
        [self decodeFrames];
    }
}

- (void)decodeFrames {
    const CGFloat duration = 0.0f;
    BOOL good = YES;
    while (good) {
        good = NO;
        @autoreleasepool {
            if (_decoder && (_decoder.validVideo || _decoder.validAudio)) {
                NSArray *frames = [_decoder decodeFrames:duration decodeVideoErrorState:&_decodeVideoErrorState];
                
                if (frames.count) {
                    good = [self addFrames:frames duration:_maxBufferedDuration];
                }
            }
        }
    }
}

- (BOOL)addFrames:(NSArray *)frames duration:(CGFloat)duration {
    
    if (_decoder.validVideo) {
        @synchronized(_videoFrames) {
            for (Frame *frame in frames)
                if (frame.type == VideoFrameType || frame.type == iOSCVVideoFrameType) {
                    [_videoFrames addObject:frame];
                }
        }
    }
    
    if (_decoder.validAudio) {
        @synchronized(_audioFrames) {
            for (Frame *frame in frames)
                if (frame.type == AudioFrameType) {
                    [_audioFrames addObject:frame];
                    _bufferedDuration += frame.duration;
                }
        }
    }
    return _bufferedDuration < duration;
}

- (void)startDecoderThread {
    isOnDecoding = YES;
    isDestroyed = false;
    pthread_mutex_init(&videoDecoderLock, NULL);
    pthread_cond_init(&videoDecoderCondition, NULL);
    
    isInitializeDecodeThread = true;
    pthread_create(&videoDecoderThread, NULL, runDecoderThread, (__bridge void*)(self));
}

- (OpenState)openFile:(NSString *)path usingHWCodec:(BOOL)usingHWCodec error:(NSError * _Nullable __autoreleasing *)perror {
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    parameters[FPS_PROBE_SIZE_CONFIGURED] = @(true);
    parameters[PROBE_SIZE] = @(50 * 1024);
    NSMutableArray* durations = [NSMutableArray array];
    durations[0] = @(1250000);
    durations[0] = @(1750000);
    durations[0] = @(2000000);
    parameters[MAX_ANALYZE_DURATION_ARRAY] = durations;
    return [self openFile:path usingHWCodec:usingHWCodec parameters:parameters error:perror];
}

- (VideoDecoder *)decoderInstance {
    VideoDecoder *decoder;
    if (_usingHWCodec) {
        
    }else {
        decoder = [[VideoDecoder alloc] init];
    }
    return decoder;
}

static int count = 0;
static int invalidGetCount = 0;
float lastPosition = -1.0;


- (VideoFrame *)getCorrectVideoFrame {
    VideoFrame *frame = NULL;
    @synchronized (_videoFrames) {
        while (_videoFrames.count > 0) {
            frame = _videoFrames[0];
            const CGFloat delta = _audioPosition - frame.position;
            if (delta < (0 - _syncMaxTimeDiff)) {
                frame = NULL;
                break;
            }
            [_videoFrames removeObjectAtIndex:0];
            if (delta > _syncMaxTimeDiff) {
                frame = NULL;
                continue;
            }else {
                break;
            }
        }
    }
    if (frame) {
        if (NULL != _currentVideoFrame) {
            _currentVideoFrame = NULL;
        }
        _currentVideoFrame = frame;
    }
    
    if (fabs(_currentVideoFrame.position - lastPosition) > 0.01f) {
        lastPosition = _currentVideoFrame.position;
        count++;
        return _currentVideoFrame;
    }else {
        invalidGetCount++;
        return nil;
    }
    
//    return frame;
    
}


- (void) audioCallbackFillData: (SInt16 *) outData
                     numFrames: (UInt32) numFrames
                   numChannels: (UInt32) numChannels
{
    [self checkPlayState];
    if (_buffered) {
        memset(outData, 0, numFrames * numChannels * sizeof(SInt16));
        return;
    }
    
    @autoreleasepool {
        while (numFrames > 0) {
            if (!_currentAudioFrame) {
                @synchronized (_audioFrames) {
                    NSInteger count = _audioFrames.count;
                    if (count > 0) {
                        AudioFrame *frame = _audioFrames[0];
                        _bufferedDuration -= frame.duration;
                        [_audioFrames removeObjectAtIndex:0];
                        _audioPosition = frame.position;
                        
                        _currentAudioFramePos = 0;
                        _currentAudioFrame = frame.samples;
                        memcpy(outData, _currentAudioFrame.bytes, _currentAudioFrame.length);
                        
                    }
                }
            }
            
            if (_currentAudioFrame) {
                const void *bytes = (Byte *)_currentAudioFrame.bytes + _currentAudioFramePos;
                const NSUInteger bytesLeft = (_currentAudioFrame.length - _currentAudioFramePos);
                const NSUInteger frameSizeOf = numChannels * sizeof(SInt16);
                const NSUInteger bytesToCopy = MIN(numFrames * frameSizeOf, bytesLeft);
                const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
                
                memcpy(outData, bytes, bytesToCopy);
                numFrames -= framesToCopy;
                outData += framesToCopy * numChannels;
                
                if (bytesToCopy < bytesLeft)
                    _currentAudioFramePos += bytesToCopy;
                else
                    _currentAudioFrame = nil;
                
            } else {
                memset(outData, 0, numFrames * numChannels * sizeof(SInt16));
                break;
            }
        }
    }
}


- (void)checkPlayState {
    if (NULL == _decoder) {
        return;
    }
    
    if (_buffered && (_bufferedDuration > _minBufferedDuration)) {
        _buffered = NO;
        
    }
    
    if (1 == _decodeVideoErrorState) {
        _decodeVideoErrorState = 0;
        if (_minBufferedDuration > 0 && !_buffered) {
            _buffered = YES;
            _decodeVideoErrorBeginTime = [[NSDate date] timeIntervalSince1970];
        }
        
        _decodeVideoErrorTotalTime = [[NSDate date] timeIntervalSince1970] - _decodeVideoErrorBeginTime;
        
        if (_decodeVideoErrorTotalTime > TIMEOUT_DECODE_ERROR) {
            _decodeVideoErrorTotalTime = 0;
            
        }
        return;
    }
    
    const NSUInteger leftVideoFrames = _decoder.validVideo ? _videoFrames.count : 0;
    const NSUInteger leftAudioFrames = _decoder.validAudio ? _audioFrames.count : 0;
    
    if (0 == leftVideoFrames || 0 == leftAudioFrames) {
//        [_decoder add]
        if (_minBufferedDuration > 0 && !_buffered) {
            _buffered = YES;
        }
        
        if ([_decoder isEOF]) {
            if (_playerStateDelegate && [_playerStateDelegate respondsToSelector:@selector(onCompletion)]) {
                _completion = YES;
                [_playerStateDelegate onCompletion];
            }
        }
    }
    
//    if (_buffered) {
//        _bufferedTotalTime = [[NSDate date] timeIntervalSince1970] - _bufferedBeginTime;
//        if (_bufferedTotalTime > TIMEOUT_BUFFER) {
//            _bufferedTotalTime = 0;
//            return;
//        }
//
//    }
    
    if (!isDecodingFirstBuffer && (0 == leftVideoFrames || 0 == leftAudioFrames || !(_bufferedDuration > _minBufferedDuration))) {
        [self signalDecoderThread];
    }
}

- (void) signalDecoderThread
{
    if(NULL == _decoder || isDestroyed) {
        return;
    }
    if(!isDestroyed) {
        pthread_mutex_lock(&videoDecoderLock);
        //        NSLog(@"Before signal First decode Buffer...");
        pthread_cond_signal(&videoDecoderCondition);
        //        NSLog(@"After signal First decode Buffer...");
        pthread_mutex_unlock(&videoDecoderLock);
    }
}

- (NSInteger) getAudioSampleRate {
    if (_decoder) {
        return [_decoder sampleRate];
    }
    return -1;
}
- (NSInteger) getAudioChannels {
    if (_decoder) {
        return [_decoder channels];
    }
    return -1;
}
- (CGFloat) getVideoFPS {
    if (_decoder) {
        return [_decoder getVideoFPS];
    }
    return 0.0f;
}
- (NSInteger) getVideoFrameHeight {
    if (_decoder) {
        return [_decoder frameHeight];
    }
    return 0;
}
- (NSInteger) getVideoFrameWidth {
    if (_decoder) {
        return [_decoder frameWidth];
    }
    return 0;
}
- (BOOL) isValid {
    if(_decoder && ![_decoder validVideo] && ![_decoder validAudio]){
        return NO;
    }
    return YES;
}
- (CGFloat) getDuration {
    if (_decoder) {
        return [_decoder getDuration];
    }
    return 0.0f;
}

@end
