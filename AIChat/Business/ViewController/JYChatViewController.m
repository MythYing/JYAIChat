//
//  JYChatViewController.m
//  AIChat
//
//  Created by JiangYing on 2025/10/3.
//

#import "JYChatViewController.h"
#import "JYMacro.h"
#import "JYModel.h"
#import "JYChatNavigationBar.h"
#import "JYChatInputView.h"
#import "JYChatMessageUserCell.h"
#import "JYChatMessageAICell.h"
#import "JYChatMessageSearchCell.h"
#import <JYEventSource/EventSource.h>

@interface JYChatViewController ()

@property(nonatomic, strong) JYChatNavigationBar *navBar;
@property(nonatomic, strong) JYChatInputView *inputView;
@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) UIStackView *stackView;

@property(nonatomic, copy) YYThreadSafeArray *messageList;
@property(nonatomic, strong) EventSource *eventSource;

@property(nonatomic, assign) BOOL didFirstViewDidAppear;

@property(nonatomic, assign) JYMessageStatus status;
@property(nonatomic, copy) NSString *statusString;
@property(nonatomic, copy) NSString *loadingString;

@property(nonatomic, assign) BOOL didFinishReceive;

@property(nonatomic, strong) YYThreadSafeDictionary *searchMessageDic;
@property(nonatomic, strong) YYThreadSafeDictionary *searchCellDic;

@property(nonatomic, strong) YYThreadSafeDictionary *aiMessageDic;
@property(nonatomic, strong) YYThreadSafeDictionary *aiCellDic;

@property(nonatomic, strong) YYThreadSafeArray *aiCellAnimationQueue;
@property(nonatomic, strong) NSTimer *scrollTimer;

@end

@implementation JYChatViewController

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        _messageList = [YYThreadSafeArray array];
        _searchMessageDic = [YYThreadSafeDictionary dictionary];
        _searchCellDic = [YYThreadSafeDictionary dictionary];
        _aiMessageDic = [YYThreadSafeDictionary dictionary];
        _aiCellDic = [YYThreadSafeDictionary dictionary];
        _aiCellAnimationQueue = [YYThreadSafeArray array];
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
    
    [self setStatus:JYMessageStatusNone prefix:@""];
    
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
    
    JYMessageUser *userMessage = [[JYMessageUser alloc] init];
    userMessage.contentId = [NSUUID UUID].UUIDString.lowercaseString;
    userMessage.content = text;
    [self.messageList appendObject:userMessage];
    JYChatMessageUserCell *cell = [[JYChatMessageUserCell alloc] init];
    [cell refreshWithMessage:userMessage];
    [self.stackView addArrangedSubview:cell];
    [self setStatus:JYMessageStatusWaiting prefix:@""];
    [self startScrollTimer];
    
    // 消息和视图Dic置空
    [self.searchMessageDic removeAllObjects];
    [self.searchCellDic removeAllObjects];
    [self.aiMessageDic removeAllObjects];
    [self.aiCellDic removeAllObjects];
    [self.aiCellAnimationQueue removeAllObjects];
    self.didFinishReceive = NO;
    
    if (self.eventSource) {
        EventSource *eventSource = self.eventSource;
        self.eventSource = nil;
        [eventSource close];
    }
    
    EventSourceConfig *config = [[EventSourceConfig alloc] init];
    config.url = [NSURL URLWithString:JYHelper.workflowUrl];
    config.method = @"POST";
    config.headers = @{
        @"Authorization": JYHelper.authorization,
        @"Content-Type": @"application/json",
    };
    config.body = @{
        @"workflow_id": JYHelper.workflowId,
        @"workflow_version": JYHelper.workflowVersion,
        @"parameters": @{
            @"query": text ?: @"",
            @"enableDeepThinking": @(self.inputView.deepThinkingOptionView.isSelected),
            @"enableOnlineSearch": @(self.inputView.onlineSearchOptionView.isSelected),
        }
    }.jsonStringEncoded.dataValue;
    self.eventSource = [[EventSource alloc] initWithConfig:config];
    @weakify(self);
    [self.eventSource onMessage:^(EventSourceEvent *event) {
        @strongify(self);
        [self onSSEMessage:event];
    }];
    [self.eventSource onError:^(EventSourceEvent *event) {
        @strongify(self);
        if (self.eventSource) {
            [self.eventSource close];
            self.eventSource = nil;
            NSLog(@"[jy] SSE Error: \n event.error: %@", event.error);
        }
    }];
}

- (void)onSSEMessage:(EventSourceEvent *)event {
    NSLog(@"[jy] SSE Message: \n event.id: %@ \n event.event: %@ \n event.data: %@", event.id, event.event, event.data);
    if ([event.event isEqualToString:JYMessageEventDone]) {
        self.didFinishReceive = YES;
        
        EventSource *eventSource = self.eventSource;
        self.eventSource = nil;
        [eventSource close];
    } else if ([event.event isEqualToString:JYMessageEventMessage]) {
        JYCozeData *data = [JYCozeData modelWithJSON:event.data];
        NSArray<NSString *> *arr = [data.node_title componentsSeparatedByString:@"_"];
        if (arr.count == 2 && [arr[0] isEqualToString:JYMessageTypeNameSearch]) {
            JYMessageSearchEngine engine = [JYMessageSearch searchEngineFromEngineName:arr[1]];
            
            if (self.searchMessageDic[@(engine)] == nil) {
                JYMessageSearch *newMessage = [[JYMessageSearch alloc] init];
                newMessage.engine = engine;
                self.searchMessageDic[@(engine)] = newMessage;
                [self.messageList appendObject:newMessage];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    JYChatMessageSearchCell *cell = [[JYChatMessageSearchCell alloc] init];
                    [cell refreshWithMessage:newMessage];
                    self.searchCellDic[@(engine)] = cell;
                    
                    [self.stackView addArrangedSubview:cell];
                    [self setStatus:JYMessageStatusSearching prefix:[JYMessageSearch engineDescriptionWithSearchEngine:newMessage.engine]];
                });
            }
            JYMessageSearch *searchMessage = self.searchMessageDic[@(engine)];
            JYMessageSearchResult *result = [JYMessageSearchResult modelWithJSON:data.content];
            if (result.title.length == 0) {
                return;
            }
            [searchMessage appendResult:result];
            dispatch_async(dispatch_get_main_queue(), ^{
                JYChatMessageSearchCell *searchCell = self.searchCellDic[@(engine)];
                [searchCell appendResult:result];
            });
        } else if (arr.count == 4 || [arr[0] isEqualToString:JYMessageTypeNameAI]) {
            JYMessageAIModel aiModel = [JYMessageAI aiModelFromModelName:arr[2]];
            BOOL isContent = [arr[3] isEqualToString:JYMessageOutputContent];
            
            if (self.aiMessageDic[@(aiModel)] == nil) {
                JYMessageAI *newMessage = [[JYMessageAI alloc] init];
                newMessage.model = aiModel;
                self.aiMessageDic[@(aiModel)] = newMessage;
                [self.messageList appendObject:newMessage];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    JYChatMessageAICell *cell = [[JYChatMessageAICell alloc] init];
                    [cell refreshWithMessage:newMessage];
                    self.aiCellDic[@(aiModel)] = cell;
                    
                    [self.aiCellAnimationQueue appendObject:cell];
                    [self tryDequeueCellAnimation];
                });
            }
            JYMessageAI *aiMessage = self.aiMessageDic[@(aiModel)];
            if (!isContent) {
                BOOL isBegin = aiMessage.thought.length == 0;
                BOOL isEnd = data.node_is_finish;
                if (aiMessage.thoughtId.length == 0) {
                    aiMessage.thoughtId = data.node_execute_uuid;
                }
                NSString *thought = data.content ?: @"";
                if (isBegin) {
                    thought = [thought stringByTrimmingLeftCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
                if (isEnd) {
                    thought = [thought stringByTrimmingRightCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
                [aiMessage appendThought:thought];
                dispatch_async(dispatch_get_main_queue(), ^{
                    JYChatMessageAICell *aiCell = self.aiCellDic[@(aiModel)];
                    [aiCell appendThought:thought];
                    if (isEnd) {
                        [aiCell finishAppendThought];
                    }
                });
            } else {
                BOOL isBegin = aiMessage.content.length == 0;
                BOOL isEnd = data.node_is_finish;
                if (aiMessage.contentId.length == 0) {
                    aiMessage.contentId = data.node_execute_uuid;
                }
                NSString *content = data.content ?: @"";
                if (isBegin) {
                    content = [content stringByTrimmingLeftCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
                if (isEnd) {
                    content = [content stringByTrimmingRightCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
                [aiMessage appendContent:content];
                dispatch_async(dispatch_get_main_queue(), ^{
                    JYChatMessageAICell *aiCell = self.aiCellDic[@(aiModel)];
                    [aiCell appendContent:content];
                    if (isEnd) {
                        [aiCell finishAppendContent];
                    }
                });
            }
        }
    }
}

- (void)tryDequeueCellAnimation {
    JYChatMessageAICell *animatingCell = [self.aiCellAnimationQueue qmui_firstMatchWithBlock:^BOOL(JYChatMessageAICell *_Nonnull item) {
        return item.animationStatus == JYSegmentedLabelAnimationStatusAnimating;
    }];
    if (animatingCell) {
        return;
    }
    JYChatMessageAICell *cell = [self.aiCellAnimationQueue qmui_firstMatchWithBlock:^BOOL(JYChatMessageAICell *_Nonnull item) {
        return item.animationStatus == JYSegmentedLabelAnimationStatusNone;
    }];
    if (cell) {
        @weakify(self);
        @weakify(cell);
        cell.startThoughtAnimationAction = ^{
            @strongify(self);
            @strongify(cell);
            [self setStatus:JYMessageStatusAIThinking prefix:[JYMessageAI modelDescriptionWithAIModel:cell.model]];
        };
        cell.startContentAnimationAction = ^{
            @strongify(self);
            @strongify(cell);
            [self setStatus:JYMessageStatusAIReplying prefix:[JYMessageAI modelDescriptionWithAIModel:cell.model]];
        };
        cell.stopAnimationAction = ^{
            @strongify(self);
            [self tryDequeueCellAnimation];
        };
        [cell startAnimation];
        [self.stackView addArrangedSubview:cell];
    } else if (self.didFinishReceive) {
        [self setStatus:JYMessageStatusDone prefix:@""];
        [self stopScrollTimer];
        [self.scrollView qmui_scrollToBottomAnimated:NO];
    }
}

#pragma mark - Scroll Timer

- (void)startScrollTimer {
    if (self.scrollTimer) {
        return;
    }
    self.scrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                        target:self
                                                      selector:@selector(onScrollTimer)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)stopScrollTimer {
    [self.scrollTimer invalidate];
    self.scrollTimer = nil;
}

- (void)onScrollTimer {
    [self.scrollView qmui_scrollToBottomAnimated:NO];
}

#pragma mark - Status Loading

- (void)setStatus:(JYMessageStatus)status prefix:(NSString *)prefix {
    _status = status;
    switch (status) {
        case JYMessageStatusNone: {
            self.statusString = @"请输入文字进行提问";
            [self updatePlaceholderWithEnableLoading:NO];
            break;
        }
        case JYMessageStatusWaiting: {
            self.statusString = @"等待响应中";
            [self updatePlaceholderWithEnableLoading:YES];
            break;
        }
        case JYMessageStatusSearching: {
            self.statusString = [NSString stringWithFormat:@"%@ 搜索中", prefix ?: @""];
            [self updatePlaceholderWithEnableLoading:YES];
            break;
        }
        case JYMessageStatusAIThinking: {
            self.statusString = [NSString stringWithFormat:@"%@ 思考中", prefix ?: @""];
            [self updatePlaceholderWithEnableLoading:YES];
            break;
        }
        case JYMessageStatusAIReplying: {
            self.statusString = [NSString stringWithFormat:@"%@ 生成中", prefix ?: @""];
            [self updatePlaceholderWithEnableLoading:YES];
            break;
        }
        case JYMessageStatusDone: {
            self.statusString = @"已完成作答，点击右上角开启新提问";
            [self updatePlaceholderWithEnableLoading:NO];
            break;
        }
    }
}

- (void)updatePlaceholderWithEnableLoading:(BOOL)enableLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.loadingString = @"";
        self.inputView.placeholderLabel.text = [NSString stringWithFormat:@"%@%@", self.statusString, self.loadingString];
        if (enableLoading) {
            [self startLoadingWithStatusString:self.statusString];
        }
    });
}
    
- (void)startLoadingWithStatusString: (NSString *)statusString {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (![statusString isEqualToString:self.statusString]) {
            return;
        }
        if (self.loadingString.length < 3) {
            self.loadingString = [self.loadingString stringByAppendingString:@"."];
        } else {
            self.loadingString = @"";
        }
        self.inputView.placeholderLabel.text = [NSString stringWithFormat:@"%@%@", statusString, self.loadingString];
        [self startLoadingWithStatusString:statusString];
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

@end
