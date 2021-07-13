//
//  CXIMMessageHandler.m
//  Pods
//
//  Created by wshaolin on 2019/4/10.
//

#import "CXIMMessageHandler.h"
#import <CXFoundation/CXFoundation.h>
#import "CXIMMessageModel.h"
#import "TIMMessage+CXIMSDK.h"
#import "CXIMProfileUtils.h"

@implementation CXIMMessageHandler

+ (void)convertMessages:(NSArray<TIMMessage *> *)messages
           conversation:(TIMConversation *)conversation
             completion:(void (^)(NSArray<CXIMMessageModel *> *))completion{
    if(!completion){
        return;
    }
    
    if(CXArrayIsEmpty(messages)){
        completion(nil);
        return;
    }
    
    // 所有的支持的消息
    NSMutableArray<CXIMMessageModel *> *array1 = [NSMutableArray array];
    // 发送失败的消息
    NSMutableArray<CXIMMessageModel *> *array2 = [NSMutableArray array];
    [messages enumerateObjectsUsingBlock:^(TIMMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([[[obj getConversation] getReceiver] isEqualToString:[conversation getReceiver]] && obj.supportive){
            CXIMMessageModel *message = [[CXIMMessageModel alloc] initWithMessage:obj];
            if(obj.status == TIM_MSG_STATUS_SEND_FAIL){
                [array2 addObject:message];
            }
            
            [array1 addObject:message];
        }
    }];
    
    CXIMMessageModel *failedMessage = array2.lastObject;
    if(!failedMessage || [conversation getType] != TIM_C2C){
        completion([array1 copy]);
        return;
    }
    
    [CXIMProfileUtils checkFriendship:[failedMessage.message sender] success:^(TIMCheckFriendResult * _Nullable friendResults) {
        if(friendResults.status != TIM_FRIEND_RELATION_TYPE_BOTH){
            [array2 enumerateObjectsUsingBlock:^(CXIMMessageModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.errorMsg = @"对方和你已不是好友关系";
            }];
        }
        
        completion([array1 copy]);
    } failure:^(int code, NSString * _Nullable error) {
        completion([array1 copy]);
    }];
}

@end
