//
//  ViewController.m
//  AvAudioRecord-Test
//
//  Created by yaoxb on 2016/12/21.
//  Copyright © 2016年 yaoxb. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "EMVoiceConverter.h"
#define filePath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"sound"]

@interface ViewController ()<AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAudioRecorder *recorder;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSInteger length;
@property (weak, nonatomic) IBOutlet UILabel *fileSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *audioLength;
@property (weak, nonatomic) IBOutlet UILabel *modeLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)stopRecording:(id)sender {

    [self.timer invalidate];
    [self.recorder stop];
    [self getFileSize];
}

- (IBAction)play:(id)sender {
    
    NSString *sourceFilePath = [self amrFilePath];
    NSString *resultFilePath = [filePath stringByAppendingString:@"wav_amr.wav"];
    [EMVoiceConverter amrToWav:sourceFilePath wavSavePath:resultFilePath];

    
    NSError *error = nil;
    NSError *setCategoryError = nil;
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &setCategoryError];
    if (setCategoryError){
        NSLog(@"Error setting category! %@", setCategoryError);
    }
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:resultFilePath] error:&error];
    self.audioPlayer.volume = 1.0f;


    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
    
    
}

- (IBAction)startRecording
{
    [self.recorder stop];
    
    NSInteger mode;
    switch (self.audioMode) {
        case Audio_Mode_AAC:
            mode = kAudioFormatMPEG4AAC;
            break;
            case Audio_Mode_MP3:
            mode = kAudioFormatMPEGLayer3;
            break;
            case Audio_Mode_WAV:
            mode = kAudioFormatLinearPCM;
            break;
        default:
            break;
    }
    
    //设置文件名和录音路径
//    _recordFilePath = [RMTAudioHelper genAudioFileFullPath:fileName withSuffix:cWav];
    NSDictionary *recordSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    [NSNumber numberWithFloat: 8000.0],AVSampleRateKey, //采样率
                                    [NSNumber numberWithInteger: mode],AVFormatIDKey,
                                    [NSNumber numberWithInt:8],AVLinearPCMBitDepthKey,//采样位数 默认 16
                                    [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,//通道的数目
                                    //                                   [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,//大端还是小端 是内存的组织方式
                                    //                                   [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,//采样信号是整数还是浮点数
                                    //                                   [NSNumber numberWithInt: AVAudioQualityMedium],AVEncoderAudioQualityKey,//音频编码质量
                                    nil];
    
    
    

    
    NSString *filePath_IN = [self audioFilePath];
    
    //初始化录音
    AVAudioRecorder *temp = [[AVAudioRecorder alloc]initWithURL:[NSURL URLWithString:filePath_IN]
                                                       settings:recordSettings
                                                          error:nil];
    self.recorder = temp;
    self.recorder.delegate = self;
    _recorder.meteringEnabled = YES;
    [self.recorder prepareToRecord];
    //开始录音
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [self.recorder record];
    
    [self.timer invalidate];
    self.timer = nil;
    __weak typeof(self) weakself = self;
    __block NSInteger time = 0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        time++;
        weakself.audioLength.text = [@(time).stringValue stringByAppendingString:@"s"];
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *sourceFilePath = [self audioFilePath];
        NSString *resultFilePath = [self amrFilePath];
        [EMVoiceConverter wavToAmr:sourceFilePath amrSavePath:resultFilePath];
        [self stopRecording:nil];
    });
}


- (void)getFileSize
{
   unsigned long long size = [[[NSFileManager defaultManager] attributesOfItemAtPath:[self amrFilePath] error:nil] fileSize];
    NSString *sizeStr = [self transformedValue:@(size)];
    self.fileSizeLabel.text = sizeStr;
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error
{
    
}


- (id)transformedValue:(id)value
{
    
    double convertedValue = [value doubleValue];
    int multiplyFactor = 0;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"bytes",@"KB",@"MB",@"GB",@"TB",@"PB", @"EB", @"ZB", @"YB",nil];
    
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%4.2f %@",convertedValue, [tokens objectAtIndex:multiplyFactor]];
}

- (NSString *)audioFilePath
{
    switch (self.audioMode) {
        case Audio_Mode_AAC:{
            
            return [filePath stringByAppendingString:@".m4a"];
            break;
        }
            
        case Audio_Mode_WAV:{
            return [filePath stringByAppendingString:@".wav"];
            break;
        }
            
            case Audio_Mode_MP3:
        {
            return [filePath stringByAppendingString:@".mp3"];
            break;
        }
    }
}

- (NSString *)amrFilePath
{
    switch (self.audioMode) {
        case Audio_Mode_AAC:{
            
            return [filePath stringByAppendingString:@"m4a.amr"];
            break;
        }
            
        case Audio_Mode_WAV:{
            return [filePath stringByAppendingString:@"wav.amr"];
            break;
        }
            
        case Audio_Mode_MP3:
        {
            return [filePath stringByAppendingString:@"mp3.amr"];
            break;
        }
    }
  
}

@end
