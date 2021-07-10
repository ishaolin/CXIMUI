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
                config.title = [NSString stringWithFormat:@"应用“%@”没有相册访问权限", [NSBundle mainBundle].cx_displayName];
                config.buttonTitles = @[@"取消", @"去授权"];
            } completion:^(NSUInteger buttonIndex) {
                if(buttonIndex == 1){
                    [CXAppUtils openSettingsPage];
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
