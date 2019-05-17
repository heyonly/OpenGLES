//
//  ViewController.m
//  Tutorial01
//
//  Created by heyonly on 2019/5/8.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "ViewController.h"
#import <libx264/x264.h>
#import <libavformat/avformat.h>
#import <libavutil/imgutils.h>
#import <libswscale/swscale.h>
#import <libavcodec/avcodec.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [self decode];
}

- (void)decode {
    AVFormatContext *pFormatCtx;
    int             i, videoIndex;
    AVCodecContext  *pCodecCtx;
    AVCodec         *pCodec;
    AVFrame         *pFrame,*pFrameYUV;
    uint8_t         *out_buffer;
    AVPacket        *packet;
    int             y_size;
    int             ret,got_picture = 0;
    struct SwsContext   *img_convert_ctx;
    FILE            *fp_yuv;
    int             frame_cnt;
    clock_t         time_start,time_finish;
    double          time_duration = 0.0;
    char            info[1024] = {0};
    AVDictionary    *options;
    
    NSString *iFilePath = [[NSBundle mainBundle] pathForResource:@"sintel.mov" ofType:nil];
    const char* input_path = [iFilePath UTF8String];
    NSString *oFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"out_put.yuv"];
    
    const char* output_path = [oFilePath UTF8String];
    
    av_register_all();
    avformat_network_init();
    pFormatCtx = avformat_alloc_context();
    
    if (avformat_open_input(&pFormatCtx, input_path, NULL, NULL) != 0) {
        NSLog(@"Couldnot open input stream.");
        return;
    }
    
    if (avformat_find_stream_info(pFormatCtx, NULL) < 0) {
        NSLog(@"Couldn't find stream information. ");
        return;
    }
    
    videoIndex = -1;
    for (i = 0; i < pFormatCtx->nb_streams; i++) {
        if (pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoIndex = i;
            break;
        }
    }
    if (videoIndex == -1) {
        NSLog(@"Couldn't find a video stream. ");
        return;
    }
    
    pCodecCtx = pFormatCtx->streams[videoIndex]->codec;
    pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    if (pCodec == NULL) {
        printf("Couldn't find Codec.\n");
        return;
    }
    
    if (avcodec_open2(pCodecCtx, pCodec, NULL) < 0) {
        printf("Couldn't open codec.\n");
        return;
    }
    
    pFrame = av_frame_alloc();
    pFrameYUV = av_frame_alloc();
    out_buffer = (unsigned char*)av_malloc(av_image_get_buffer_size(AV_PIX_FMT_YUV420P, pCodecCtx->width, pCodecCtx->height, 1));
    
    av_image_fill_arrays(pFrameYUV->data, pFrameYUV->linesize, out_buffer, AV_PIX_FMT_YUV420P, pCodecCtx->width, pCodecCtx->height, 1);
    
    packet = (AVPacket*)av_malloc(sizeof(AVPacket));
    img_convert_ctx = sws_getContext(pCodecCtx->width, pCodecCtx->height, pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height, AV_PIX_FMT_YUV420P, SWS_BICUBIC, NULL, NULL, NULL);
    
    
    sprintf(info, "%s[Input     ]%s\n",info, input_path);
    sprintf(info, "%s[Output    ]%s\n",info, output_path);
    sprintf(info, "%s[Format    ]%s\n",info, pFormatCtx->iformat->name);
    sprintf(info, "%s[Codec     ]%s\n",info, pCodecCtx->codec->name);
    sprintf(info, "%s[Resolution]%dx%d\n",info, pCodecCtx->width,pCodecCtx->height);
    
    fp_yuv = fopen(output_path, "wb+");
    if (fp_yuv == NULL) {
        printf("Could not open output file.\n");
        return;
    }
    
    frame_cnt = 0;
    time_start = clock();
    while (av_read_frame(pFormatCtx, packet) >= 0) {
        if (packet->stream_index == videoIndex) {
            ret = avcodec_decode_video2(pCodecCtx, pFrame, &got_picture, packet);
            if (ret < 0) {
                printf("Decode Error .\n");
                return;
            }
        }
        if (got_picture) {
            sws_scale(img_convert_ctx, (const uint8_t* const*)pFrame->data, pFrame->linesize, 0, pCodecCtx->height, pFrameYUV->data, pFrameYUV->linesize);
            
            y_size = pCodecCtx->width * pCodecCtx->height;
            fwrite(pFrameYUV->data[0], 1, y_size, fp_yuv);
            fwrite(pFrameYUV->data[1], 1, y_size/2, fp_yuv);
            fwrite(pFrameYUV->data[2], 1, y_size/2, fp_yuv);
            
            char pictype_str[10] = {0};
            switch (pFrameYUV->pict_type) {
                case AV_PICTURE_TYPE_I:
                    sprintf(pictype_str, "I");break;
                case AV_PICTURE_TYPE_P:
                    sprintf(pictype_str, "P");break;
                case AV_PICTURE_TYPE_B:
                    sprintf(pictype_str, "B");break;
                    break;
                    
                default:
                    break;
            }
            printf("Frame Index: %5d. Type:%s\n",frame_cnt,pictype_str);
            frame_cnt++;
        }
        av_free_packet(packet);
    }
//    while (1) {
//        ret = avcodec_decode_video2(pCodecCtx, pFrame,&got_picture, packet);
//        if (ret < 0) {
//            break;
//        }
//        if (!got_picture) {
//            break;
//        }
//        sws_scale(img_convert_ctx, (const uint8_t* const *)pFrame->data, pFrame->linesize, 0, pCodecCtx->height, pFrameYUV->data, pFrameYUV->linesize);
//
//        int y_size = pCodecCtx->width * pCodecCtx->height;
//        fwrite(pFrameYUV->data[0], 1, y_size, fp_yuv);
//        fwrite(pFrameYUV->data[1], 1, y_size/4, fp_yuv);
//        fwrite(pFrameYUV->data[2], 1, y_size/4, fp_yuv);
//
//        char pictype_str[10] = {0};
//        switch (pFrame->pict_type) {
//            case AV_PICTURE_TYPE_I:
//                sprintf(pictype_str, "I");break;
//            case AV_PICTURE_TYPE_P:
//                sprintf(pictype_str, "P");break;
//            case AV_PICTURE_TYPE_B:
//                sprintf(pictype_str, "B");break;
//                break;
//
//            default:
//                break;
//        }
//        printf("Frame Index: %5d. Type:%s\n",frame_cnt,pictype_str);
//        frame_cnt++;
//    }
    time_finish = clock();
    time_duration=(double)(time_finish - time_start);
    
    sprintf(info, "%s[Time      ]%fus\n",info,time_duration);
    sprintf(info, "%s[Count     ]%d\n",info,frame_cnt);
    
    sws_freeContext(img_convert_ctx);
    
    fclose(fp_yuv);
    
    av_frame_free(&pFrameYUV);
    av_frame_free(&pFrame);
    avcodec_close(pCodecCtx);
    avformat_close_input(&pFormatCtx);
    
    NSString * info_ns = [NSString stringWithFormat:@"%s", info];
    NSLog(@"%@",info_ns);

}
@end
