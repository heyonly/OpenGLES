//
//  ViewController.m
//  Tutorial02
//
//  Created by heyonly on 2019/5/9.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "ViewController.h"
#import <libavformat/avformat.h>
#import <libavutil/imgutils.h>
#import <libswscale/swscale.h>
#import <libavcodec/avcodec.h>
#include <pthread.h>


@interface ViewController ()

@end

typedef struct {
    int num;
}Buffer;


Buffer buf;
pthread_mutex_t pc_mutex;
pthread_cond_t pc_condp,pc_condc;


static void producer() {
    for (int i = 0; i < 1000; i++) {
        pthread_mutex_lock(&pc_mutex);
        while (buf.num != 0) {
            pthread_cond_wait(&pc_condp, &pc_mutex);
        }
        buf.num = i;
        printf("producer %d\n",buf.num);
        
        pthread_cond_signal(&pc_condc);
        pthread_mutex_unlock(&pc_mutex);
    }
    pthread_exit(NULL);
}

static void consumer() {
    for (int i = 1; i < 1000; i++) {
        pthread_mutex_lock(&pc_mutex);
        while (buf.num == 0) {
            pthread_cond_wait(&pc_condc, &pc_mutex);
        }
        printf("consumer %d\n",buf.num);
        buf.num = 0;
        
        pthread_cond_signal(&pc_condp);
        pthread_mutex_unlock(&pc_mutex);
    }
    pthread_exit(NULL);
}

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self decode];
    

    

    
    
    
    
    
}

- (void)decode {
    NSString *iFilePath = [[NSBundle mainBundle] pathForResource:@"sintel.mov" ofType:nil];
    const char* inputFile = [iFilePath UTF8String];
    NSString *vFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"out_put.yuv"];
    
    NSString *aFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"out_put.pcm"];
    
    const char *audioFile = [aFilePath UTF8String];
    const char *videoFile = [vFilePath UTF8String];

    av_register_all();
    avformat_network_init();
    
    int res = 0;
    int videoStream = -1;
    int audioStream  = -1;
    char errBuf[1024] = {0};
    FILE *fp_video = fopen(videoFile, "wb+");
    FILE *fp_audio = fopen(audioFile, "wb+");
    AVFormatContext *pFormatCtx = NULL;
    
    if ((res = avformat_open_input(&pFormatCtx, inputFile, NULL, NULL)) < 0) {
        av_strerror(res, errBuf, 1024);
        NSLog(@"Couldnot open input stream.");
        return;
    }
    
    avformat_find_stream_info(pFormatCtx, NULL);
    av_dump_format(pFormatCtx, 0, NULL, 0);
    for (int i = 0; i < pFormatCtx->nb_streams; i++) {
        if (pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoStream = i;
        }else if (pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO) {
            audioStream = i;
        }
    }
    
    if (videoStream == -1) {
        printf("Didn't find a video stream.\n");
        return;
    }
    if (audioStream == -1) {
        printf("Didn't find a audio stream.\n");
        return;
    }
    
    AVCodecContext *pVideoCodecCtx = pFormatCtx->streams[videoStream]->codec;
    AVCodec *pVideoCodec = avcodec_find_decoder(pVideoCodecCtx->codec_id);
    if (pVideoCodec == NULL) {
        printf("Video Codec not found.\n");
        return;
    }
    AVCodecContext *pAudioCodecCtx = pFormatCtx->streams[audioStream]->codec;
    AVCodec *pAudioCodec = avcodec_find_decoder(pAudioCodecCtx->codec_id);
    
    if (pAudioCodec == NULL) {
        printf("Audio Codec not found.\n");
        return;
    }
    
    if (avcodec_open2(pVideoCodecCtx, pVideoCodec, NULL) < 0) {
        printf("Could not open Video codec.\n");
        return;
    }
    
    if (avcodec_open2(pAudioCodecCtx, pAudioCodec, NULL) < 0) {
        printf("Could not open Audio codec.\n");
        return;
    }
    
    AVFrame *frame = av_frame_alloc();
    AVPacket *packet = av_packet_alloc();
    
    int got_picture;
    while (1) {
        if (av_read_frame(pFormatCtx, packet) < 0) {
            break;
        }
        
        if (packet->stream_index == videoStream) {
            if (avcodec_decode_video2(pVideoCodecCtx, frame, &got_picture, packet) < 0) {
                printf("decode Video error.\n");
                return;
            }
            
            if (got_picture) {
                if (frame->format == AV_PIX_FMT_YUV420P) {
                    fwrite(frame->data[0], 1, frame->linesize[0] * frame->height, fp_video);
                    fwrite(frame->data[1], 1, frame->linesize[1] * frame->height/2, fp_video);
                    fwrite(frame->data[2], 1, frame->linesize[2] * frame->height/2, fp_video);
                }
            }
        }else if (packet->stream_index == audioStream) {
            if (avcodec_decode_audio4(pAudioCodecCtx, frame, &got_picture, packet) < 0) {
                printf("decode Audio error.\n");
                return;
            }
            
            if (got_picture) {
                if (frame->format == AV_SAMPLE_FMT_S16) {
                    for (int i = 0; i < frame->linesize[0]; i++) {
                        for (int j = 0; j < frame->channels; j++) {
                            fwrite(frame->data[j] + i, 2, 1, fp_audio);
                        }
                    }
                }else if (frame->format == AV_SAMPLE_FMT_FLTP) {
                    for (int i = 0; i < frame->linesize[0]; i++) {
                        for (int j = 0; j < frame->channels; j++) {
                            fwrite(frame->data[j] + i, 4, 1, fp_audio);
                        }
                    }
                }
            }
        }
        av_free_packet(packet);
    }
    fclose(fp_video);
    fclose(fp_audio);
    avcodec_close(pVideoCodecCtx);
    avcodec_close(pAudioCodecCtx);
    avformat_close_input(&pFormatCtx);
    NSLog(@"finished!!");
    return;
}


- (void)setupConsumerAndProducer {
    pthread_t thread[2];
    pthread_attr_t attr;
    buf.num = 0;
    
    pthread_mutex_init(&pc_mutex, NULL);
    pthread_cond_init(&pc_condp, NULL);
    pthread_cond_init(&pc_condc, NULL);
    
    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);
    
    
    pthread_create(&thread[0], &attr, (void*)producer, NULL);
    
    pthread_create(&thread[1], &attr, (void*)consumer, NULL);
    
    //    pthread_join(thread[0], NULL);
    //    pthread_join(thread[1], NULL);
    
    pthread_mutex_destroy(&pc_mutex);
    pthread_cond_destroy(&pc_condc);
    pthread_cond_destroy(&pc_condp);
    pthread_attr_destroy(&attr);
    
    //    pthread_exit(NULL);
}
@end
