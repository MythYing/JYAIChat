//
//  JYChatViewController.m
//  AIChat
//
//  Created by JiangYing on 2025/10/3.
//

#import "JYChatViewController.h"
#import "JYMacro.h"
#import "JYModel.h"
#import "JYPromiseHelper.h"
#import "JYChatNavigationBar.h"
#import "JYChatInputView.h"
#import "JYChatMessageUserCell.h"
#import "JYChatMessageAICell.h"
#import "JYChatMessageSearchCell.h"
#import <JYEventSource/EventSource.h>
#import <PromiseKit/PromiseKit.h>

#pragma mark - JYWorkFlowStatus

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

static BOOL isEnded(JYWorkFlowNodeStatus status) {
    return status == JYWorkFlowNodeStatusFulfilled || status == JYWorkFlowNodeStatusRejected || status == JYWorkFlowNodeStatusSkipped;
}

@interface JYWorkFlowStatus : NSObject

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
@property(nonatomic, assign) JYWorkFlowNodeStatus requestReplyMixed;

@property(nonatomic, assign) JYWorkFlowNodeStatus uiSearchBaidu;
@property(nonatomic, assign) JYWorkFlowNodeStatus uiSearchSogou;
@property(nonatomic, assign) JYWorkFlowNodeStatus uiSearchToutiao;
@property(nonatomic, assign) JYWorkFlowNodeStatus uiReplyDeepseek;
@property(nonatomic, assign) JYWorkFlowNodeStatus uiReplyDoubao;
@property(nonatomic, assign) JYWorkFlowNodeStatus uiReplyHunyuan;
@property(nonatomic, assign) JYWorkFlowNodeStatus uiReplyMixed;

@property(nonatomic, assign) BOOL enableDeepThinking;
@property(nonatomic, assign) BOOL enableOnlineSearch;
@property(nonatomic, copy) NSString *query;
@property(nonatomic, copy) NSString *searchKeyword;
@property(nonatomic, copy) NSString *prompt;

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

@end

#pragma mark - JYChatViewController

@interface JYChatViewController ()

@property(nonatomic, strong) JYChatNavigationBar *navBar;
@property(nonatomic, strong) JYChatInputView *inputView;
@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) UIStackView *stackView;
@property(nonatomic, strong) UILabel *titleLabel;

@property(nonatomic, assign) BOOL didFirstViewDidAppear;

@property(nonatomic, strong) JYWorkFlowStatus *workFlowStatus;
@property(nonatomic, strong) NSTimer *scrollTimer;

@end

@implementation JYChatViewController

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        _workFlowStatus = [[JYWorkFlowStatus alloc] init];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:true animated:false];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.didFirstViewDidAppear) {
        self.didFirstViewDidAppear = YES;
        [self.inputView.textView becomeFirstResponder];
    }
}

- (void)setupUI {
    self.view.backgroundColor = UIColor.whiteColor;
    
    [self.view addSubview:self.navBar];
    [self.view addSubview:self.inputView];
    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.stackView];
    [self.view addSubview:self.titleLabel];
    
    [self.navBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
    }];
    [self.inputView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.leading.trailing.equalTo(self.view);
    }];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(self.navBar.mas_bottom);
        make.bottom.equalTo(self.inputView.mas_top);
    }];
    [self.stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.stackView.superview);
        make.width.equalTo(self.scrollView);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.scrollView).inset(24);
        make.centerY.equalTo(self.scrollView);
    }];
    
    self.inputView.placeholder = @"请输入文字进行提问";
    [self.inputView stopPlaceholderLoading];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startTitleAnimationWithLength:0];
    });
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

#pragma mark - Notification

- (void)keyboardWillShow:(NSNotification *)notification {
    [self.scrollView qmui_scrollToBottomAnimated:YES];
}

#pragma mark - Action

- (void)onNewChat {
    JYChatViewController *vc = [[JYChatViewController alloc] init];
    [self.navigationController setViewControllers:@[vc] animated:false];
}

- (void)onSend {
    NSString *text = [self.inputView.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    self.inputView.textView.text = @"";
    [self.inputView.textView.delegate textViewDidChange:self.inputView.textView];
    [self.inputView.textView endEditing:YES];
    self.inputView.userInteractionEnabled = NO;
    self.titleLabel.hidden = YES;
    
    JYMessageUser *userMessage = [[JYMessageUser alloc] init];
    userMessage.contentId = [NSUUID UUID].UUIDString.lowercaseString;
    userMessage.content = text;
    JYChatMessageUserCell *cell = [[JYChatMessageUserCell alloc] init];
    [cell refreshWithMessage:userMessage];
    [self.stackView addArrangedSubview:cell];
    self.inputView.placeholder = @"等待响应中";
    [self.inputView startPlaceholderLoading];
    [self startScrollTimer];
    
    self.workFlowStatus = [[JYWorkFlowStatus alloc] init];
    self.workFlowStatus.enableDeepThinking = self.inputView.deepThinkingOptionView.isSelected;
    self.workFlowStatus.enableOnlineSearch = self.inputView.onlineSearchOptionView.isSelected;
    self.workFlowStatus.query = text;
    [self workFlowStatusDidUpdate];
}

- (void)workFlowStatusDidUpdate {
    if (isPending(self.workFlowStatus.initStatus)) {
        self.workFlowStatus.initStatus = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        if (!self.workFlowStatus.enableOnlineSearch) {
            self.workFlowStatus.requestSearchKeyword = JYWorkFlowNodeStatusSkipped;
            self.workFlowStatus.requestSearchSogou = JYWorkFlowNodeStatusSkipped;
            self.workFlowStatus.requestWebContentSogou = JYWorkFlowNodeStatusSkipped;
            self.workFlowStatus.requestSearchToutiao = JYWorkFlowNodeStatusSkipped;
            self.workFlowStatus.requestWebContentToutiao = JYWorkFlowNodeStatusSkipped;
        }
        
        self.workFlowStatus.initStatus = JYWorkFlowNodeStatusFulfilled;
        [self workFlowStatusDidUpdate];
    }
    
    if (isFulfilled(self.workFlowStatus.initStatus) &&
        isPending(self.workFlowStatus.requestSearchKeyword)) {
        self.workFlowStatus.requestSearchKeyword = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        [JYPromiseHelper.sharedInstance requestSearchKeywordWithQuery:self.workFlowStatus.query].then(^(NSString *searchKeyword) {
            NSLog(@"[jy] WorkFlow requestSearchKeyword searchKeyword: %@", searchKeyword);
            self.workFlowStatus.searchKeyword = searchKeyword;
            
            self.workFlowStatus.requestSearchKeyword = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }).catch(^(NSError *error) {
            NSLog(@"[jy] WorkFlow requestSearchKeyword error: %@", error);
            
            self.workFlowStatus.requestSearchKeyword = JYWorkFlowNodeStatusRejected;
            [self workFlowStatusDidUpdate];
        });
    }
    
    if (isFulfilled(self.workFlowStatus.requestSearchKeyword) &&
        isPending(self.workFlowStatus.requestSearchBaidu)) {
        self.workFlowStatus.requestSearchBaidu = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        [JYPromiseHelper.sharedInstance requestSearchWithKeyword:self.workFlowStatus.searchKeyword engine:JYMessageSearchEngineBaidu].then(^(NSArray<JYMessageSearchResult *> *resultList) {
            NSLog(@"[jy] WorkFlow requestSearchBaidu resultList: %@", resultList.yy_modelToJSONString);
            JYMessageSearch *message = [[JYMessageSearch alloc] init];
            message.engine = JYMessageSearchEngineBaidu;
            [message setResultList:resultList];
            self.workFlowStatus.searchMessageBaidu = message;
            
            self.workFlowStatus.requestSearchBaidu = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }).catch(^(NSError *error) {
            NSLog(@"[jy] WorkFlow requestSearchBaidu error: %@", error);
            
            self.workFlowStatus.requestSearchBaidu = JYWorkFlowNodeStatusRejected;
            [self workFlowStatusDidUpdate];
        });
    }
    
    if (isFulfilled(self.workFlowStatus.requestSearchKeyword) &&
        isPending(self.workFlowStatus.requestSearchSogou)) {
        self.workFlowStatus.requestSearchSogou = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        [JYPromiseHelper.sharedInstance requestSearchWithKeyword:self.workFlowStatus.searchKeyword engine:JYMessageSearchEngineSogou].then(^(NSArray<JYMessageSearchResult *> *resultList) {
            NSLog(@"[jy] WorkFlow requestSearchSogou resultList: %@", resultList.yy_modelToJSONString);
            JYMessageSearch *message = [[JYMessageSearch alloc] init];
            message.engine = JYMessageSearchEngineSogou;
            [message setResultList:resultList];
            self.workFlowStatus.searchMessageSogou = message;
            
            self.workFlowStatus.requestSearchSogou = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }).catch(^(NSError *error) {
            NSLog(@"[jy] WorkFlow requestSearchSogou error: %@", error);
            
            self.workFlowStatus.requestSearchSogou = JYWorkFlowNodeStatusRejected;
            [self workFlowStatusDidUpdate];
        });
    }
    
    if (isFulfilled(self.workFlowStatus.requestSearchKeyword) &&
        isPending(self.workFlowStatus.requestSearchToutiao)) {
        self.workFlowStatus.requestSearchToutiao = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        [JYPromiseHelper.sharedInstance requestSearchWithKeyword:self.workFlowStatus.searchKeyword engine:JYMessageSearchEngineToutiao].then(^(NSArray<JYMessageSearchResult *> *resultList) {
            NSLog(@"[jy] WorkFlow requestSearchToutiao resultList: %@", resultList.yy_modelToJSONString);
            JYMessageSearch *message = [[JYMessageSearch alloc] init];
            message.engine = JYMessageSearchEngineToutiao;
            [message setResultList:resultList];
            self.workFlowStatus.searchMessageToutiao = message;
            
            self.workFlowStatus.requestSearchToutiao = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }).catch(^(NSError *error) {
            NSLog(@"[jy] WorkFlow requestSearchToutiao error: %@", error);
            
            self.workFlowStatus.requestSearchToutiao = JYWorkFlowNodeStatusRejected;
            [self workFlowStatusDidUpdate];
        });
    }
    
    if (isFulfilled(self.workFlowStatus.requestSearchBaidu) &&
        isPending(self.workFlowStatus.requestWebContentBaidu)) {
        self.workFlowStatus.requestWebContentBaidu = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        NSArray<NSString *> *urlList = [self.workFlowStatus.searchMessageBaidu.resultList qmui_mapWithBlock:^id _Nonnull(JYMessageSearchResult *result, NSInteger index) {
            return result.url ?: @"";
        }];
        [JYPromiseHelper.sharedInstance requestWebContentListWithUrlList:urlList].then(^(NSArray<JYMessageSearchResult *> *resultList) {
            for (JYMessageSearchResult *result in resultList) {
                JYMessageSearchResult *originResult = [self.workFlowStatus.searchMessageBaidu.resultList qmui_firstMatchWithBlock:^BOOL(JYMessageSearchResult * _Nonnull item) {
                    return [item.url isEqualToString:result.url];
                }];
                if (originResult) {
                    originResult.content = result.content;
                }
            }
            NSLog(@"[jy] WorkFlow requestWebContentBaidu message: %@", self.workFlowStatus.searchMessageBaidu.resultList.yy_modelToJSONString);
            
            self.workFlowStatus.requestWebContentBaidu = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }).catch(^(NSError *error) {
            NSLog(@"[jy] WorkFlow requestWebContentBaidu error: %@", error);
            
            self.workFlowStatus.requestWebContentBaidu = JYWorkFlowNodeStatusRejected;
            [self workFlowStatusDidUpdate];
        });
    }
    
    if (isFulfilled(self.workFlowStatus.requestSearchSogou) &&
        isPending(self.workFlowStatus.requestWebContentSogou)) {
        self.workFlowStatus.requestWebContentSogou = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        NSArray<NSString *> *urlList = [self.workFlowStatus.searchMessageSogou.resultList qmui_mapWithBlock:^id _Nonnull(JYMessageSearchResult *result, NSInteger index) {
            return result.url ?: @"";
        }];
        [JYPromiseHelper.sharedInstance requestWebContentListWithUrlList:urlList].then(^(NSArray<JYMessageSearchResult *> *resultList) {
            for (JYMessageSearchResult *result in resultList) {
                JYMessageSearchResult *originResult = [self.workFlowStatus.searchMessageSogou.resultList qmui_firstMatchWithBlock:^BOOL(JYMessageSearchResult * _Nonnull item) {
                    return [item.url isEqualToString:result.url];
                }];
                if (originResult) {
                    originResult.content = result.content;
                }
            }
            NSLog(@"[jy] WorkFlow requestWebContentSogou message: %@", self.workFlowStatus.searchMessageSogou.resultList.yy_modelToJSONString);
            
            self.workFlowStatus.requestWebContentSogou = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }).catch(^(NSError *error) {
            NSLog(@"[jy] WorkFlow requestWebContentSogou error: %@", error);
            
            self.workFlowStatus.requestWebContentSogou = JYWorkFlowNodeStatusRejected;
            [self workFlowStatusDidUpdate];
        });
    }
    
    if (isFulfilled(self.workFlowStatus.requestSearchToutiao) &&
        isPending(self.workFlowStatus.requestWebContentToutiao)) {
        self.workFlowStatus.requestWebContentToutiao = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        NSArray<NSString *> *urlList = [self.workFlowStatus.searchMessageToutiao.resultList qmui_mapWithBlock:^id _Nonnull(JYMessageSearchResult *result, NSInteger index) {
            return result.url ?: @"";
        }];
        [JYPromiseHelper.sharedInstance requestWebContentListWithUrlList:urlList].then(^(NSArray<JYMessageSearchResult *> *resultList) {
            for (JYMessageSearchResult *result in resultList) {
                JYMessageSearchResult *originResult = [self.workFlowStatus.searchMessageToutiao.resultList qmui_firstMatchWithBlock:^BOOL(JYMessageSearchResult * _Nonnull item) {
                    return [item.url isEqualToString:result.url];
                }];
                if (originResult) {
                    originResult.content = result.content;
                }
            }
            NSLog(@"[jy] WorkFlow requestWebContentToutiao message: %@", self.workFlowStatus.searchMessageToutiao.resultList.yy_modelToJSONString);
            
            self.workFlowStatus.requestWebContentToutiao = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }).catch(^(NSError *error) {
            NSLog(@"[jy] WorkFlow requestWebContentToutiao error: %@", error);
            
            self.workFlowStatus.requestWebContentToutiao = JYWorkFlowNodeStatusRejected;
            [self workFlowStatusDidUpdate];
        });
    }
    
    if (isEnded(self.workFlowStatus.requestSearchBaidu) &&
        isEnded(self.workFlowStatus.requestSearchSogou) &&
        isEnded(self.workFlowStatus.requestSearchToutiao) &&
        isPending(self.workFlowStatus.generatePrompt)) {
        BOOL isSearchFulfilled = (isFulfilled(self.workFlowStatus.requestSearchBaidu) ||
                                  isFulfilled(self.workFlowStatus.requestSearchSogou) ||
                                  isFulfilled(self.workFlowStatus.requestSearchToutiao));
        if (self.workFlowStatus.enableOnlineSearch && isSearchFulfilled) {
            NSMutableString *reference = [NSMutableString string];
            self.workFlowStatus.generatePrompt = JYWorkFlowNodeStatusRunning;
            [self workFlowStatusDidUpdate];
            
            for (JYMessageSearchResult *result in self.workFlowStatus.searchMessageSogou.resultList) {
                if (result.title.length == 0 || result.url.length == 0 || result.content.length == 0) {
                    continue;
                }
                [reference appendFormat:@"## %@""\n""%@""\n", result.title, result.content];
            }
            for (JYMessageSearchResult *result in self.workFlowStatus.searchMessageToutiao.resultList) {
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
                                "%@""\n", self.workFlowStatus.query ?: @"", reference];
            self.workFlowStatus.prompt = prompt;
            
            self.workFlowStatus.generatePrompt = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }
        
        if (!self.workFlowStatus.enableOnlineSearch) {
            self.workFlowStatus.generatePrompt = JYWorkFlowNodeStatusRunning;
            [self workFlowStatusDidUpdate];
            
            NSString *prompt = [NSString stringWithFormat:@"# 角色""\n"
                                "你是一个专业的AI问答助手，请根据问题回答。""\n"
                                "# 问题""\n"
                                "%@""\n"
                                "# 参考资料""\n", self.workFlowStatus.query ?: @""];
            self.workFlowStatus.prompt = prompt;
            NSLog(@"[jy] WorkFlow generatePrompt prompt: %@", prompt);
            
            self.workFlowStatus.generatePrompt = JYWorkFlowNodeStatusFulfilled;
            [self workFlowStatusDidUpdate];
        }
    }
    
    if (isFulfilled(self.workFlowStatus.generatePrompt) &&
        isPending(self.workFlowStatus.requestReplyDeepseek)) {
        self.workFlowStatus.requestReplyDeepseek = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            JYMessageAI *message = [[JYMessageAI alloc] init];
            message.model = JYMessageAIModelDeepseek;
            self.workFlowStatus.aiMessageDeepseek = message;
            
            JYChatMessageAICell *cell = [[JYChatMessageAICell alloc] init];
            [cell refreshWithModel:JYMessageAIModelDeepseek];
            self.workFlowStatus.aiCellDeepseek = cell;
            [self workFlowStatusDidUpdate];
            
            [JYPromiseHelper.sharedInstance requestAIModelWithPrompt:self.workFlowStatus.prompt
                                                           aiMessage:message
                                                              aiCell:cell
                                                  enableDeepThinking:self.workFlowStatus.enableDeepThinking].then(^(JYMessageAI *aiMessage) {
                NSLog(@"[jy] WorkFlow requestReplyDeepseek aiMessage: %@", aiMessage.content);
                
                self.workFlowStatus.requestReplyDeepseek = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
            }).catch(^(NSError *error) {
                NSLog(@"[jy] WorkFlow requestReplyDeepseek error: %@", error);
                
                self.workFlowStatus.requestReplyDeepseek = JYWorkFlowNodeStatusRejected;
                [self workFlowStatusDidUpdate];
            });
        });
    }
    
    if (isFulfilled(self.workFlowStatus.generatePrompt) &&
        isPending(self.workFlowStatus.requestReplyDoubao)) {
        self.workFlowStatus.requestReplyDoubao = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            JYMessageAI *message = [[JYMessageAI alloc] init];
            message.model = JYMessageAIModelDoubao;
            self.workFlowStatus.aiMessageDoubao = message;
            
            JYChatMessageAICell *cell = [[JYChatMessageAICell alloc] init];
            [cell refreshWithModel:JYMessageAIModelDoubao];
            self.workFlowStatus.aiCellDoubao = cell;
            [self workFlowStatusDidUpdate];
            
            [JYPromiseHelper.sharedInstance requestAIModelWithPrompt:self.workFlowStatus.prompt
                                                           aiMessage:message
                                                              aiCell:cell
                                                  enableDeepThinking:self.workFlowStatus.enableDeepThinking].then(^(JYMessageAI *aiMessage) {
                NSLog(@"[jy] WorkFlow requestReplyDoubao aiMessage: %@", aiMessage.content);
                
                self.workFlowStatus.requestReplyDoubao = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
            }).catch(^(NSError *error) {
                NSLog(@"[jy] WorkFlow requestReplyDoubao error: %@", error);
                
                self.workFlowStatus.requestReplyDoubao = JYWorkFlowNodeStatusRejected;
                [self workFlowStatusDidUpdate];
            });
        });
    }
    
    if (isFulfilled(self.workFlowStatus.generatePrompt) &&
        isPending(self.workFlowStatus.requestReplyHunyuan)) {
        self.workFlowStatus.requestReplyHunyuan = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            JYMessageAI *message = [[JYMessageAI alloc] init];
            message.model = JYMessageAIModelHunyuan;
            self.workFlowStatus.aiMessageHunyuan = message;
            
            JYChatMessageAICell *cell = [[JYChatMessageAICell alloc] init];
            [cell refreshWithModel:JYMessageAIModelHunyuan];
            self.workFlowStatus.aiCellHunyuan = cell;
            [self workFlowStatusDidUpdate];
            
            [JYPromiseHelper.sharedInstance requestAIModelWithPrompt:self.workFlowStatus.prompt
                                                           aiMessage:message
                                                              aiCell:cell
                                                  enableDeepThinking:self.workFlowStatus.enableDeepThinking].then(^(JYMessageAI *aiMessage) {
                NSLog(@"[jy] WorkFlow requestReplyHunyuan aiMessage: %@", aiMessage.content);
                
                self.workFlowStatus.requestReplyHunyuan = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
            }).catch(^(NSError *error) {
                NSLog(@"[jy] WorkFlow requestReplyHunyuan error: %@", error);
                
                self.workFlowStatus.requestReplyHunyuan = JYWorkFlowNodeStatusRejected;
                [self workFlowStatusDidUpdate];
            });
        });
    }
    
    BOOL isReplyFulfilled = (isFulfilled(self.workFlowStatus.requestReplyDeepseek) ||
                             isFulfilled(self.workFlowStatus.requestReplyDoubao) ||
                             isFulfilled(self.workFlowStatus.requestReplyHunyuan));
    if (isEnded(self.workFlowStatus.requestReplyDeepseek) &&
        isEnded(self.workFlowStatus.requestReplyDoubao) &&
        isEnded(self.workFlowStatus.requestReplyHunyuan) &&
        isReplyFulfilled &&
        isPending(self.workFlowStatus.requestReplyMixed)) {
        self.workFlowStatus.requestReplyMixed = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        NSInteger replyCount = 0;
        NSMutableString *reply = [NSMutableString string];
        if (isFulfilled(self.workFlowStatus.requestReplyDeepseek)) {
            [reply appendFormat:@"# 回答%@""\n""%@""\n", @(++replyCount), self.workFlowStatus.aiMessageDoubao.content ?: @""];
        }
        if (isFulfilled(self.workFlowStatus.requestReplyDoubao)) {
            [reply appendFormat:@"# 回答%@""\n""%@""\n", @(++replyCount), self.workFlowStatus.aiMessageDoubao.content ?: @""];
        }
        if (isFulfilled(self.workFlowStatus.requestReplyHunyuan)) {
            [reply appendFormat:@"# 回答%@""\n""%@""\n", @(++replyCount), self.workFlowStatus.aiMessageHunyuan.content ?: @""];
        }
        
        NSString *prompt = [NSString stringWithFormat:@"# 角色""\n"
                            "你是一个擅长“答案汇总”的专家，你将会收到关于一个问题的多个答案，你需要对多个答案进行去重、整合等处理，输出一个最终答案。""\n"
                            "# 问题""\n"
                            "%@""\n", reply];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            JYMessageAI *message = [[JYMessageAI alloc] init];
            message.model = JYMessageAIModelMixed;
            self.workFlowStatus.aiMessageMixed = message;
            
            JYChatMessageAICell *cell = [[JYChatMessageAICell alloc] init];
            [cell refreshWithModel:JYMessageAIModelMixed];
            self.workFlowStatus.aiCellMixed = cell;
            [self workFlowStatusDidUpdate];
            
            [JYPromiseHelper.sharedInstance requestAIModelWithPrompt:prompt
                                                           aiMessage:message
                                                              aiCell:cell
                                                  enableDeepThinking:self.workFlowStatus.enableDeepThinking].then(^(JYMessageAI *aiMessage) {
                NSLog(@"[jy] WorkFlow requestReplyMixed aiMessage: %@", aiMessage.yy_modelToJSONString);
                
                self.workFlowStatus.requestReplyMixed = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
            }).catch(^(NSError *error) {
                NSLog(@"[jy] WorkFlow requestReplyMixed error: %@", error);
                
                self.workFlowStatus.requestReplyMixed = JYWorkFlowNodeStatusRejected;
                [self workFlowStatusDidUpdate];
            });
        });
    }
    
    if (isEnded(self.workFlowStatus.requestSearchBaidu) &&
        isPending(self.workFlowStatus.uiSearchBaidu)) {
        if (isFulfilled(self.workFlowStatus.requestSearchBaidu)) {
            self.workFlowStatus.uiSearchBaidu = JYWorkFlowNodeStatusRunning;
            [self workFlowStatusDidUpdate];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                JYChatMessageSearchCell *cell = [[JYChatMessageSearchCell alloc] init];
                [cell refreshWithEngine:JYMessageSearchEngineBaidu];
                [self.stackView addArrangedSubview:cell];
                [cell setResultList:self.workFlowStatus.searchMessageBaidu.resultList];
                @weakify(self);
                cell.stopAnimationAction = ^{
                    @strongify(self);
                    self.workFlowStatus.uiSearchBaidu = JYWorkFlowNodeStatusFulfilled;
                    [self workFlowStatusDidUpdate];
                };
                self.workFlowStatus.searchCellBaidu = cell;
                
                self.inputView.placeholder = [NSString stringWithFormat:@"%@ 搜索中", searchEngineDescription(JYMessageSearchEngineBaidu)];
                [self.inputView startPlaceholderLoading];
            });
        } else {
            self.workFlowStatus.uiSearchBaidu = JYWorkFlowNodeStatusSkipped;
            [self workFlowStatusDidUpdate];
        }
    }
    
    if (isEnded(self.workFlowStatus.uiSearchBaidu) &&
        isEnded(self.workFlowStatus.requestSearchSogou) &&
        isPending(self.workFlowStatus.uiSearchSogou)) {
        if (isFulfilled(self.workFlowStatus.requestSearchSogou)) {
            self.workFlowStatus.uiSearchSogou = JYWorkFlowNodeStatusRunning;
            [self workFlowStatusDidUpdate];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                JYChatMessageSearchCell *cell = [[JYChatMessageSearchCell alloc] init];
                [cell refreshWithEngine:JYMessageSearchEngineSogou];
                [self.stackView addArrangedSubview:cell];
                [cell setResultList:self.workFlowStatus.searchMessageSogou.resultList];
                @weakify(self);
                cell.stopAnimationAction = ^{
                    @strongify(self);
                    self.workFlowStatus.uiSearchSogou = JYWorkFlowNodeStatusFulfilled;
                    [self workFlowStatusDidUpdate];
                };
                self.workFlowStatus.searchCellSogou = cell;
                
                self.inputView.placeholder = [NSString stringWithFormat:@"%@ 搜索中", searchEngineDescription(JYMessageSearchEngineSogou)];
                [self.inputView startPlaceholderLoading];
            });
        } else {
            self.workFlowStatus.uiSearchSogou = JYWorkFlowNodeStatusSkipped;
            [self workFlowStatusDidUpdate];
        }
    }
    
    if (isEnded(self.workFlowStatus.uiSearchSogou) &&
        isEnded(self.workFlowStatus.requestSearchToutiao) &&
        isPending(self.workFlowStatus.uiSearchToutiao)) {
        if (isFulfilled(self.workFlowStatus.requestSearchToutiao)) {
            self.workFlowStatus.uiSearchToutiao = JYWorkFlowNodeStatusRunning;
            [self workFlowStatusDidUpdate];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                JYChatMessageSearchCell *cell = [[JYChatMessageSearchCell alloc] init];
                [cell refreshWithEngine:JYMessageSearchEngineToutiao];
                [self.stackView addArrangedSubview:cell];
                [cell setResultList:self.workFlowStatus.searchMessageToutiao.resultList];
                @weakify(self);
                cell.stopAnimationAction = ^{
                    @strongify(self);
                    self.workFlowStatus.uiSearchToutiao = JYWorkFlowNodeStatusFulfilled;
                    [self workFlowStatusDidUpdate];
                };
                self.workFlowStatus.searchCellToutiao = cell;
                
                self.inputView.placeholder = [NSString stringWithFormat:@"%@ 搜索中", searchEngineDescription(JYMessageSearchEngineToutiao)];
                [self.inputView startPlaceholderLoading];
            });
        } else {
            self.workFlowStatus.uiSearchToutiao = JYWorkFlowNodeStatusSkipped;
            [self workFlowStatusDidUpdate];
        }
    }
    
    if (isEnded(self.workFlowStatus.uiSearchToutiao) &&
        self.workFlowStatus.aiCellDeepseek &&
        isPending(self.workFlowStatus.uiReplyDeepseek)) {
        self.workFlowStatus.uiReplyDeepseek = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @weakify(self);
            self.workFlowStatus.aiCellDeepseek.stopAnimationAction = ^{
                @strongify(self);
                self.workFlowStatus.uiReplyDeepseek = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
            };
            [self.stackView addArrangedSubview:self.workFlowStatus.aiCellDeepseek];
            [self.workFlowStatus.aiCellDeepseek startAnimation];
            
            self.inputView.placeholder = [NSString stringWithFormat:@"%@ 生成中", aiModelDescription(JYMessageAIModelDeepseek)];
            [self.inputView startPlaceholderLoading];
        });
    }
    
    if (isEnded(self.workFlowStatus.uiReplyDeepseek) &&
        self.workFlowStatus.aiCellDoubao &&
        isPending(self.workFlowStatus.uiReplyDoubao)) {
        self.workFlowStatus.uiReplyDoubao = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @weakify(self);
            self.workFlowStatus.aiCellDoubao.stopAnimationAction = ^{
                @strongify(self);
                self.workFlowStatus.uiReplyDoubao = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
            };
            [self.stackView addArrangedSubview:self.workFlowStatus.aiCellDoubao];
            [self.workFlowStatus.aiCellDoubao startAnimation];
            
            self.inputView.placeholder = [NSString stringWithFormat:@"%@ 生成中", aiModelDescription(JYMessageAIModelDoubao)];
            [self.inputView startPlaceholderLoading];
        });
    }
    
    if (isEnded(self.workFlowStatus.uiReplyDoubao) &&
        self.workFlowStatus.aiCellHunyuan &&
        isPending(self.workFlowStatus.uiReplyHunyuan)) {
        self.workFlowStatus.uiReplyHunyuan = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @weakify(self);
            self.workFlowStatus.aiCellHunyuan.stopAnimationAction = ^{
                @strongify(self);
                self.workFlowStatus.uiReplyHunyuan = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
            };
            [self.stackView addArrangedSubview:self.workFlowStatus.aiCellHunyuan];
            [self.workFlowStatus.aiCellHunyuan startAnimation];
            
            self.inputView.placeholder = [NSString stringWithFormat:@"%@ 生成中", aiModelDescription(JYMessageAIModelHunyuan)];
            [self.inputView startPlaceholderLoading];
        });
    }
    
    if (isEnded(self.workFlowStatus.uiReplyHunyuan) &&
        self.workFlowStatus.aiCellMixed &&
        isPending(self.workFlowStatus.uiReplyMixed)) {
        self.workFlowStatus.uiReplyMixed = JYWorkFlowNodeStatusRunning;
        [self workFlowStatusDidUpdate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @weakify(self);
            self.workFlowStatus.aiCellMixed.stopAnimationAction = ^{
                @strongify(self);
                self.workFlowStatus.uiReplyMixed = JYWorkFlowNodeStatusFulfilled;
                [self workFlowStatusDidUpdate];
                
                self.inputView.placeholder = @"已完成回答，点击右上角开启新提问";
                [self.inputView stopPlaceholderLoading];
                [self stopScrollTimer];
                [self.scrollView qmui_scrollToBottomAnimated:NO];
            };
            [self.stackView addArrangedSubview:self.workFlowStatus.aiCellMixed];
            [self.workFlowStatus.aiCellMixed startAnimation];
            
            self.inputView.placeholder = [NSString stringWithFormat:@"%@ 生成中", aiModelDescription(JYMessageAIModelMixed)];
            [self.inputView startPlaceholderLoading];
        });
    }
}

#pragma mark - Scroll Timer

- (void)startScrollTimer {
    if (self.scrollTimer) {
        [self.scrollTimer invalidate];
        self.scrollTimer = nil;
    }
    @weakify(self);
    self.scrollTimer = [NSTimer timerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        @strongify(self);
        [self.scrollView qmui_scrollToBottomAnimated:NO];
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.scrollTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopScrollTimer {
    if (self.scrollTimer) {
        [self.scrollTimer invalidate];
        self.scrollTimer = nil;
    }
}

#pragma mark - Title Animation

- (void)startTitleAnimationWithLength:(NSInteger)length {
    NSString *title = @"请尽情向我提问～";
    if (length > title.length) {
        return;
    }
    self.titleLabel.text = [title substringToIndex:length];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startTitleAnimationWithLength:length + 1];
    });
}

#pragma mark - Getter

- (JYChatNavigationBar *)navBar {
    if (_navBar == nil) {
        JYChatNavigationBar *navBar = [[JYChatNavigationBar alloc] init];
        @weakify(self);
        navBar.newChatAction = ^{
            @strongify(self);
            [self onNewChat];
        };
        _navBar = navBar;
    }
    return _navBar;
}

- (JYChatInputView *)inputView {
    if (_inputView == nil) {
        JYChatInputView *inputView = [[JYChatInputView alloc] init];
        @weakify(self);
        inputView.sendAction = ^{
            @strongify(self);
            [self onSend];
        };
        _inputView = inputView;
    }
    return _inputView;
}

- (UIScrollView *)scrollView {
    if (_scrollView == nil) {
        UIScrollView *scrollView = [[UIScrollView alloc] init];
        scrollView.backgroundColor = UIColor.whiteColor;
        scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, 24, 0);
        scrollView.bounces = YES;
        _scrollView = scrollView;
    }
    return _scrollView;
}

- (UIStackView *)stackView {
    if (_stackView == nil) {
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.alignment = UIStackViewAlignmentFill;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.spacing = 0;
        _stackView = stackView;
    }
    return _stackView;
}

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:20];
        label.textColor = UIColor.firstTextColor;
        label.textAlignment = NSTextAlignmentCenter;
        _titleLabel = label;
    }
    return _titleLabel;
}

@end
