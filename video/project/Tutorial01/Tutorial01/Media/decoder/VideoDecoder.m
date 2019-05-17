//
//  VideoDecoder.m
//  Tutorial01
//
//  Created by heyonly on 2019/5/6.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "VideoDecoder.h"

@interface VideoDecoder ()
{
    AVFrame                 *_videoFrame;
    AVFrame                 *_audioFrame;
    
    CGFloat                 _fps;
    CGFloat                 _decodePosition;
    
    BOOL                    _isSubscribe;
    BOOL                    _isEOF;
    
    SwrContext              *_swrContext;
    void                    *_swrBuffer;
    NSUInteger              _swrBufferSize;
    
    AVPicture               _picture;
    BOOL                    _pictureValid;
    struct SwsContext       *_swsContext;
    
    int                     _subscribeTimeOutTimeInSecs;
    int                     _readLastestFrameTime;
    
    BOOL                    _interrupted;
    int                     _connectionRetry;
}

@end
/*
for (int i=0; i < nheight; i++)
{
    memcpy(m_pYUVBuffer + nYUVBufsize , m_pYUVFrame->data[0] + i * m_pYUVFrame->linesize[0],
           nwidth);
    nYUVBufsize += nwidth;
}
for (int i=0; i < nheight/2; i++)
{
    memcpy(m_pYUVBuffer + nYUVBufsize , m_pYUVFrame->data[1] + i * m_pYUVFrame->linesize[1],
           nwidth/2);
    nYUVBufsize += nwidth/2;
}
for (int i=0; i < nheight/2; i++)
{
    memcpy(m_pYUVBuffer + nYUVBufsize , m_pYUVFrame->data[2] + i * m_pYUVFrame->linesize[2],
           nwidth/2);
    nYUVBufsize += nwidth/2;
}
*/

static NSData * copyFrameData(UInt8 *src,int linesize, int width,int height) {
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength:width * height];
    Byte *dst = md.mutableBytes;
    for (int i = 0; i < height; i++) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}


static NSArray *collectStreams(AVFormatContext *formatCtx,enum AVMediaType codecType) {
    NSMutableArray *ma = [NSMutableArray array];
    for (NSInteger i = 0; i < formatCtx->nb_streams; i++) {
        if (codecType == formatCtx->streams[i]->codec->codec_type) {
            [ma addObject:[NSNumber numberWithInteger:i]];
        }
    }
    return [ma copy];
}

static void avStreamFPSTimeBase(AVStream *st,CGFloat defaultTimeBase,CGFloat *pFPS,CGFloat *pTimeBase) {
    CGFloat fps,timebase;
    if (st->time_base.den && st->time_base.num) {
        timebase = av_q2d(st->time_base);
    }else if (st->codec->time_base.den && st->codec->time_base.num) {
        timebase = av_q2d(st->codec->time_base);
    }else {
        timebase = defaultTimeBase;
    }
    
    if (st->codec->ticks_per_frame != 1) {
        NSLog(@"st.codec.ticks_per_frame : %d",st->codec->ticks_per_frame);
    }
    
    if (st->avg_frame_rate.den && st->avg_frame_rate.num) {
        fps = av_q2d(st->avg_frame_rate);
    }else if (st->r_frame_rate.den && st->r_frame_rate.num) {
        fps = av_q2d(st->r_frame_rate);
    }else {
        fps = 1.0 / timebase;
    }
    
    if (pFPS) {
        *pFPS = fps;
    }
    if (pTimeBase) {
        *pTimeBase = timebase;
    }
}

@implementation VideoDecoder

static int interrupt_callback(void *ctx) {
    
    return 0;
}



- (BOOL)openFile:(NSString *)path parameter:(NSDictionary *)parameters error:(NSError **)perror {
    
    BOOL ret = YES;
    if (nil == path) {
        return  NO;
    }
    _connectionRetry = 0;
    totalVideoFramecount = 0;
    _subscribeTimeOutTimeInSecs = SUBSCRIBE_VIDEO_DATA_TIME_OUT;
    _interrupted = NO;
    _isOpenInputSuccess = NO;
    _isSubscribe = YES;
    _buriedPoint = [[BuriedPoint alloc] init];
    _buriedPoint.bufferStatusRecords = [[NSMutableArray alloc] init];
    _readLastestFrameTime = [[NSDate date] timeIntervalSince1970] * 1000;
    
    avformat_network_init();
    av_register_all();
    int openInputErrCode = [self openInput:path parameter:parameters];
    if (openInputErrCode > 0) {
        BOOL openVideoStatus = [self openVideStream];
        BOOL openAudioStatus = [self openAudioStream];
        if (!openVideoStatus || !openAudioStatus) {
            [self closeFile];
            ret = NO;
        }
    }else {
        _buriedPoint.failOpen = ([[NSDate date] timeIntervalSince1970] * 1000 - _buriedPoint.beginOpen) / 1000.0f;
        _buriedPoint.successOpen = 0.0f;
        _buriedPoint.failOpenType = openInputErrCode;
        ret = NO;
    }
    _buriedPoint.retryTimes = _connectionRetry;
    
    
    return ret;
}

- (BOOL)openVideStream {
    _videoStreamIndex = -1;
    _videoStreams = collectStreams(_formatCtx, AVMEDIA_TYPE_VIDEO);
    for (NSNumber *n in _videoStreams) {
        const NSUInteger iStream = n.integerValue;
        AVCodecContext *codecCtx = _formatCtx->streams[iStream]->codec;
        
        AVCodec *codec = avcodec_find_decoder(codecCtx->codec_id);
        if (!codec) {
            NSLog(@"Find Video Decoder Failed codec_id %d code_id_h264 %d",codecCtx->codec_id,AV_CODEC_ID_H264);
            return NO;
        }
        
        int openCodecErrCode = 0;
        
        if ((openCodecErrCode = avcodec_open2(codecCtx, codec, NULL)) < 0) {
            NSLog(@"open Video Codec Failed openCodecErr is %s",av_err2str(openCodecErrCode));
            return NO;
        }
        
        _videoFrame = av_frame_alloc();
        if (!_videoFrame) {
            NSLog(@"Alloc Video Frame Failed ..");
            avcodec_close(codecCtx);
            return NO;
        }
        
        _videoStreamIndex = iStream;
        _videoCodecCtx = codecCtx;
        
        AVStream *st = _formatCtx->streams[_videoStreamIndex];
        avStreamFPSTimeBase(st, 0.04, &_fps, &_videoTimeBase);
        break;
    }
    return YES;
}

- (BOOL)openAudioStream {
    _audioStreamIndex = -1;
    _audioStreams = collectStreams(_formatCtx, AVMEDIA_TYPE_AUDIO);
    
    for (NSNumber *n in _audioStreams) {
        const NSUInteger iStream = [n integerValue];
        AVCodecContext *codecCtx = _formatCtx->streams[iStream]->codec;
        
        AVCodec *codec = avcodec_find_decoder(codecCtx->codec_id);
        if (!codec) {
            NSLog(@"Find audio Decoder Failed codec_id %d codec_id_aac is %d",codecCtx->codec_id,AV_CODEC_ID_AAC);
            
            return NO;
        }
        int openCodecErrcode = 0;
        if ((openCodecErrcode = avcodec_open2(codecCtx, codec, NULL)) < 0) {
            NSLog(@"Open Audio Codec Failed openCodecErr is %s",av_err2str(openCodecErrcode));
            return NO;
        }
        
        SwrContext *swrContext = NULL;
        if (![self audioCodecIsSupported:codecCtx]) {
            swrContext = swr_alloc_set_opts(NULL, av_get_default_channel_layout(codecCtx->channels), AV_SAMPLE_FMT_S16, codecCtx->sample_rate, av_get_default_channel_layout(codecCtx->channels), codecCtx->sample_fmt, codecCtx->sample_rate, 0, NULL);
            
            if (!swrContext || swr_init(swrContext)) {
                if (swrContext) {
                    swr_free(&swrContext);
                }
                avcodec_close(codecCtx);
                
                NSLog(@"init resampler failed ...");
                return NO;
            }
            _audioFrame = av_frame_alloc();
            if (!_audioFrame) {
                NSLog(@"Alloc Audio Frame Failed ...");
                if (swrContext) {
                    swr_free(&swrContext);
                }
                avcodec_close(codecCtx);
                return NO;
            }
            _audioStreamIndex = iStream;
            _audioCodecCtx = codecCtx;
            _swrContext = swrContext;
            AVStream *st = _formatCtx->streams[_audioStreamIndex];
            
            avStreamFPSTimeBase(st, 0.025, 0, &_audioTimeBase);
            break;
        }
        
    }
    return YES;
}

- (void)closeFile {
    
}

- (BOOL)audioCodecIsSupported:(AVCodecContext *)audioCodecCtx {
    if (audioCodecCtx->sample_fmt == AV_SAMPLE_FMT_S16) {
        return true;
    }
    return false;
}

- (int)openInput:(NSString *)path parameter:(NSDictionary *)parameters {
    AVFormatContext *formatCtx = avformat_alloc_context();
    AVIOInterruptCB int_cb = {interrupt_callback,(__bridge void *)self};
    formatCtx->interrupt_callback = int_cb;
    int openInputErrorCode = 0;
    if ((openInputErrorCode = avformat_open_input(&formatCtx, [path UTF8String], NULL, NULL)) != 0) {
        NSLog(@"Video decoder open input file Failed .. videoSource URI is %@ openInputErr is %s",path,av_err2str(openInputErrorCode));
        if (formatCtx) {
            avformat_free_context(formatCtx);
        }
        return openInputErrorCode;
    }
    
//    [self initAnalyzeDurationAndProbesize:formatCtx parameter:parameters];
    int findStreamErrCode = 0;
    double startFindStreamTimeMills = CFAbsoluteTimeGetCurrent() * 1000;
    if ((findStreamErrCode = avformat_find_stream_info(formatCtx, NULL)) < 0) {
        avformat_close_input(&formatCtx);
        avformat_free_context(formatCtx);
        NSLog(@"Video decoder find stream info failed .. find stream ErrCode is %s",av_err2str(findStreamErrCode));
        return findStreamErrCode;
    }
    
    int wasteYimeMills = CFAbsoluteTimeGetCurrent() * 1000 - startFindStreamTimeMills;
    NSLog(@"Find Stream Info waste TimeMills is %d",wasteYimeMills);
    
    if (formatCtx->streams[0]->codec->codec_id == AV_CODEC_ID_NONE) {
        avformat_close_input(&formatCtx);
        avformat_free_context(formatCtx);
//        if ([self isNeedRetry]) {
//            return [self openInput:path parameter:parameters];
//        }else {
            return -1;
//        }
    }
    _formatCtx = formatCtx;
    return 1;
}

- (void)initAnalyzeDurationAndProbesize:(AVFormatContext *)formatCtx parameter:(NSDictionary *)parameters {
    float probeSize = [parameters[PROBE_SIZE] floatValue];
    
    formatCtx->probesize = probeSize ?:50 * 1024;
    NSArray *durations = parameters[MAX_ANALYZE_DURATION_ARRAY];
    if (durations && durations.count > _connectionRetry) {
        formatCtx->max_analyze_duration = [durations[_connectionRetry] floatValue];
    }else {
        float multiplier = 0.5 + (double)pow(2.0, (double)_connectionRetry) * 0.25;
        formatCtx->max_analyze_duration = multiplier * AV_TIME_BASE;
    }
    
    BOOL fpsProbeSizeConfiged = [parameters[FPS_PROBE_SIZE_CONFIGURED] boolValue];
    if (fpsProbeSizeConfiged) {
        formatCtx->fps_probe_size = 3;
    }
}

- (int)openFormatInput:(AVFormatContext **)formatCtx path:(NSString *)path parameter:(NSDictionary *)parameters {
    const char* videoSourceURI = [path cStringUsingEncoding: NSUTF8StringEncoding];
    AVDictionary *options = NULL;
    NSString* rtmpTcurl = parameters[RTMP_TCURL_KEY];
    if([rtmpTcurl length] > 0){
        const char *rtmp_tcurl = [rtmpTcurl cStringUsingEncoding: NSUTF8StringEncoding];
        av_dict_set(&options, "rtmp_tcurl", rtmp_tcurl, 0);
    }
    int ret = avformat_open_input(formatCtx, videoSourceURI, NULL, NULL);
    return ret;
}

- (NSArray *)decodeFrames:(CGFloat)minDuration decodeVideoErrorState:(int *)decodeVideoErrorState {
    if (_videoStreamIndex == -1 && _audioStreamIndex == -1) {
        return nil;
    }
    NSMutableArray *result = [NSMutableArray array];
    AVPacket packet;
    CGFloat decodeDuration = 0;
    BOOL finished = NO;
    while (!finished) {
        if (av_read_frame(_formatCtx, &packet) < 0) {
            _isEOF = YES;
            break;
        }
        
        int pktSize = packet.size;
        int pktStreamIndex = packet.stream_index;
        if (pktStreamIndex == _videoStreamIndex) {
            double startDecodeTimeMills = CFAbsoluteTimeGetCurrent() * 1000;
            
            VideoFrame *frame = [self decodeVideo:packet packetSize:pktSize decodeVideoErrorState:decodeVideoErrorState];
            int wasteTimeMills = CFAbsoluteTimeGetCurrent() * 1000 - startDecodeTimeMills;
            decodeVideoFrameWasteTimeMills += wasteTimeMills;
            if (frame) {
                totalVideoFramecount++;
                [result addObject:frame];
                decodeDuration += frame.duration;
                if (decodeDuration > minDuration) {
                    finished = YES;
                }
            }
        }else if (pktStreamIndex == _audioStreamIndex) {
            while (pktSize > 0) {
                int gotframe = 0;
                int len = avcodec_decode_audio4(_audioCodecCtx, _audioFrame, &gotframe, &packet);
                
                if (len < 0) {
                    NSLog(@"decode audio error, skip packet");
                    break;
                }
                
                if (gotframe) {
                    AudioFrame *frame = [self handleAudioFrame];
                    if (frame) {
                        [result addObject:frame];
                        if (_videoStreamIndex == -1) {
                            _decodePosition = frame.position;
                            decodeDuration += frame.duration;
                            if (decodeDuration > minDuration) {
                                finished = YES;
                            }
                        }
                    }
                }
                
                if (0 == len) {
                    break;
                }
                pktSize -= len;
            }
        }else {
            NSLog(@"We Can Not Process Stream Except Audio And Video Stream...");
        }
        
        av_free_packet(&packet);
    }
    
    return result;
}

- (VideoFrame *)decodeVideo:(AVPacket)packet packetSize:(int)pktSize decodeVideoErrorState:(int *)decodeVideoErrorState
{
    VideoFrame *frame = nil;
    while (pktSize > 0) {
        int gotframe = 0;
        int len = avcodec_decode_video2(_videoCodecCtx, _videoFrame, &gotframe, &packet);
        
        if (len < 0) {
            NSLog(@"decode video error, skip packet %s",av_err2str(len));
            *decodeVideoErrorState = 1;
            break;
        }
        
        if (gotframe) {
            frame = [self handleVideoFrame];
        }
        
        if (0 == len) {
            break;
        }
        pktSize -= len;
    }
    return frame;
}

- (AudioFrame *)handleAudioFrame {
    if (!_audioFrame->data[0]) {
        return nil;
    }
    
    const NSUInteger numChannels = _audioCodecCtx->channels;
    NSInteger numFrames;
    
    void *audioData;
    if (_swrContext) {
        const NSUInteger ratio = 2;
        const int bufSize = av_samples_get_buffer_size(NULL, (int)numChannels, (int)(_audioFrame->nb_samples * ratio), AV_SAMPLE_FMT_S16, 1);
        
        if (!_swrBuffer || _swrBufferSize < bufSize) {
            _swrBufferSize = bufSize;
            _swrBuffer = realloc(_swrBuffer, _swrBufferSize);
        }
        Byte *outbuf[2] = {_swrBuffer,0};
        numFrames = swr_convert(_swrContext, outbuf, (int)(_audioFrame->nb_samples * ratio), (const uint8_t **)_audioFrame->data, _audioFrame->nb_samples);
        
        if (numFrames < 0) {
            return nil;
        }
        audioData = _swrBuffer;
    }else {
        if (_audioCodecCtx->sample_fmt != AV_SAMPLE_FMT_S16) {
            return nil;
        }
        
        audioData = _audioFrame->data[0];
        numFrames = _audioFrame->nb_samples;
    }
    
    const NSUInteger numElements = numFrames * numChannels;
    NSMutableData *pcmData = [NSMutableData dataWithLength:numElements * sizeof(SInt16)];
    memcpy(pcmData.mutableBytes, audioData, numElements * sizeof(SInt16));
    AudioFrame *frame = [[AudioFrame alloc] init];
    frame.position = av_frame_get_best_effort_timestamp(_audioFrame) * _audioTimeBase;
    frame.duration = av_frame_get_pkt_duration(_audioFrame) * _audioTimeBase;
    frame.samples = pcmData;
    frame.type = AudioFrameType;
    return frame;
}

- (VideoFrame *)handleVideoFrame {
    if (!_videoFrame->data[0]) {
        return nil;
    }
    
    VideoFrame *frame = [[VideoFrame alloc] init];
    
    if (_videoCodecCtx->pix_fmt == AV_PIX_FMT_YUV420P || _videoCodecCtx->pix_fmt == AV_PIX_FMT_YUVJ420P) {
        frame.luma = copyFrameData(_videoFrame->data[0], _videoFrame->linesize[0], _videoCodecCtx->width, _videoCodecCtx->height);
        
        frame.chromaB = copyFrameData(_videoFrame->data[1], _videoFrame->linesize[1], _videoCodecCtx->width / 2, _videoCodecCtx->height/2);
        frame.chromaR = copyFrameData(_videoFrame->data[2], _videoFrame->linesize[2], _videoCodecCtx->width/2, _videoFrame->height/2);
    }else {
        if (![self setupScaler]) {
            return nil;
        }
        
        sws_scale(_swsContext, (const uint8_t **)_videoFrame->data, _videoFrame->linesize, 0, _videoCodecCtx->height, _picture.data, _picture.linesize);
        
        frame.luma = copyFrameData(_picture.data[0], _picture.linesize[0], _videoCodecCtx->width, _videoCodecCtx->height);
        
        frame.chromaB = copyFrameData(_picture.data[1], _picture.linesize[1], _videoCodecCtx->width / 2, _videoCodecCtx->height/2);
        frame.chromaR = copyFrameData(_picture.data[2], _picture.linesize[2], _videoCodecCtx->width/2, _videoFrame->height/2);
    }
    
    frame.width = _videoCodecCtx->width;
    frame.height = _videoCodecCtx->height;
    frame.linesize = _videoFrame->linesize[0];
    frame.type = VideoFrameType;
    frame.position = av_frame_get_best_effort_timestamp(_videoFrame) * _videoTimeBase;
    
    const int64_t frameDuration = av_frame_get_pkt_duration(_videoFrame);
    
    if (frameDuration) {
        frame.duration = frameDuration * _videoTimeBase;
        frame.duration += _videoFrame->repeat_pict * _videoTimeBase * 0.5;
        
    }else {
        frame.duration = 1.0 / _fps;
    }
    
    return frame;
}


- (BOOL)setupScaler {
    [self closeScaler];
    _pictureValid = avpicture_alloc(&_picture, AV_PIX_FMT_YUV420P, _videoCodecCtx->width, _videoCodecCtx->height);
    
    if (!_pictureValid) {
        return NO;
    }
    
    _swsContext = sws_getCachedContext(_swsContext, _videoCodecCtx->width, _videoCodecCtx->height, _videoCodecCtx->pix_fmt, _videoCodecCtx->width, _videoCodecCtx->height, AV_PIX_FMT_YUV420P, SWS_FAST_BILINEAR, NULL, NULL, NULL);
    
    return _swsContext != NULL;
}

- (BOOL) isNeedRetry
{
    _connectionRetry++;
    return _connectionRetry <= NET_WORK_STREAM_RETRY_TIME;
}


- (NSUInteger)frameWidth {
    return _videoCodecCtx ? _videoCodecCtx->width:0;
}
- (NSUInteger)frameHeight {
    return _videoCodecCtx ? _videoCodecCtx->height:0;
}
- (CGFloat)sampleRate {
    return _audioCodecCtx ? _audioCodecCtx->sample_rate : 0;
}
- (NSUInteger)channels {
    return _audioCodecCtx ? _audioCodecCtx->channels : 0;
}
- (BOOL)validVideo {
    return _videoStreamIndex != -1;
}
- (BOOL)validAudio {
    return _audioStreamIndex != -1;
}
- (CGFloat)getVideoFPS {
    return _fps;
}
- (CGFloat)getDuration {
    if (_formatCtx) {
        if (_formatCtx->duration == AV_NOPTS_VALUE) {
            return -1;
        }
        return _formatCtx->duration / AV_TIME_BASE;
    }
    return -1;
}

- (void)closeScaler {
    if (_swsContext) {
        sws_freeContext(_swsContext);
        _swsContext = NULL;
    }
    
    if (_pictureValid) {
        avpicture_free(&_picture);
        _pictureValid = NO;
    }
}

- (BOOL)isEOF {
    return _isEOF;
}
@end
