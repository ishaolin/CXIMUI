//
//  CXIMChatToolbar.m
//  Pods
//
//  Created by wshaolin on 2019/3/26.
//

#import "CXIMChatToolbar.h"
#import "CXIMChatTextView.h"
#import <CXFoundation/CXFoundation.h>
#import "CXIMImageDefines.h"

@interface CXIMChatToolbar () <CXIMChatTextViewDelegate> {
    CXIMChatTextView *_textView;
    UIButton *_imageButton;
    CGFloat _keyboardHeight;
}

@end

@implementation CXIMChatToolbar

- (instancetype)initWithFrame:(CGRect)frame{
    if([super initWithFrame:frame]){
        _textView = [[CXIMChatTextView alloc] init];
        _textView.maximumVisibleLines = 5;
        _textView.layer.cornerRadius = 4.0;
        _textView.delegate = self;
        [self addSubview:_textView];
        
        _imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_imageButton setImage:CX_IMUI_IMAGE(@"im_chatbar_camera") forState:UIControlStateNormal];
        [_imageButton addTarget:self action:@selector(handleActionForImageButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_imageButton];
        
        [NSNotificationCenter addObserver:self
                                   action:@selector(keyboardWillShowNotification:)
                                     name:UIKeyboardWillShowNotification];
        [NSNotificationCenter addObserver:self
                                   action:@selector(keyboardWillHideNotification:)
                                     name:UIKeyboardWillHideNotification];
    }
    
    return self;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\n"]){
        if([self.delegate respondsToSelector:@selector(IMChatToolbar:sendText:)]){
            [self.delegate IMChatToolbar:self sendText:textView.text];
        }
        
        textView.text = nil;
        return NO;
    }
    return YES;
}

- (void)IMChatTextView:(CXIMChatTextView *)textView didChangeTextHeight:(CGFloat)height{
    CGFloat offsetHeight = height - CGRectGetHeight(textView.frame);
    
    CGRect textViewFrame = textView.frame;
    textViewFrame.size.height = height;
    textView.frame = textViewFrame;
    
    CGRect frame = self.frame;
    frame.size.height += offsetHeight;
    frame.origin.y -= offsetHeight;
    self.frame = frame;
    
    [self notifyDelegateDidChangeFrame:frame changeType:CXIMChangeTypeTextChanged];
}

- (void)keyboardWillShowNotification:(NSNotification *)notification{
    NSDictionary<NSString *, id> *info = notification.userInfo;
    CGRect keyboardFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat duration = [info[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationOptions options = [info[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    _keyboardHeight = CGRectGetHeight(keyboardFrame);
    
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        CGRect frame = self.frame;
        frame.origin.y = CGRectGetMinY(keyboardFrame) - CGRectGetHeight(self.frame) + [UIScreen mainScreen].cx_safeAreaInsets.bottom;
        self.frame = frame;
        [self notifyDelegateDidChangeFrame:frame changeType:CXIMChangeTypeKeyboardShow];
    } completion:nil];
}

- (void)keyboardWillHideNotification:(NSNotification *)notification{
    NSDictionary<NSString *, id> *info = notification.userInfo;
    CGFloat duration = [info[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationOptions options = [info[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        CGRect frame = self.frame;
        frame.origin.y = CGRectGetHeight(self.superview.bounds) - CGRectGetHeight(frame);
        self.frame = frame;
        [self notifyDelegateDidChangeFrame:frame changeType:CXIMChangeTypeKeyboardHide];
    } completion:nil];
}

- (void)handleActionForImageButton:(UIButton *)imageButton{
    if([self.delegate respondsToSelector:@selector(IMChatToolbarActionForSelectPhoto:)]){
        [self.delegate IMChatToolbarActionForSelectPhoto:self];
    }
}

- (void)notifyDelegateDidChangeFrame:(CGRect)frame changeType:(CXIMChangeType)changeType{
    if([self.delegate respondsToSelector:@selector(IMChatToolbar:didChangeFrame:changeType:)]){
        [self.delegate IMChatToolbar:self didChangeFrame:frame changeType:changeType];
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    if(CGRectGetWidth(_textView.frame) > 0){
        return;
    }
    
    CGFloat imageButton_W = 50.0;
    CGFloat imageButton_H = imageButton_W;
    CGFloat imageButton_X = CGRectGetWidth(self.bounds) - imageButton_W - 2.0;
    CGFloat imageButton_Y = (CGRectGetHeight(self.bounds) - imageButton_H - [UIScreen mainScreen].cx_safeAreaInsets.bottom) * 0.5;
    _imageButton.frame = (CGRect){imageButton_X, imageButton_Y, imageButton_W, imageButton_H};
    
    CGFloat textView_X = 15.0;
    CGFloat textView_W = imageButton_X - textView_X;
    CGFloat textView_H = MAX(CGRectGetHeight(_textView.frame), _textView.minimumTextHeight);
    CGFloat textView_Y = (CGRectGetHeight(self.bounds) - textView_H - [UIScreen mainScreen].cx_safeAreaInsets.bottom) * 0.5;
    _textView.frame = (CGRect){textView_X, textView_Y, textView_W, textView_H};
}

- (void)dealloc{
    [NSNotificationCenter removeObserver:self];
}

@end
