//
//  JYWorkFlowStatus.h
//  AIChat
//
//  Created by JiangYing on 2025/10/22.
//

#import <Foundation/Foundation.h>
#import "JYModel.h"
#import "JYChatViewController.h"
#import "JYChatMessageAICell.h"
#import "JYChatMessageSearchCell.h"

@interface JYWorkFlowStatus : NSObject

@property(nonatomic, weak, readonly) JYChatViewController *vc;
@property(nonatomic, copy, readonly, nonnull) NSString *query;
@property(nonatomic, assign, readonly) BOOL enableDeepThinking;
@property(nonatomic, assign, readonly) BOOL enableOnlineSearch;

- (instancetype _Nonnull)initWithVC:(JYChatViewController *_Nonnull)vc;

- (void)startWithQuery:(NSString *_Nonnull)query
    enableDeepThinking:(BOOL)enableDeepThinking
    enableOnlineSearch:(BOOL)enableOnlineSearch;

@end
