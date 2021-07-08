//
//  CXIMImageDefines.m
//  Pods
//
//  Created by wshaolin on 2019/4/11.
//

#import "CXIMImageDefines.h"

void CXImageWriteToSavedPhotosAlbum(UIImage *image){
    if(!image){
        return;
    }
    
    [image cx_writeToSavedPhotosAlbum:^(PHAuthorizationStatus status, CXPhotosAlbumAuthorizeResultBlock authorizeResultBlock) {
        if(status == PHAuthorizationStatusNotDetermined){
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus _status) {
                if(_status != PHAuthorizationStatusAuthorized){
                    return;
                }
                
                [CXDispatchHandler asyncOnMainQueue:^{
                    authorizeResultBlock(YES);
                }];
            }];
        }else if(status == PHAuthorizationStatusAuthorized){
            authorizeResultBlock(YES);
        }else{
            [CXAlertControllerUtils showAlertWithConfigBlock:^(CXAlertControllerConfigModel *config) {
                config.title = @"您无相册访问权限";
                config.message = [NSString stringWithFormat:@"请打开系统设置中“设置->隐私”，允许“%@”读取和写入您的照片。", [NSBundle mainBundle].cx_appName];
                config.buttonTitles = @[@"取消", @"去设置"];
            } completion:^(NSUInteger buttonIndex) {
                if(buttonIndex == 1){
                    [CXAppUtil openOSSettingPage];
                }
            }];
            authorizeResultBlock(NO);
        }
    } completion:^(NSError *error) {
        if(error){
            [CXHUD showMsg:@"图片保存失败"];
        }else{
            [CXHUD showMsg:@"已保存至相册"];
        }
    }];
}
