//
//  CXIMCameraControlView.h
//  Pods
//
//  Created by wshaolin on 2019/3/26.
//

#import <UIKit/UIKit.h>

#define CX_VIDEO_RECORD_MAX_DURATION 10.0

@class CXIMCameraControlView;

@protocol CXIMCameraControlViewDelegate <NSObject>

@optional

- (void)IMCameraControlViewDidResetAction:(CXIMCameraControlView *)controlView;
- (void)IMCameraControlViewDidAlbumAction:(CXIMCameraControlView *)controlView;
- (void)IMCameraControlViewDidCancelAction:(CXIMCameraControlView *)controlView;
- (void)IMCameraControlViewDidSelectAction:(CXIMCameraControlView *)controlView;

- (void)IMCameraControlViewDidTakePictureAction:(CXIMCameraControlView *)controlView;
- (void)IMCameraControlViewWillRecordVideoAction:(CXIMCameraControlView *)controlView;
- (void)IMCameraControlViewDidRecordVideoAction:(CXIMCameraControlView *)controlView;

@end

@interface CXIMCameraControlView : UIView

@property (nonatomic, weak) id<CXIMCameraControlViewDelegate> delegate;

- (void)recordFinished;

@end
