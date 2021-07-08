//
//  CXIMCameraViewController.h
//  Pods
//
//  Created by wshaolin on 2019/3/26.
//

#import <CXUIKit/CXUIKit.h>

@class CXIMCameraViewController;

typedef void(^CXIMCameraRecordCompletionBlock)(CXIMCameraViewController *VC,
                                               NSString *videoPath,
                                               NSArray<NSString *> *imagePaths);

@interface CXIMCameraViewController : CXBaseViewController

- (instancetype)initWithCompletionBlock:(CXIMCameraRecordCompletionBlock)completionBlock;

@end

NSString *CXIMImageCacheToDisk(UIImage *image, NSUInteger tag);
