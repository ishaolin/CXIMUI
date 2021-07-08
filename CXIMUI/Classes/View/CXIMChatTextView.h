//
//  CXIMChatTextView.h
//  Pods
//
//  Created by wshaolin on 2019/3/26.
//

#import <CXUIKit/CXUIKit.h>

@class CXIMChatTextView;

@protocol CXIMChatTextViewDelegate <UITextViewDelegate>

@optional

- (void)IMChatTextView:(CXIMChatTextView *)textView didChangeTextHeight:(CGFloat)height;

@end

@interface CXIMChatTextView : CXTextView

@property (nonatomic, weak) id<CXIMChatTextViewDelegate> delegate;
@property (nonatomic, assign) NSUInteger maximumVisibleLines; // 0表示不限制
@property (nonatomic, assign) CGFloat minimumTextHeight;

@end
