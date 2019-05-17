//
//  ViewController.m
//  Tutorial05
//
//  Created by heyonly on 2019/5/14.
//  Copyright © 2019 heyonly. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#define MAXBUFS  2
#define NUMFILES 2

const Float64 kGraphSampleRate = 44100.0; // 48000.0 optional tests

typedef struct {
    AudioStreamBasicDescription asbd;
    Float32 *data;
    UInt32 numFrames;
    UInt32 sampleNum;
} SoundBuffer, *SoundBufferPtr;


@interface ViewController ()
{
    CFURLRef sourceURL[2];
    
    AVAudioFormat *mAudioFormat;
    
    AUGraph   mGraph;
    AudioUnit mMixer;
    AudioUnit mOutput;
    
    SoundBuffer mSoundBuffer[MAXBUFS];
    
    Boolean isPlaying;
}
@end
static OSStatus renderInput(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    SoundBufferPtr sndbuf = (SoundBufferPtr)inRefCon;
    UInt32 sample = sndbuf[inBusNumber].sampleNum;
    UInt32 bufSamples = sndbuf[inBusNumber].numFrames;
    
    Float32 *in = sndbuf[inBusNumber].data;
    
    Float32 *outA = (Float32 *)ioData->mBuffers[0].mData;
    Float32 *outB = (Float32 *)ioData->mBuffers[1].mData;
    
    for (UInt32 i = 0; i < inNumberFrames; i++) {
        if (1 == inBusNumber) {
            outA[i] = 0;
            outB[i] = in[sample++];
        }else {
            outA[i] = in[sample++];
            outB[i] = 0;
        }
        if (sample > bufSamples) {
            sample = 0;
        }
    }
    
    sndbuf[inBusNumber].sampleNum = sample;
    
    return noErr;
}
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initSource];
    
    NSError *error = nil;
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    [sessionInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
    [sessionInstance setPreferredIOBufferDuration:0.005 error:&error];
    [sessionInstance setPreferredSampleRate:44100.0 error:&error];
    [sessionInstance setActive:YES error:&error];
    
    [self initializeAUGraph];
}
- (IBAction)buttonAction:(UIButton *)sender {
    if ([sender.titleLabel.text isEqualToString:@"start"]) {

        [self startAUGraph];
        [sender setTitle:@"stop" forState:UIControlStateNormal];
    }else {

        [self stopAUGraph];
        [sender setTitle:@"start" forState:UIControlStateNormal];
    }
}


- (void)initializeAUGraph {
    AUNode outputNode;
    AUNode mixerNode;
    
    mAudioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:kGraphSampleRate channels:2 interleaved:NO];
    
    OSStatus result = noErr;
    
    [self performSelectorInBackground:@selector(loadFiles) withObject:nil];
    
    result = NewAUGraph(&mGraph);
    
    AudioComponentDescription output_desc;
    output_desc.componentType = kAudioUnitType_Output;
    output_desc.componentSubType = kAudioUnitSubType_RemoteIO;
    output_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    output_desc.componentFlags = 0;
    output_desc.componentFlagsMask = 0;
    
    AudioComponentDescription mixer_desc;
    mixer_desc.componentType = kAudioUnitType_Mixer;
    mixer_desc.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    mixer_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    mixer_desc.componentFlags = 0;
    mixer_desc.componentFlagsMask = 0;
    
    result = AUGraphAddNode(mGraph, &output_desc, &outputNode);
    
    result = AUGraphAddNode(mGraph, &mixer_desc, &mixerNode);
    
    result = AUGraphConnectNodeInput(mGraph, mixerNode, 0, outputNode, 0);
    
    result = AUGraphOpen(mGraph);
    
    result = AUGraphNodeInfo(mGraph, mixerNode, NULL, &mMixer);
    
    result = AUGraphNodeInfo(mGraph, outputNode, NULL, &mOutput);
    
    UInt32 numBuses = 2;
    
    result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &numBuses, sizeof(numBuses));
    
    for (int i = 0; i < numBuses; i++) {
        AURenderCallbackStruct rcbs;
        rcbs.inputProc = &renderInput;
        rcbs.inputProcRefCon = mSoundBuffer;
        
        result = AUGraphSetNodeInputCallback(mGraph, mixerNode, i, &rcbs);
        
        result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, i, mAudioFormat.streamDescription, sizeof(AudioStreamBasicDescription));
    }
    
    result = AudioUnitSetProperty(mMixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, mAudioFormat.streamDescription, sizeof(AudioStreamBasicDescription));
    
    result = AudioUnitSetProperty(mOutput, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, mAudioFormat.streamDescription, sizeof(AudioStreamBasicDescription));
    
    result = AUGraphInitialize(mGraph);
    
    CAShow(mGraph);
}

- (void)startAUGraph {
    OSStatus status = AUGraphStart(mGraph);
    printf("AUGraphStart :%d \n",status);
}

- (void)stopAUGraph {
    
    Boolean isRunning = false;
    
    OSStatus status = AUGraphIsRunning(mGraph, &isRunning);
    if (isRunning) {
        status = AUGraphStop(mGraph);
        printf("AUGraphStop :%d \n",status);
        isPlaying = false;
    }
    
}

- (void)loadFiles {
    AVAudioFormat *clientFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:kGraphSampleRate channels:1 interleaved:YES];
    
    for (int i = 0; i < NUMFILES && i < MAXBUFS; i++) {
        ExtAudioFileRef xafref = 0;
        OSStatus result = ExtAudioFileOpenURL(sourceURL[i], &xafref);
        if (result || !xafref) {
            printf("ExtAudioFileOpenURL result %ld %08lX %4.4s\n", (long)result, (long)result, (char*)&result);
            break;
        }
        
        AudioStreamBasicDescription fileFormat;
        UInt32 propSize = sizeof(fileFormat);
        
        result = ExtAudioFileGetProperty(xafref, kExtAudioFileProperty_FileDataFormat, &propSize, &fileFormat);
        
        if (result) {
            printf("ExtAudioFileGetProperty Failed!!\n");
            break;
        }
        
        double rateRation = kGraphSampleRate / fileFormat.mSampleRate;
        
        propSize = sizeof(AudioStreamBasicDescription);
        
        result = ExtAudioFileSetProperty(xafref, kExtAudioFileProperty_ClientDataFormat, propSize, clientFormat.streamDescription);
        
        if (result) {
            printf("ExtAudioFileSetProperty Failed!!\n");
            break;
        }
        
        UInt64 numFrames = 0;
        
        propSize = sizeof(numFrames);
        
        result = ExtAudioFileGetProperty(xafref, kExtAudioFileProperty_FileLengthFrames, &propSize, &numFrames);
        
        if (result) {
            printf("ExtAudioFileGetProperty FileLengthFrames Failed!!\n");
            break;
        }
        
        numFrames = (numFrames * rateRation);
        
        mSoundBuffer[i].numFrames = (UInt32)numFrames;
        mSoundBuffer[i].asbd = *(clientFormat.streamDescription);
        
        UInt32 samples = (UInt32)numFrames * mSoundBuffer[i].asbd.mChannelsPerFrame;
        mSoundBuffer[i].data = (Float32 *)calloc(samples, sizeof(Float32));
        mSoundBuffer[i].sampleNum = 0;
        
        AudioBufferList bufList;
        bufList.mNumberBuffers = 1;
        bufList.mBuffers[0].mNumberChannels = 1;
        bufList.mBuffers[0].mData = mSoundBuffer[i].data;
        bufList.mBuffers[0].mDataByteSize = samples * sizeof(Float32);
        
        UInt32 numPackets = (UInt32)numFrames;
        result = ExtAudioFileRead(xafref, &numPackets, &bufList);
        
        if (result) {
            printf("ExtAudioFileRead Failed !!\n");
            free(mSoundBuffer[i].data);
            mSoundBuffer[i].data = 0;
        }
        
        ExtAudioFileDispose(xafref);
        
    }
}

- (void)initSource {
    isPlaying = false;
    
    // clear the mSoundBuffer struct
    memset(&mSoundBuffer, 0, sizeof(mSoundBuffer));
    
    // create the URLs we'll use for source A and B
    NSString *sourceA = [[NSBundle mainBundle] pathForResource:@"GuitarMonoSTP" ofType:@"aif"];
    NSString *sourceB = [[NSBundle mainBundle] pathForResource:@"DrumsMonoSTP" ofType:@"aif"];
    sourceURL[0] = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)sourceA, kCFURLPOSIXPathStyle, false);
    sourceURL[1] = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)sourceB, kCFURLPOSIXPathStyle, false);
}

@end
