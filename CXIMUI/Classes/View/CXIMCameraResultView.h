//
//  CXIMCameraResultView.h
//  Pods
//
//  Created by wshaolin on 2019/3/26.
//

#import <UIKit/UIKit.h>

@interface CXIMCameraResultView : UIView

- (void)setRecordVideoPath:(NSString *)videoPath
                coverImage:(UIImage *)coverImage;

- (void)willResignActive;

- (void)didBecomeActive;

- (void)willEnterForeground;

- (void)reset;

@end
