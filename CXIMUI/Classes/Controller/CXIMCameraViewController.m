//
//  CXIMCameraViewController.m
//  Pods
//
//  Created by wshaolin on 2019/3/26.
//

#import "CXIMCameraViewController.h"
#import <TXRTMPSDK/TXUGCRecord.h>
#import <CXAssetsPicker/CXAssetsPicker.h>
#import "CXIMCameraControlView.h"
#import "CXIMCameraResultView.h"
#import "CXIMImageDefines.h"
#import <CXIMSDK/CXIMFileUtils.h>

static inline UIImageOrientation CXUIImageOrientationFromDeviceOrientation(UIDeviceOrientation deviceOrientation){
    switch (deviceOrientation) {
        case UIDeviceOrientationLandscapeLeft:
            return UIImageOrientationLeft;
        case UIDeviceOrientationLandscapeRight:
            return UIImageOrientationRight;
        case UIDeviceOrientationPortraitUpsideDown:
            return UIImageOrientationDown;
        default:
            return UIImageOrientationUp;
    }
}

@interface CXIMCameraViewController () <CXAnimatedTransitioningSupportor, TXVideoRecordListener, CXIMCameraControlViewDelegate, CXAssetsPickerControllerDelegate, UINavigationControllerDelegate> {
    UIView *_preview;
    UIActivityIndicatorView *_indicatorView;
    CXIMCameraControlView *_controlView;
    CXIMCameraResultView *_resultView;
    UIButton *_switchCameraButton;
    
    NSArray<NSString *> *_imagePaths;
    NSString *_videoPath;
    UIImage *_coverImage;
    UIDeviceOrientation _deviceOrientation;
    BOOL _recordVideo;
}

@property (nonatomic, copy) CXIMCameraRecordCompletionBlock completionBlock;
@property (nonatomic, weak) CXAssetsPickerController *assetsPickerController;

@end

@implementation CXIMCameraViewController

- (CXAnimatedTransitioningStyle)animatedTransitioningStyle{
    return CXAnimatedTransitioningStyleCoverVertical;
}

- (instancetype)initWithCompletionBlock:(CXIMCameraRecordCompletionBlock)completionBlock{
    if(self = [super init]){
        self.completionBlock = completionBlock;
    }
    
    return self;
}

- (void)willResignActiveNotification:(NSNotification *)notification{
    [_resultView willResignActive];
}

- (void)didEnterBackgroundNotification:(NSNotification *)notification{
    if(self.assetsPickerController){
        return;
    }
    
    if(CXStringIsEmpty(_videoPath) && CXArrayIsEmpty(_imagePaths)){
        [self dismissAnimated:NO completion:nil];
    }
}

- (void)willEnterForegroundNotification:(NSNotification *)notification{
    [_resultView willEnterForeground];
}

- (void)didBecomeActiveNotification:(NSNotification *)notification{
    [_resultView didBecomeActive];
}

- (void)audioSessionInterruptionNotification:(NSNotification*)notification{
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if(type == AVAudioSessionInterruptionTypeBegan) {
        if(@available(iOS 10.3, *)){
            if([info objectForKey:AVAudioSessionInterruptionWasSuspendedKey]){
                return;
            }
        }
        
        [_resultView willResignActive];
    }else{
        AVAudioSessionInterruptionOptions options = [info[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
        if(options == AVAudioSessionInterruptionOptionShouldResume){
            [_resultView didBecomeActive];
        }
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [TXUGCRecord shareInstance].recordDelegate = self;
    self.navigationBar.hidden = YES;
    
    _preview = [[UIView alloc] init];
    _preview.backgroundColor = [UIColor blackColor];
    _preview.frame = self.view.bounds;
    [self.view addSubview:_preview];
    
    _switchCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_switchCameraButton setImage:CX_IMUI_IMAGE(@"im_camera_switch") forState:UIControlStateNormal];
    [_switchCameraButton addTarget:self action:@selector(handleActionForSwitchCameraButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_switchCameraButton];
    CGFloat switchCameraButton_W = 35.0;
    CGFloat switchCameraButton_H = 44.0;
    CGFloat switchCameraButton_X = CGRectGetWidth(self.view.bounds) - switchCameraButton_W - 15.0;
    CGFloat switchCameraButton_Y = CGRectGetHeight(self.navigationBar.frame) - switchCameraButton_H;
    _switchCameraButton.frame = (CGRect){switchCameraButton_X, switchCameraButton_Y, switchCameraButton_W, switchCameraButton_H};
    
    _resultView = [[CXIMCameraResultView alloc] init];
    _resultView.frame = self.view.bounds;
    [self.view addSubview:_resultView];
    
    _controlView = [[CXIMCameraControlView alloc] init];
    _controlView.delegate = self;
    [self.view addSubview:_controlView];
    CGFloat controlView_W = CGRectGetWidth(self.view.bounds);
    CGFloat controlView_H = 171.0;
    CGFloat controlView_X = 0;
    CGFloat controlView_Y = CGRectGetHeight(self.view.bounds) - controlView_H - [UIScreen mainScreen].cx_safeAreaInsets.bottom;
    _controlView.frame = (CGRect){controlView_X, controlView_Y, controlView_W, controlView_H};
    
    _indicatorView = [CXSystemAdapter largeActivityIndicatorView];
    [self.view addSubview:_indicatorView];
    CGFloat indicatorView_W = _indicatorView.bounds.size.width;
    CGFloat indicatorView_H = _indicatorView.bounds.size.height;
    CGFloat indicatorView_X = (CGRectGetWidth(self.view.bounds) - indicatorView_W) * 0.5;
    CGFloat indicatorView_Y = (CGRectGetMinY(_controlView.frame) - indicatorView_H - [UIScreen mainScreen].cx_safeAreaInsets.top) * 0.5;
    _indicatorView.frame = (CGRect){indicatorView_X, indicatorView_Y, indicatorView_W, indicatorView_H};
    
    [NSNotificationCenter addObserver:self
                               action:@selector(audioSessionInterruptionNotification:)
                                 name:AVAudioSessionInterruptionNotification];
    
    [self checkVideoAuthorization];
}

- (void)checkVideoAuthorization{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusAuthorized:{
            [self checkAudioAuthorization];
        }
            break;
        case AVAuthorizationStatusNotDetermined:{
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if(!granted){
                    return;
                }
                
                [CXDispatchHandler asyncOnMainQueue:^{
                    [self checkAudioAuthorization];
                }];
            }];
        }
            break;
        case AVAuthorizationStatusRestricted:
        case AVAuthorizationStatusDenied:{
            [CXAlertControllerUtils showAlertWithConfigBlock:^(CXAlertControllerConfigModel *config) {
                config.title = @"您无相册访问权限";
                config.message = [NSString stringWithFormat:@"请打开系统设置中“隐私->相机”，允许“%@”访问您的相机。", [NSBundle mainBundle].cx_appName];
            } completion:^(NSUInteger buttonIndex) {
                [CXAppUtil openOSSettingPage];
            }];
        }
            break;
        default:
            break;
    }
}

- (void)checkAudioAuthorization{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                
            }];
        }
            break;
        case AVAuthorizationStatusRestricted:
        case AVAuthorizationStatusDenied:{
            [CXAlertControllerUtils showAlertWithConfigBlock:^(CXAlertControllerConfigModel *config) {
                config.title = @"您无麦克风权限";
                config.message = [NSString stringWithFormat:@"请打开系统设置中“隐私->麦克风”，允许“%@”访问您的麦克风。", [NSBundle mainBundle].cx_appName];
            } completion:nil];
        }
            break;
        default:
            break;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [_indicatorView startAnimating];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [_indicatorView stopAnimating];
    
    TXUGCSimpleConfig *config = [[TXUGCSimpleConfig alloc] init];
    config.videoQuality = VIDEO_QUALITY_MEDIUM;
    config.frontCamera = _switchCameraButton.isSelected;
    [[TXUGCRecord shareInstance] startCameraSimple:config preview:_preview];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[TXUGCRecord shareInstance] stopCameraPreview];
}

- (void)handleActionForSwitchCameraButton:(UIButton *)switchCameraButton{
    CXDataRecord(@"30000138");
    
    switchCameraButton.selected = !switchCameraButton.isSelected;
    [[TXUGCRecord shareInstance] switchCamera:switchCameraButton.isSelected];
    switchCameraButton.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        switchCameraButton.userInteractionEnabled = YES;
    });
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion{
    if(self.completionBlock){
        self.completionBlock(self, _videoPath, _imagePaths);
    }
    
    [self.navigationController popViewControllerAnimated:animated];
}

- (void)resetCameraState{
    _videoPath = nil;
    _coverImage = nil;
    _imagePaths = nil;
}

#pragma mark - CXIMCameraControlViewDelegate

- (void)IMCameraControlViewDidCancelAction:(CXIMCameraControlView *)controlView{
    [self resetCameraState];
    
    [self dismissAnimated:YES completion:nil];
}

- (void)IMCameraControlViewDidAlbumAction:(CXIMCameraControlView *)controlView{
    CXAssetsPickerController *assetsPickerController = [[CXAssetsPickerController alloc] initWithAssetsType:CXAssetsPhoto];
    assetsPickerController.delegate = self;
    assetsPickerController.enableMaximumCount = 9;
    assetsPickerController.finishDismissViewController = NO;
    
    [self presentViewController:assetsPickerController animated:YES completion:NULL];
    self.assetsPickerController = assetsPickerController;
}

- (void)IMCameraControlViewDidResetAction:(CXIMCameraControlView *)controlView{
    CXDataRecord(@"30000114");
    
    [self resetCameraState];
    [_resultView reset];
}

- (void)IMCameraControlViewDidSelectAction:(CXIMCameraControlView *)controlView{
    CXDataRecord(@"30000115");
    
    if(CXStringIsEmpty(_videoPath)){
        [_coverImage cx_writeToSavedPhotosAlbum:nil completion:nil];
    }else{
        if(UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(_videoPath)){
            UISaveVideoAtPathToSavedPhotosAlbum(_videoPath, nil, nil, NULL);
        }
    }
    
    [_resultView reset];
    [self dismissAnimated:YES completion:nil];
}

- (void)IMCameraControlViewDidTakePictureAction:(CXIMCameraControlView *)controlView{
    CXDataRecordX(@"30000113", @{@"source" : @{@"photo" : @(1)}});
    
    _recordVideo = NO;
    _deviceOrientation = CXDeviceOrientationFromDeviceMotion([CXMotionManager sharedManager].motion);
    [[TXUGCRecord shareInstance] startRecord];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[TXUGCRecord shareInstance] stopRecord];
    });
}

- (void)IMCameraControlViewWillRecordVideoAction:(CXIMCameraControlView *)controlView{
    CXDataRecordX(@"30000113", @{@"source" : @{@"photo" : @(0)}});
    
    _recordVideo = YES;
    [[TXUGCRecord shareInstance] startRecord];
}

- (void)IMCameraControlViewDidRecordVideoAction:(CXIMCameraControlView *)controlView{
    [[TXUGCRecord shareInstance] stopRecord];
}

- (void)assetsPickerController:(CXAssetsPickerController *)assetsPickerController didFinishPickingAssets:(NSArray<PHAsset *> *)assets assetsType:(CXAssetsType)assetsType{
    [CXHUD showHUD];
    [CXAssetsImageManager requestImageDataForAssets:assets completion:^(NSArray<CXAssetsElementImage *> *images) {
        [CXHUD dismiss];
        NSMutableArray <NSString *>*imagePaths = [NSMutableArray array];
        [images enumerateObjectsUsingBlock:^(CXAssetsElementImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *imagePath = CXIMImageCacheToDisk(obj.image, idx);
            if(!CXStringIsEmpty(imagePath)){
                [imagePaths addObject:imagePath];
            }
        }];
        
        self->_videoPath = nil;
        self->_imagePaths = imagePaths.copy;
        [self dismissAnimated:NO completion:nil];
        [assetsPickerController dismissViewControllerAnimated:YES completion:NULL];
    }];
}

- (void)assetsPickerController:(CXAssetsPickerController *)assetsPickerController didSelectCountReachedEnableMaximumCount:(NSUInteger)enableMaximumCount{
    [CXHUD showMsg:[NSString stringWithFormat:@"最多选择%@张图片", @(enableMaximumCount)]];
}

- (void)onRecordComplete:(TXRecordResult *)result{
    if([UIApplication sharedApplication].applicationState != UIApplicationStateActive){
        [self resetCameraState];
        return;
    }
    
    if(result.retCode == RECORD_RESULT_FAILED){
        [self resetCameraState];
        [CXHUD showMsg:@"拍摄失败"];
    }else{
        if(_recordVideo){
            _videoPath = result.videoPath;
            _coverImage = result.coverImage;
        }else{
            UIImageOrientation imageOrientation = CXUIImageOrientationFromDeviceOrientation(_deviceOrientation);
            _coverImage = [CXImageUtil rotateImageOrientationToUp:result.coverImage orientation:imageOrientation];
        }
        
        NSString *imagePath = CXIMImageCacheToDisk(_coverImage, 0);
        if(!CXStringIsEmpty(imagePath)){
            _imagePaths = @[imagePath];
        }
    }
    
    [_controlView recordFinished];
    [_resultView setRecordVideoPath:_videoPath coverImage:_coverImage];
}

- (void)dealloc{
    [TXUGCRecord shareInstance].recordDelegate = nil;
    [[TXUGCRecord shareInstance] stopCameraPreview];
    [NSNotificationCenter removeObserver:self];
}

@end

NSString *CXIMImageCacheToDisk(UIImage *image, NSUInteger tag){
    if(!image){
        return nil;
    }
    
    NSString *imageName = CXCreateCacheFileName([NSString stringWithFormat:@"_%@.jpg", @(tag)]);
    NSString *imagePath = CX_IM_IMAGE_PATH_GET(imageName);
    NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
    if([[NSFileManager defaultManager] createFileAtPath:imagePath contents:imageData attributes:nil]){
        return imagePath;
    }
    
    return nil;
}
