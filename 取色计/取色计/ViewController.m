//
//  ViewController.m
//  取色计
//
//  Created by 陈伟杰 on 2018/12/14.
//  Copyright © 2018年 陈伟杰. All rights reserved.
//

#import "ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

#define kwidth [UIScreen mainScreen].bounds.size.width
#define kheight [UIScreen mainScreen].bounds.size.height
@interface ViewController ()<AVCapturePhotoCaptureDelegate>
{
    CAShapeLayer *_maskLayer;
}
@property(nonatomic,strong)AVCaptureSession *session;
@property(nonatomic,strong)AVCaptureDevice *device;
@property(nonatomic,strong)AVCapturePhotoSettings *outputSettings;
@property(nonatomic,strong)AVCaptureDeviceInput *deviceInput;
@property(nonatomic,strong)AVCapturePhotoOutput *photoOutput;
@property(nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;
@property(nonatomic,strong)UIButton *signInBtn;
@property(nonatomic,strong)UIView *littleView;
@property(nonatomic,strong)UIView *view1;
@property(nonatomic,strong)UIView *view2;
@property(nonatomic,strong)UIView *view3;
@property(nonatomic,strong)UIView *view4;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpUI];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.session startRunning];
    //    [self loopline];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.session stopRunning];
}

#pragma mark private method
- (void)setUpUI{
    if ([self.session canAddInput:self.deviceInput]) {
        [self.session addInput:self.deviceInput];
    }
    
    [self.photoOutput setPhotoSettingsForSceneMonitoring:self.outputSettings];
    [self.session addOutput:self.photoOutput];
    [self.view.layer addSublayer:self.previewLayer];
    
    [self.view addSubview:self.signInBtn];
    [self.view addSubview:self.littleView];
    [self.view addSubview:self.view1];
    [self.view addSubview:self.view2];
    [self.view addSubview:self.view3];
    [self.view addSubview:self.view4];
}

- (AVCaptureDevice*)cameraWithPosition:(AVCaptureDevicePosition)position{
    AVCaptureDeviceDiscoverySession *deviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
    NSArray *deviceArray = deviceDiscoverySession.devices;
    for (AVCaptureDevice *device in deviceArray) {
        if (device.position == position) {
            return  device;
        }
    }
    return nil;
}

- (UIColor*)getPixelColorAtLocation:(CGPoint)point withImage:(UIImage*)image{
    UIColor *color = nil;
    CGImageRef inImage = image.CGImage;
    CGContextRef cgctx = [self createARGBBitmapContextFromImage:inImage];
    if (cgctx == NULL) {
        return nil;
    }
    size_t w = CGImageGetWidth(inImage);
    size_t h = CGImageGetHeight(inImage);
    CGRect rect = {
        {0,0},{w,h}
    };
    CGContextDrawImage(cgctx, rect, inImage);
    unsigned char* data = CGBitmapContextGetData(cgctx);
    if (data!=NULL) {
        int offset = 4*((w*round(point.y))+round(point.x));
        NSLog(@"offset:%d %f %f",offset,point.x,point.y);
        
        int alpha = data[offset];
        int red = data[offset+1];
        int green = data[offset+2];
        int blue = data[offset+3];
        [self.signInBtn setTitle:[NSString stringWithFormat:@"colors:RGBA %i %i %i %i",red,green,blue,alpha] forState:UIControlStateNormal];
        NSLog(@"offset:%i colors:RGB A %i %i %i %i",offset,red,green,blue,alpha);
        color = [UIColor colorWithRed:(red/255.0f) green:(green/255.0f) blue:(blue/255.0f) alpha:(alpha/255.0f)];
    }
    return color;
}

-(CGContextRef)createARGBBitmapContextFromImage:(CGImageRef)inImage{
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    void* bitmapData;
    int bitmapByteCount;
    int bitmapBytesPerRow;
    size_t pixelsWide = CGImageGetWidth(inImage);
    size_t pixelsHigh = CGImageGetHeight(inImage);
    bitmapBytesPerRow = (pixelsWide*4);
    bitmapByteCount = bitmapBytesPerRow*pixelsHigh;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (colorSpace == NULL) {
        fprintf(stderr, "Error allocating color spacen");
        return NULL;
    }
    
    bitmapData = malloc(bitmapByteCount);
    if (bitmapData == NULL) {
        fprintf(stderr, "Memory not allocated!");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    
    context = CGBitmapContextCreate(bitmapData, pixelsWide, pixelsHigh,8,bitmapBytesPerRow, colorSpace, kCGImageAlphaPremultipliedFirst);
    if (context == NULL) {
        free(bitmapData);
        fprintf(stderr, "Context not created");
    }
    CGColorSpaceRelease(colorSpace);
    
    return context;
}


#pragma mark click
- (void)clickSignIn{
    
    NSDictionary *setDic = @{AVVideoCodecKey:AVVideoCodecTypeJPEG};
    AVCapturePhotoSettings* outputSettings = [AVCapturePhotoSettings photoSettingsWithFormat:setDic];
    [self.photoOutput capturePhotoWithSettings:outputSettings delegate:self];
}

#pragma mark AVCapturePhotoCaptureDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error{
    NSData *data = [photo fileDataRepresentation];
    UIImage *image = [UIImage imageWithData:data];
    UIGraphicsBeginImageContext([UIScreen mainScreen].bounds.size);
    [image drawInRect:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
   
    self.signInBtn.backgroundColor = [self getPixelColorAtLocation:CGPointMake([UIScreen mainScreen].bounds.size.width/2.0, [UIScreen mainScreen].bounds.size.height/2.0) withImage:newImage];

}

#pragma mark lazy load
-(AVCaptureSession *)session{
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        _session.sessionPreset = AVCaptureSessionPresetHigh;
    }
    return _session;
}

-(AVCaptureDevice *)device{
    if (!_device) {
        _device = [self cameraWithPosition:AVCaptureDevicePositionBack];
    }
    return _device;
}

-(AVCapturePhotoSettings *)outputSettings{
    if (!_outputSettings) {
        NSDictionary *setDic = @{AVVideoCodecKey:AVVideoCodecTypeJPEG};
        _outputSettings = [AVCapturePhotoSettings photoSettingsWithFormat:setDic];
    }
    return _outputSettings;
}
-(AVCaptureDeviceInput *)deviceInput{
    if (!_deviceInput) {
        _deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:nil];
    }
    return _deviceInput;
}

- (AVCapturePhotoOutput *)photoOutput{
    if (!_photoOutput) {
        _photoOutput = [[AVCapturePhotoOutput alloc] init];
    }
    return _photoOutput;
}

-(AVCaptureVideoPreviewLayer *)previewLayer{
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [_previewLayer setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    }
    return _previewLayer;
}

-(UIButton *)signInBtn{
    if (!_signInBtn) {
        _signInBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _signInBtn.frame = CGRectMake(15, [UIScreen mainScreen].bounds.size.height-50-15-(([UIScreen mainScreen].bounds.size.height>736)?88:64), self.view.frame.size.width-30, 50);
        _signInBtn.layer.cornerRadius = 5;
        _signInBtn.backgroundColor = [UIColor colorWithRed:0.19 green:0.65 blue:0.92 alpha:1.00];
        [_signInBtn setTitle:@"获取颜色值" forState:UIControlStateNormal];
        [_signInBtn addTarget:self action:@selector(clickSignIn) forControlEvents:UIControlEventTouchUpInside];
    }
    return _signInBtn;
}

-(UIView *)littleView{
    if (!_littleView) {
        _littleView = [[UIView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2.0, [UIScreen mainScreen].bounds.size.height/2.0, 1, 1)];
        _littleView.backgroundColor = [UIColor redColor];
    }
    return _littleView;
}

-(UIView *)view1{
    if (!_view1) {
        _view1 = [[UIView alloc] initWithFrame:CGRectMake(kwidth/2.0-20-50, kheight/2.0, 50, 1)];
        _view1.backgroundColor = [UIColor redColor];
    }
    return _view1;
}

-(UIView *)view2{
    if (!_view2) {
        _view2 = [[UIView alloc] initWithFrame:CGRectMake(kwidth/2.0, kheight/2.0-20-50, 1, 50)];
        _view2.backgroundColor = [UIColor redColor];
    }
    return _view2;
}

-(UIView *)view3{
    if (!_view3) {
        _view3 = [[UIView alloc] initWithFrame:CGRectMake(kwidth/2.0+20, kheight/2.0, 50, 1)];
        _view3.backgroundColor = [UIColor redColor];
    }
    return _view3;
}

-(UIView *)view4{
    if (!_view4) {
        _view4 = [[UIView alloc] initWithFrame:CGRectMake(kwidth/2.0, kheight/2.0+20, 1, 50)];
        _view4.backgroundColor = [UIColor redColor];
    }
    return _view4;
}

@end
