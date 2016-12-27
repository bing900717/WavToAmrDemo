//
//  ViewController.h
//  AvAudioRecord-Test
//
//  Created by yaoxb on 2016/12/21.
//  Copyright © 2016年 yaoxb. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,Audio_Mode) {
    Audio_Mode_AAC,
    Audio_Mode_MP3,
    Audio_Mode_WAV
};

@interface ViewController : UIViewController

@property (nonatomic ,assign) Audio_Mode audioMode;

@end

