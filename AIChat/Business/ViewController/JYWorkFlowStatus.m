//
//  JYWorkFlowStatus.m
//  AIChat
//
//  Created by JiangYing on 2025/10/22.
//

#import "JYWorkFlowStatus.h"
#import "JYMacro.h"
#import "JYPromiseHelper.h"
#import <PromiseKit/PromiseKit.h>

#pragma mark - JYWorkFlowNodeStatus

typedef enum : NSUInteger {
    JYWorkFlowNodeStatusPending = 0,
    JYWorkFlowNodeStatusRunning,
    JYWorkFlowNodeStatusFulfilled,
    JYWorkFlowNodeStatusRejected,
    JYWorkFlowNodeStatusSkipped,
} JYWorkFlowNodeStatus;

static BOOL isPending(JYWorkFlowNodeStatus status) {
    return status == JYWorkFlowNodeStatusPending;
}

static BOOL isFulfilled(JYWorkFlowNodeStatus status) {
    return status == JYWorkFlowNodeStatusFulfilled;
}

static BOOL isRejected(JYWorkFlowNodeStatus status) {
    return status == JYWorkFlowNodeStatusRejected;
}

static BOOL isSkipped(JYWorkFlowNodeStatus status) {
    return status == JYWorkFlowNodeStatusSkipped;
}

static BOOL isEnded(JYWorkFlowNodeStatus status) {
    return status == JYWorkFlowNodeStatusFulfilled || status == JYWorkFlowNodeStatusRejected || status == JYWorkFlowNodeStatusSkipped;
}

#pragma mark - JYWorkFlowStatus

@interface JYWorkFlowStatus ()

@property(nonatomic, weak) JYChatViewController *vc;
@property(nonatomic, copy) NSString *query;
@property(nonatomic, assign) BOOL enableDeepThinking;
@property(nonatomic, assign) BOOL enableOnlineSearch;

@property(nonatomic, copy) NSString *searchKeyword;
@property(nonatomic, copy) NSString *prompt;
@property(nonatomic, copy) NSString *promptMixed;

@property(nonatomic, assign) JYWorkFlowNodeStatus initStatus;
@property(nonatomic, assign) JYWorkFlowNodeStatus requestSearchKeyword;
@property(nonatomic, assign) JYWorkFlowNodeStatus requestSearchBaidu;
@property(nonatomic, assign) JYWorkFlowNodeStatus requestWebContentBaidu;
@property(nonatomic, assign) JYWorkFlowNodeStatus requestSearchSogou;
@property(nonatomic, assign) JYWorkFlowNodeStatus requestWebContentSogou;
@property(nonatomic, assign) JYWorkFlowNodeStatus requestSearchToutiao;
@property(nonatomic, assign) JYWorkFlowNodeStatus requestWebContentToutiao;
@property(nonatomic, assign) JYWorkFlowNodeStatus generatePrompt;
@property(nonatomic, assign) JYWorkFlowNodeStatus requestReplyDeepseek;
@property(nonatomic, assign) JYWorkFlowNodeStatus requestReplyDoubao;
@property(nonatomic, assign) JYWorkFlowNodeStatus requestReplyHunyuan;
@property(nonatomic, assign) JYWorkFlowNodeStatus generatePromptMixed;
@property(nonatomic, assign) JYWorkFlowNodeStatus requestReplyMixed;

@property(nonatomic, assign) JYWorkFlowNodeStatus uiSearchKeyword;
@property(nonatomic, assign) JYWorkFlowNodeStatus uiSearchBaidu;
@property(nonatomic, assign) JYWorkFlowNodeStatus uiSearchSogou;
@property(nonatomic, assign) JYWorkFlowNodeStatus uiSearchToutiao;
@property(nonatomic, assign) JYWorkFlowNodeStatus uiPrompt;
@property(nonatomic, assign) JYWorkFlowNodeStatus uiReplyDeepseek;
@property(nonatomic, assign) JYWorkFlowNodeStatus uiReplyDoubao;
@property(nonatomic, assign) JYWorkFlowNodeStatus uiReplyHunyuan;
@property(nonatomic, assign) JYWorkFlowNodeStatus uiPromptMixed;
@property(nonatomic, assign) JYWorkFlowNodeStatus uiReplyMixed;
@property(nonatomic, assign) JYWorkFlowNodeStatus uiResult;

@property(nonatomic, strong) JYMessageSearch *searchMessageBaidu;
@property(nonatomic, strong) JYMessageSearch *searchMessageSogou;
@property(nonatomic, strong) JYMessageSearch *searchMessageToutiao;
@property(nonatomic, strong) JYMessageAI *aiMessageDeepseek;
@property(nonatomic, strong) JYMessageAI *aiMessageDoubao;
@property(nonatomic, strong) JYMessageAI *aiMessageHunyuan;
@property(nonatomic, strong) JYMessageAI *aiMessageMixed;

@property(nonatomic, strong) JYChatMessageSearchCell *searchCellBaidu;
@property(nonatomic, strong) JYChatMessageSearchCell *searchCellSogou;
@property(nonatomic, strong) JYChatMessageSearchCell *searchCellToutiao;
@property(nonatomic, strong) JYChatMessageAICell *aiCellDeepseek;
@property(nonatomic, strong) JYChatMessageAICell *aiCellDoubao;
@property(nonatomic, strong) JYChatMessageAICell *aiCellHunyuan;
@property(nonatomic, strong) JYChatMessageAICell *aiCellMixed;

@end

@implementation JYWorkFlowStatus

- (instancetype)initWithVC:(JYChatViewController *)vc {
    self = [super init];
    if (self) {
        _vc = vc;
    }
    return self;
}

- (void)startWithQuery:(NSString *)query
    enableDeepThinking:(BOOL)enableDeepThinking
    enableOnlineSearch:(BOOL)enableOnlineSearch {
    self.query = query;
    self.enableDeepThinking = enableDeepThinking;
    self.enableOnlineSearch = enableOnlineSearch;
    [self workFlowStatusDidUpdate];
}

- (void)workFlowStatusDidUpdate {
    [self node_initStatus];
    [self node_requestSearchKeyword];
    [self node_requestSearchBaidu];
    [self node_requestWebContentBaidu];
    [self node_requestSearchSogou];
    [self node_requestWebContentSogou];
    [self node_requestSearchToutiao];
    [self node_requestWebContentToutiao];
    [self node_generatePrompt];
    [self node_requestReplyDeepseek];
    [self node_requestReplyDoubao];
    [self node_requestReplyHunyuan];
    [self node_generatePromptMixed];
    [self node_requestReplyMixed];
    
    [self node_uiSearchKeyword];
    [self node_uiSearchBaidu];
    [self node_uiSearchSogou];
    [self node_uiSearchToutiao];
    [self node_uiPrompt];
    [self node_uiReplyDeepseek];
    [self node_uiReplyDoubao];
    [self node_uiReplyHunyuan];
    [self node_uiPromptMixed];
    [self node_uiReplyMixed];
    [self node_uiResult];
}

- (void)node_initStatus {
    if (isPending(self.initStatus)) {
        self.initStatus = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        if (!self.enableOnlineSearch) {
            self.requestSearchKeyword = JYWorkFlowNodeStatusSkipped;
            self.requestSearchSogou = JYWorkFlowNodeStatusSkipped;
            self.requestWebContentSogou = JYWorkFlowNodeStatusSkipped;
            self.requestSearchToutiao = JYWorkFlowNodeStatusSkipped;
            self.requestWebContentToutiao = JYWorkFlowNodeStatusSkipped;
        }
        
        self.initStatus = JYWorkFlowNodeStatusFulfilled;
        [self workFlowStatusDidUpdate];
    }
}

- (void)node_requestSearchKeyword {
    if (isFulfilled(self.initStatus) &&
        isPending(self.requestSearchKeyword)) {
        self.requestSearchKeyword = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        [JYPromiseHelper.sharedInstance requestSearchKeywordWithQuery:self.query].then(^(NSString *searchKeyword) {
            NSLog(@"[jy] WorkFlow requestSearchKeyword searchKeyword: %@", searchKeyword);
            self.searchKeyword = searchKeyword;
            
            self.requestSearchKeyword = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }).catch(^(NSError *error) {
            NSLog(@"[jy] WorkFlow requestSearchKeyword error: %@", error);
            
            self.requestSearchKeyword = JYWorkFlowNodeStatusRejected;
            [self workFlowStatusDidUpdate];
        });
    }
}

- (void)node_requestSearchBaidu {
    if (isFulfilled(self.requestSearchKeyword) &&
        isPending(self.requestSearchBaidu)) {
        self.requestSearchBaidu = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        [JYPromiseHelper.sharedInstance requestSearchWithKeyword:self.searchKeyword engine:JYMessageSearchEngineBaidu].then(^(NSArray<JYMessageSearchResult *> *resultList) {
            NSLog(@"[jy] WorkFlow requestSearchBaidu resultList: %@", resultList.yy_modelToJSONString);
            JYMessageSearch *message = [[JYMessageSearch alloc] init];
            message.engine = JYMessageSearchEngineBaidu;
            [message setResultList:resultList];
            self.searchMessageBaidu = message;
            
            self.requestSearchBaidu = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }).catch(^(NSError *error) {
            NSLog(@"[jy] WorkFlow requestSearchBaidu error: %@", error);
            
            self.requestSearchBaidu = JYWorkFlowNodeStatusRejected;
            [self workFlowStatusDidUpdate];
        });
    }
}

- (void)node_requestSearchSogou {
    if (isFulfilled(self.requestSearchKeyword) &&
        isPending(self.requestSearchSogou)) {
        self.requestSearchSogou = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        [JYPromiseHelper.sharedInstance requestSearchWithKeyword:self.searchKeyword engine:JYMessageSearchEngineSogou].then(^(NSArray<JYMessageSearchResult *> *resultList) {
            NSLog(@"[jy] WorkFlow requestSearchSogou resultList: %@", resultList.yy_modelToJSONString);
            JYMessageSearch *message = [[JYMessageSearch alloc] init];
            message.engine = JYMessageSearchEngineSogou;
            [message setResultList:resultList];
            self.searchMessageSogou = message;
            
            self.requestSearchSogou = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }).catch(^(NSError *error) {
            NSLog(@"[jy] WorkFlow requestSearchSogou error: %@", error);
            
            self.requestSearchSogou = JYWorkFlowNodeStatusRejected;
            [self workFlowStatusDidUpdate];
        });
    }
}

- (void)node_requestSearchToutiao {
    if (isFulfilled(self.requestSearchKeyword) &&
        isPending(self.requestSearchToutiao)) {
        self.requestSearchToutiao = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        [JYPromiseHelper.sharedInstance requestSearchWithKeyword:self.searchKeyword engine:JYMessageSearchEngineToutiao].then(^(NSArray<JYMessageSearchResult *> *resultList) {
            NSLog(@"[jy] WorkFlow requestSearchToutiao resultList: %@", resultList.yy_modelToJSONString);
            JYMessageSearch *message = [[JYMessageSearch alloc] init];
            message.engine = JYMessageSearchEngineToutiao;
            [message setResultList:resultList];
            self.searchMessageToutiao = message;
            
            self.requestSearchToutiao = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }).catch(^(NSError *error) {
            NSLog(@"[jy] WorkFlow requestSearchToutiao error: %@", error);
            
            self.requestSearchToutiao = JYWorkFlowNodeStatusRejected;
            [self workFlowStatusDidUpdate];
        });
    }
}

- (void)node_requestWebContentBaidu {
    if (isFulfilled(self.requestSearchBaidu) &&
        isPending(self.requestWebContentBaidu)) {
        self.requestWebContentBaidu = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        NSArray<NSString *> *urlList = [self.searchMessageBaidu.resultList qmui_mapWithBlock:^id _Nonnull(JYMessageSearchResult *result, NSInteger index) {
            return result.url ?: @"";
        }];
        [JYPromiseHelper.sharedInstance requestWebContentListWithUrlList:urlList].then(^(NSArray<JYMessageSearchResult *> *resultList) {
            for (JYMessageSearchResult *result in resultList) {
                JYMessageSearchResult *originResult = [self.searchMessageBaidu.resultList qmui_firstMatchWithBlock:^BOOL(JYMessageSearchResult * _Nonnull item) {
                    return [item.url isEqualToString:result.url];
                }];
                if (originResult) {
                    originResult.content = result.content;
                }
            }
            NSLog(@"[jy] WorkFlow requestWebContentBaidu message: %@", self.searchMessageBaidu.resultList.yy_modelToJSONString);
            
            self.requestWebContentBaidu = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }).catch(^(NSError *error) {
            NSLog(@"[jy] WorkFlow requestWebContentBaidu error: %@", error);
            
            self.requestWebContentBaidu = JYWorkFlowNodeStatusRejected;
            [self workFlowStatusDidUpdate];
        });
    }
}

- (void)node_requestWebContentSogou {
    if (isFulfilled(self.requestSearchSogou) &&
        isPending(self.requestWebContentSogou)) {
        self.requestWebContentSogou = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        NSArray<NSString *> *urlList = [self.searchMessageSogou.resultList qmui_mapWithBlock:^id _Nonnull(JYMessageSearchResult *result, NSInteger index) {
            return result.url ?: @"";
        }];
        [JYPromiseHelper.sharedInstance requestWebContentListWithUrlList:urlList].then(^(NSArray<JYMessageSearchResult *> *resultList) {
            for (JYMessageSearchResult *result in resultList) {
                JYMessageSearchResult *originResult = [self.searchMessageSogou.resultList qmui_firstMatchWithBlock:^BOOL(JYMessageSearchResult * _Nonnull item) {
                    return [item.url isEqualToString:result.url];
                }];
                if (originResult) {
                    originResult.content = result.content;
                }
            }
            NSLog(@"[jy] WorkFlow requestWebContentSogou message: %@", self.searchMessageSogou.resultList.yy_modelToJSONString);
            
            self.requestWebContentSogou = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }).catch(^(NSError *error) {
            NSLog(@"[jy] WorkFlow requestWebContentSogou error: %@", error);
            
            self.requestWebContentSogou = JYWorkFlowNodeStatusRejected;
            [self workFlowStatusDidUpdate];
        });
    }
}

- (void)node_requestWebContentToutiao {
    if (isFulfilled(self.requestSearchToutiao) &&
        isPending(self.requestWebContentToutiao)) {
        self.requestWebContentToutiao = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        NSArray<NSString *> *urlList = [self.searchMessageToutiao.resultList qmui_mapWithBlock:^id _Nonnull(JYMessageSearchResult *result, NSInteger index) {
            return result.url ?: @"";
        }];
        [JYPromiseHelper.sharedInstance requestWebContentListWithUrlList:urlList].then(^(NSArray<JYMessageSearchResult *> *resultList) {
            for (JYMessageSearchResult *result in resultList) {
                JYMessageSearchResult *originResult = [self.searchMessageToutiao.resultList qmui_firstMatchWithBlock:^BOOL(JYMessageSearchResult * _Nonnull item) {
                    return [item.url isEqualToString:result.url];
                }];
                if (originResult) {
                    originResult.content = result.content;
                }
            }
            NSLog(@"[jy] WorkFlow requestWebContentToutiao message: %@", self.searchMessageToutiao.resultList.yy_modelToJSONString);
            
            self.requestWebContentToutiao = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }).catch(^(NSError *error) {
            NSLog(@"[jy] WorkFlow requestWebContentToutiao error: %@", error);
            
            self.requestWebContentToutiao = JYWorkFlowNodeStatusRejected;
            [self workFlowStatusDidUpdate];
        });
    }
}

- (void)node_generatePrompt {
    if (isEnded(self.requestWebContentBaidu) &&
        isEnded(self.requestWebContentSogou) &&
        isEnded(self.requestWebContentToutiao) &&
        isPending(self.generatePrompt)) {
        if (self.enableOnlineSearch) {
            BOOL isSearchFulfilled = (isFulfilled(self.requestWebContentBaidu) ||
                                      isFulfilled(self.requestWebContentSogou) ||
                                      isFulfilled(self.requestWebContentToutiao));
            if (isSearchFulfilled) {
                NSMutableString *reference = [NSMutableString string];
                self.generatePrompt = JYWorkFlowNodeStatusRunning;
                [self workFlowStatusDidUpdate];
                
                for (JYMessageSearchResult *result in self.searchMessageBaidu.resultList) {
                    if (result.title.length == 0 || result.url.length == 0 || result.content.length == 0) {
                        continue;
                    }
                    [reference appendFormat:@"## %@""\n""%@""\n", result.title, result.content];
                }
                for (JYMessageSearchResult *result in self.searchMessageSogou.resultList) {
                    if (result.title.length == 0 || result.url.length == 0 || result.content.length == 0) {
                        continue;
                    }
                    [reference appendFormat:@"## %@""\n""%@""\n", result.title, result.content];
                }
                for (JYMessageSearchResult *result in self.searchMessageToutiao.resultList) {
                    if (result.title.length == 0 || result.url.length == 0 || result.content.length == 0) {
                        continue;
                    }
                    [reference appendFormat:@"## %@""\n""%@""\n", result.title, result.content];
                }
                NSString *prompt = [NSString stringWithFormat:@"# 角色""\n"
                                    "你是一个专业的AI问答助手，请根据问题回答，以下会给你一些参考资料。""\n"
                                    "# 问题""\n"
                                    "%@""\n"
                                    "# 参考资料""\n"
                                    "%@""\n", self.query ?: @"", reference];
                self.prompt = prompt;
                
                self.generatePrompt = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
            } else {
                self.generatePrompt = JYWorkFlowNodeStatusRejected;
                [self workFlowStatusDidUpdate];
            }
        } else {
            self.generatePrompt = JYWorkFlowNodeStatusRunning;
            [self workFlowStatusDidUpdate];
            
            NSString *prompt = [NSString stringWithFormat:@"# 角色""\n"
                                "你是一个专业的AI问答助手，请根据问题回答。""\n"
                                "# 问题""\n"
                                "%@""\n"
                                "# 参考资料""\n", self.query ?: @""];
            self.prompt = prompt;
            NSLog(@"[jy] WorkFlow generatePrompt prompt: %@", prompt);
            
            self.generatePrompt = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }
    }
}

- (void)node_requestReplyDeepseek {
    if (isFulfilled(self.generatePrompt) &&
        isPending(self.requestReplyDeepseek)) {
        self.requestReplyDeepseek = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            JYMessageAI *message = [[JYMessageAI alloc] init];
            message.model = JYMessageAIModelDeepseek;
            self.aiMessageDeepseek = message;
            
            JYChatMessageAICell *cell = [[JYChatMessageAICell alloc] init];
            [cell refreshWithModel:JYMessageAIModelDeepseek];
            self.aiCellDeepseek = cell;
            [self workFlowStatusDidUpdate];
            
            [JYPromiseHelper.sharedInstance requestAIModelWithPrompt:self.prompt
                                                           aiMessage:message
                                                              aiCell:cell
                                                  enableDeepThinking:self.enableDeepThinking].then(^(JYMessageAI *aiMessage) {
                NSLog(@"[jy] WorkFlow requestReplyDeepseek aiMessage: %@", aiMessage.content);
                
                self.requestReplyDeepseek = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
            }).catch(^(NSError *error) {
                NSLog(@"[jy] WorkFlow requestReplyDeepseek error: %@", error);
                
                self.requestReplyDeepseek = JYWorkFlowNodeStatusRejected;
                [self workFlowStatusDidUpdate];
            });
        });
    }
}

- (void)node_requestReplyDoubao {
    if (isFulfilled(self.generatePrompt) &&
        isPending(self.requestReplyDoubao)) {
        self.requestReplyDoubao = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            JYMessageAI *message = [[JYMessageAI alloc] init];
            message.model = JYMessageAIModelDoubao;
            self.aiMessageDoubao = message;
            
            JYChatMessageAICell *cell = [[JYChatMessageAICell alloc] init];
            [cell refreshWithModel:JYMessageAIModelDoubao];
            self.aiCellDoubao = cell;
            [self workFlowStatusDidUpdate];
            
            [JYPromiseHelper.sharedInstance requestAIModelWithPrompt:self.prompt
                                                           aiMessage:message
                                                              aiCell:cell
                                                  enableDeepThinking:self.enableDeepThinking].then(^(JYMessageAI *aiMessage) {
                NSLog(@"[jy] WorkFlow requestReplyDoubao aiMessage: %@", aiMessage.content);
                
                self.requestReplyDoubao = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
            }).catch(^(NSError *error) {
                NSLog(@"[jy] WorkFlow requestReplyDoubao error: %@", error);
                
                self.requestReplyDoubao = JYWorkFlowNodeStatusRejected;
                [self workFlowStatusDidUpdate];
            });
        });
    }
}

- (void)node_requestReplyHunyuan {
    if (isFulfilled(self.generatePrompt) &&
        isPending(self.requestReplyHunyuan)) {
        self.requestReplyHunyuan = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            JYMessageAI *message = [[JYMessageAI alloc] init];
            message.model = JYMessageAIModelHunyuan;
            self.aiMessageHunyuan = message;
            
            JYChatMessageAICell *cell = [[JYChatMessageAICell alloc] init];
            [cell refreshWithModel:JYMessageAIModelHunyuan];
            self.aiCellHunyuan = cell;
            [self workFlowStatusDidUpdate];
            
            [JYPromiseHelper.sharedInstance requestAIModelWithPrompt:self.prompt
                                                           aiMessage:message
                                                              aiCell:cell
                                                  enableDeepThinking:self.enableDeepThinking].then(^(JYMessageAI *aiMessage) {
                NSLog(@"[jy] WorkFlow requestReplyHunyuan aiMessage: %@", aiMessage.content);
                
                self.requestReplyHunyuan = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
            }).catch(^(NSError *error) {
                NSLog(@"[jy] WorkFlow requestReplyHunyuan error: %@", error);
                
                self.requestReplyHunyuan = JYWorkFlowNodeStatusRejected;
                [self workFlowStatusDidUpdate];
            });
        });
    }
}

- (void)node_generatePromptMixed {
    if (isEnded(self.requestReplyDeepseek) &&
        isEnded(self.requestReplyDoubao) &&
        isEnded(self.requestReplyHunyuan) &&
        isPending(self.generatePromptMixed)) {
        BOOL isReplyFulfilled = (isFulfilled(self.requestReplyDeepseek) ||
                                 isFulfilled(self.requestReplyDoubao) ||
                                 isFulfilled(self.requestReplyHunyuan));
        if (isReplyFulfilled) {
            NSInteger replyCount = 0;
            NSMutableString *reply = [NSMutableString string];
            if (isFulfilled(self.requestReplyDeepseek)) {
                [reply appendFormat:@"# 回答%@""\n""%@""\n", @(++replyCount), self.aiMessageDoubao.content ?: @""];
            }
            if (isFulfilled(self.requestReplyDoubao)) {
                [reply appendFormat:@"# 回答%@""\n""%@""\n", @(++replyCount), self.aiMessageDoubao.content ?: @""];
            }
            if (isFulfilled(self.requestReplyHunyuan)) {
                [reply appendFormat:@"# 回答%@""\n""%@""\n", @(++replyCount), self.aiMessageHunyuan.content ?: @""];
            }
            
            NSString *prompt = [NSString stringWithFormat:@"# 角色""\n"
                                "你是一个擅长“答案汇总”的专家，你将会收到关于一个问题的多个答案，你需要对多个答案进行去重、整合等处理，输出一个最终答案。""\n"
                                "# 问题""\n"
                                "%@""\n", reply];
            self.promptMixed = prompt;
            
            self.generatePromptMixed = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        } else {
            self.generatePromptMixed = JYWorkFlowNodeStatusRejected;
            [self workFlowStatusDidUpdate];
        }
    }
}

- (void)node_requestReplyMixed {
    if (isFulfilled(self.generatePromptMixed) &&
        isPending(self.requestReplyMixed)) {
        self.requestReplyMixed = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            JYMessageAI *message = [[JYMessageAI alloc] init];
            message.model = JYMessageAIModelMixed;
            self.aiMessageMixed = message;
            
            JYChatMessageAICell *cell = [[JYChatMessageAICell alloc] init];
            [cell refreshWithModel:JYMessageAIModelMixed];
            self.aiCellMixed = cell;
            [self workFlowStatusDidUpdate];
            
            [JYPromiseHelper.sharedInstance requestAIModelWithPrompt:self.promptMixed
                                                           aiMessage:message
                                                              aiCell:cell
                                                  enableDeepThinking:self.enableDeepThinking].then(^(JYMessageAI *aiMessage) {
                NSLog(@"[jy] WorkFlow requestReplyMixed aiMessage: %@", aiMessage.yy_modelToJSONString);
                
                self.requestReplyMixed = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
            }).catch(^(NSError *error) {
                NSLog(@"[jy] WorkFlow requestReplyMixed error: %@", error);
                
                self.requestReplyMixed = JYWorkFlowNodeStatusRejected;
                [self workFlowStatusDidUpdate];
            });
        });
    }
}

- (void)node_uiSearchKeyword {
    if (isEnded(self.requestSearchKeyword) &&
        isPending(self.uiSearchKeyword)) {
        self.uiSearchKeyword = JYWorkFlowNodeStatusFulfilled;
        [self workFlowStatusDidUpdate];
        
        if (isRejected(self.requestSearchKeyword)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.vc.inputView.placeholder = @"搜索关键词解析失败，点此重试";
                [self.vc.inputView stopPlaceholderLoading];
            });
        }
    }
}

- (void)node_uiSearchBaidu {
    if (isEnded(self.uiSearchKeyword) &&
        isEnded(self.requestSearchBaidu) &&
        isPending(self.uiSearchBaidu)) {
        if (isFulfilled(self.requestSearchBaidu)) {
            self.uiSearchBaidu = JYWorkFlowNodeStatusRunning;
            [self workFlowStatusDidUpdate];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                JYChatMessageSearchCell *cell = [[JYChatMessageSearchCell alloc] init];
                [cell refreshWithEngine:JYMessageSearchEngineBaidu];
                [self.vc.stackView addArrangedSubview:cell];
                [cell setResultList:self.searchMessageBaidu.resultList];
                @weakify(self);
                cell.stopAnimationAction = ^{
                    @strongify(self);
                    self.uiSearchBaidu = JYWorkFlowNodeStatusFulfilled;
                    [self workFlowStatusDidUpdate];
                };
                self.searchCellBaidu = cell;
                
                self.vc.inputView.placeholder = [NSString stringWithFormat:@"%@ 搜索中", searchEngineDescription(JYMessageSearchEngineBaidu)];
                [self.vc.inputView startPlaceholderLoading];
            });
        } else {
            self.uiSearchBaidu = JYWorkFlowNodeStatusSkipped;
            [self workFlowStatusDidUpdate];
        }
    }
}

- (void)node_uiSearchSogou {
    if (isEnded(self.uiSearchBaidu) &&
        isEnded(self.requestSearchSogou) &&
        isPending(self.uiSearchSogou)) {
        if (isFulfilled(self.requestSearchSogou)) {
            self.uiSearchSogou = JYWorkFlowNodeStatusRunning;
            [self workFlowStatusDidUpdate];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                JYChatMessageSearchCell *cell = [[JYChatMessageSearchCell alloc] init];
                [cell refreshWithEngine:JYMessageSearchEngineSogou];
                [self.vc.stackView addArrangedSubview:cell];
                [cell setResultList:self.searchMessageSogou.resultList];
                @weakify(self);
                cell.stopAnimationAction = ^{
                    @strongify(self);
                    self.uiSearchSogou = JYWorkFlowNodeStatusFulfilled;
                    [self workFlowStatusDidUpdate];
                };
                self.searchCellSogou = cell;
                
                self.vc.inputView.placeholder = [NSString stringWithFormat:@"%@ 搜索中", searchEngineDescription(JYMessageSearchEngineSogou)];
                [self.vc.inputView startPlaceholderLoading];
            });
        } else {
            self.uiSearchSogou = JYWorkFlowNodeStatusSkipped;
            [self workFlowStatusDidUpdate];
        }
    }
}

- (void)node_uiSearchToutiao {
    if (isEnded(self.uiSearchSogou) &&
        isEnded(self.requestSearchToutiao) &&
        isPending(self.uiSearchToutiao)) {
        if (isFulfilled(self.requestSearchToutiao)) {
            self.uiSearchToutiao = JYWorkFlowNodeStatusRunning;
            [self workFlowStatusDidUpdate];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                JYChatMessageSearchCell *cell = [[JYChatMessageSearchCell alloc] init];
                [cell refreshWithEngine:JYMessageSearchEngineToutiao];
                [self.vc.stackView addArrangedSubview:cell];
                [cell setResultList:self.searchMessageToutiao.resultList];
                @weakify(self);
                cell.stopAnimationAction = ^{
                    @strongify(self);
                    self.uiSearchToutiao = JYWorkFlowNodeStatusFulfilled;
                    [self workFlowStatusDidUpdate];
                };
                self.searchCellToutiao = cell;
                
                self.vc.inputView.placeholder = [NSString stringWithFormat:@"%@ 搜索中", searchEngineDescription(JYMessageSearchEngineToutiao)];
                [self.vc.inputView startPlaceholderLoading];
            });
        } else {
            self.uiSearchToutiao = JYWorkFlowNodeStatusSkipped;
            [self workFlowStatusDidUpdate];
        }
    }
}

- (void)node_uiPrompt {
    if (isEnded(self.uiSearchToutiao) &&
        isEnded(self.generatePrompt) &&
        isPending(self.uiPrompt)) {
        self.uiPrompt = JYWorkFlowNodeStatusFulfilled;
        [self workFlowStatusDidUpdate];
        
        if (isRejected(self.generatePrompt)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.vc.inputView.placeholder = @"搜索失败，点此重试";
                [self.vc.inputView stopPlaceholderLoading];
            });
        }
    }
}

- (void)node_uiReplyDeepseek {
    if (isEnded(self.uiPrompt) &&
        self.aiCellDeepseek &&
        isPending(self.uiReplyDeepseek)) {
        self.uiReplyDeepseek = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @weakify(self);
            self.aiCellDeepseek.stopAnimationAction = ^{
                @strongify(self);
                self.uiReplyDeepseek = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
            };
            [self.vc.stackView addArrangedSubview:self.aiCellDeepseek];
            [self.aiCellDeepseek startAnimation];
            
            self.vc.inputView.placeholder = [NSString stringWithFormat:@"%@ 生成中", aiModelDescription(JYMessageAIModelDeepseek)];
            [self.vc.inputView startPlaceholderLoading];
        });
    }
}

- (void)node_uiReplyDoubao {
    if (isEnded(self.uiReplyDeepseek) &&
        self.aiCellDoubao &&
        isPending(self.uiReplyDoubao)) {
        self.uiReplyDoubao = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @weakify(self);
            self.aiCellDoubao.stopAnimationAction = ^{
                @strongify(self);
                self.uiReplyDoubao = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
            };
            [self.vc.stackView addArrangedSubview:self.aiCellDoubao];
            [self.aiCellDoubao startAnimation];
            
            self.vc.inputView.placeholder = [NSString stringWithFormat:@"%@ 生成中", aiModelDescription(JYMessageAIModelDoubao)];
            [self.vc.inputView startPlaceholderLoading];
        });
    }
}

- (void)node_uiReplyHunyuan {
    if (isEnded(self.uiReplyDoubao) &&
        self.aiCellHunyuan &&
        isPending(self.uiReplyHunyuan)) {
        self.uiReplyHunyuan = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @weakify(self);
            self.aiCellHunyuan.stopAnimationAction = ^{
                @strongify(self);
                self.uiReplyHunyuan = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
            };
            [self.vc.stackView addArrangedSubview:self.aiCellHunyuan];
            [self.aiCellHunyuan startAnimation];
            
            self.vc.inputView.placeholder = [NSString stringWithFormat:@"%@ 生成中", aiModelDescription(JYMessageAIModelHunyuan)];
            [self.vc.inputView startPlaceholderLoading];
        });
    }
}

- (void)node_uiPromptMixed {
    if (isEnded(self.uiReplyHunyuan) &&
        isEnded(self.generatePromptMixed) &&
        isPending(self.uiPromptMixed)) {
        self.uiPromptMixed = JYWorkFlowNodeStatusFulfilled;
        [self workFlowStatusDidUpdate];
        
        if (isRejected(self.generatePromptMixed)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.vc.inputView.placeholder = @"答案生成失败，点此重试";
                [self.vc.inputView stopPlaceholderLoading];
            });
        }
    }
}

- (void)node_uiReplyMixed {
    if (isEnded(self.uiPromptMixed) &&
        self.aiCellMixed &&
        isPending(self.uiReplyMixed)) {
        self.uiReplyMixed = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @weakify(self);
            self.aiCellMixed.stopAnimationAction = ^{
                @strongify(self);
                self.uiReplyMixed = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
            };
            [self.vc.stackView addArrangedSubview:self.aiCellMixed];
            [self.aiCellMixed startAnimation];
            
            self.vc.inputView.placeholder = [NSString stringWithFormat:@"%@ 生成中", aiModelDescription(JYMessageAIModelMixed)];
            [self.vc.inputView startPlaceholderLoading];
        });
    }
}

- (void)node_uiResult {
    if (isEnded(self.uiReplyMixed) &&
        isPending(self.uiResult)) {
        self.uiResult = JYWorkFlowNodeStatusFulfilled;
        [self workFlowStatusDidUpdate];
        
        if (isFulfilled(self.requestReplyMixed)) {
            self.vc.inputView.placeholder = @"已完成回答，点击右上角开启新提问";
            [self.vc.inputView stopPlaceholderLoading];
            [self.vc stopScrollTimer];
            [self.vc.scrollView qmui_scrollToBottomAnimated:NO];
        } else if (isRejected(self.requestReplyMixed)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.vc.inputView.placeholder = @"最终答案生成失败，点此重试";
                [self.vc.inputView stopPlaceholderLoading];
            });
        }
    }
}

@end
