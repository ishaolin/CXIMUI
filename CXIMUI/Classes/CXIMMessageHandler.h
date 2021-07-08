//
//  CXIMMessageHandler.h
//  Pods
//
//  Created by wshaolin on 2019/4/10.
//

#import <Foundation/Foundation.h>

@class TIMMessage, TIMConversation, CXIMMessageModel;

@interface CXIMMessageHandler : NSObject

+ (void)convertMessages:(NSArray<TIMMessage *> *)messages
           conversation:(TIMConversation *)conversation
             completion:(void (^)(NSArray<CXIMMessageModel *> *messageModels))completion;

@end
