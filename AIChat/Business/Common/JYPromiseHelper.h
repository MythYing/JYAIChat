//
//  JYPromiseHelper.h
//  AIChat
//
//  Created by JiangYing on 2025/10/16.
//

#import <Foundation/Foundation.h>
#import <PromiseKit/PromiseKit.h>
#import "JYChatMessageAICell.h"
#import "JYModel.h"

@interface JYPromiseHelper : NSObject

+ (instancetype _Nonnull)sharedInstance;

- (AnyPromise *_Nonnull)requestSearchWithKeyword:(NSString *_Nonnull)keyword engine:(JYMessageSearchEngine)engine;
- (AnyPromise *_Nonnull)requestWebContentListWithUrlList:(NSArray<NSString *> *_Nonnull)urlList;

- (AnyPromise *_Nonnull)requestSearchKeywordWithQuery:(NSString *_Nonnull)query;
- (AnyPromise *_Nonnull)requestAIModelWithPrompt:(NSString *_Nonnull)prompt
                                       aiMessage:(JYMessageAI *_Nonnull)aiMessage
                                          aiCell:(JYChatMessageAICell *_Nonnull)aiCell
                              enableDeepThinking:(BOOL)enableDeepThinking;

@end
