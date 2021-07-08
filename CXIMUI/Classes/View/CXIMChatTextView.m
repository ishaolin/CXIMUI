//
//  CXIMChatTextView.m
//  Pods
//
//  Created by wshaolin on 2019/3/26.
//

#import "CXIMChatTextView.h"

@interface CXIMChatTextView () {
    CGFloat _textHeight;
}

@end

@implementation CXIMChatTextView

@dynamic delegate;

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        self.backgroundColor = [UIColor whiteColor];
        self.scrollEnabled = NO;
        self.scrollsToTop = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.enablesReturnKeyAutomatically = YES;
        self.returnKeyType = UIReturnKeySend;
        self.font = CX_PingFangSC_RegularFont(17.0);
        
        self.placeholderColor = CXHexIColor(0xCCCCCC);
        self.placeholder = @"请输入内容";
        self.minimumTextHeight = 37.0;
    }
    
    return self;
}

- (void)textDidChange:(NSString *)text{
    if([self.delegate respondsToSelector:@selector(IMChatTextView:didChangeTextHeight:)]){
        CGFloat textHeight = ceilf([self sizeThatFits:CGSizeMake(self.bounds.size.width, MAXFLOAT)].height);
        if(self.maximumVisibleLines > 0){
            CGFloat maximumTextHeight = ceil(self.font.lineHeight * self.maximumVisibleLines + self.textContainerInset.top + self.textContainerInset.bottom);
            self.scrollEnabled = textHeight > maximumTextHeight;
            textHeight = MIN(textHeight, maximumTextHeight);
        }
        
        textHeight = MAX(textHeight, self.minimumTextHeight);
        if(textHeight == _textHeight){
            return;
        }
        
        _textHeight = textHeight;
        [self.delegate IMChatTextView:self didChangeTextHeight:_textHeight];
    }
}

@end
