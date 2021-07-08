//
//  CXIMChatToolbar.h
//  Pods
//
//  Created by wshaolin on 2019/3/26.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CXIMChangeType){
    CXIMChangeTypeKeyboardShow,
    CXIMChangeTypeKeyboardHide,
    CXIMChangeTypeTextChanged
};

@class CXIMChatToolbar;

@protocol CXIMChatToolbarDelegate <NSObject>

@optional

- (void)IMChatToolbar:(CXIMChatToolbar *)chatToolbar sendText:(NSString *)text;

- (void)IMChatToolbar:(CXIMChatToolbar *)chatToolbar didChangeFrame:(CGRect)frame changeType:(CXIMChangeType)changeType;

- (void)IMChatToolbarActionForSelectPhoto:(CXIMChatToolbar *)chatToolbar;

@end

@interface CXIMChatToolbar : UIView

@property (nonatomic, weak) id<CXIMChatToolbarDelegate> delegate;
@property (nonatomic, assign) CGFloat minimumHeight;

@end
