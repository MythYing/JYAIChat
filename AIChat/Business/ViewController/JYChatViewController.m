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
#import <JYNonReusableTableView/JYNonReusableTableView.h>

@interface JYChatViewController () <JYNonReusableTableViewDelegate, JYNonReusableTableViewDataSource>

@property(nonatomic, strong) JYChatNavigationBar *navBar;
@property(nonatomic, strong) JYChatInputView *inputView;
@property(nonatomic, strong) JYNonReusableTableView *messageTableView;

@property(nonatomic, copy) YYThreadSafeArray *messageList;
@property(nonatomic, strong) EventSource *eventSource;

@property(nonatomic, assign) BOOL didFirstViewDidAppear;

@property(nonatomic, assign) JYMessageStatus status;
@property(nonatomic, copy) NSString *statusString;
@property(nonatomic, copy) NSString *loadingString;

@property(nonatomic, strong) JYMessageSearch *toutiaoSearchMessage;

@property(nonatomic, strong) JYMessageAI *deepseekAIMessage;
@property(nonatomic, strong) JYMessageAI *doubaoAIMessage;
@property(nonatomic, strong) JYMessageAI *mixedAIMessage;

@end

@implementation JYChatViewController

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        _messageList = [YYThreadSafeArray array];
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
    [self.view addSubview:self.messageTableView];
    
    [self.navBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
    }];
    [self.inputView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.leading.trailing.equalTo(self.view);
    }];
    [self.messageTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        make.top.equalTo(self.navBar.mas_bottom);
        make.bottom.equalTo(self.inputView.mas_top);
    }];
    
    [self.messageTableView reloadData];
    
    [self setStatus:JYMessageStatusNone prefix:@""];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

#pragma mark - Notification

- (void)keyboardWillShow:(NSNotification *)notification {
    [self.messageTableView qmui_scrollToBottomAnimated:YES];
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
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messageList.count - 1 inSection:0];
    [self.messageTableView insertRowAtIndexPath:indexPath];
    [self.messageTableView qmui_scrollToBottomAnimated:YES];
    [self setStatus:JYMessageStatusWaiting prefix:@""];
    
    // 消息清空
    self.deepseekAIMessage = nil;
    self.doubaoAIMessage = nil;
    self.mixedAIMessage = nil;
    
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
        [self setStatus:JYMessageStatusDone prefix:@""];
        // 消息清空
        self.deepseekAIMessage = nil;
        self.doubaoAIMessage = nil;
        self.mixedAIMessage = nil;
        
        EventSource *eventSource = self.eventSource;
        self.eventSource = nil;
        [eventSource close];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.messageTableView qmui_scrollToBottomAnimated:NO];
        });
    } else if ([event.event isEqualToString:JYMessageEventMessage]) {
        JYCozeData *data = [JYCozeData modelWithJSON:event.data];
        NSArray<NSString *> *arr = [data.node_title componentsSeparatedByString:@"_"];
        if (arr.count == 2 && [arr[0] isEqualToString:JYMessageTypeNameSearch]) {
            JYMessageSearchEngine engine = [JYMessageSearch searchEngineFromEngineName:arr[1]];
            
            JYMessageSearch *searchMessage;
            JYMessageSearch *newMessage;
            switch (engine) {
                case JYMessageSearchEngineToutiao: {
                    if (self.toutiaoSearchMessage == nil) {
                        newMessage = [[JYMessageSearch alloc] init];
                        newMessage.engine = JYMessageSearchEngineToutiao;
                        self.toutiaoSearchMessage = newMessage;
                    }
                    searchMessage = self.toutiaoSearchMessage;
                    break;
                }
                default: {
                    break;
                }
            }
            if (newMessage) {
                [self.messageList appendObject:newMessage];
                
                NSString *prefix = [JYMessageSearch engineDescriptionWithSearchEngine:newMessage.engine];
                [self setStatus:JYMessageStatusSearching prefix:prefix];
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messageList.count - 1 inSection:0];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.messageTableView insertRowAtIndexPath:indexPath];
                });
            }
            if (searchMessage) {
                JYMessageSearchResult *result = [JYMessageSearchResult modelWithJSON:data.content];
                [searchMessage appendResult:result];
                NSInteger index = [self.messageList indexOfObject:searchMessage];
                if (index != NSNotFound) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.messageTableView refreshRowAtIndexPath:indexPath];
                        [self.messageTableView qmui_scrollToBottomAnimated:NO];
                    });
                }
            }
        } else if (arr.count == 4 || [arr[0] isEqualToString:JYMessageTypeNameAI]) {
            JYMessageAIModel aiModel = [JYMessageAI aiModelFromModelName:arr[2]];
            BOOL isContent = [arr[3] isEqualToString:JYMessageOutputContent];
            
            JYMessageAI *aiMessage;
            JYMessageAI *newMessage;
            switch (aiModel) {
                case JYMessageAIModelMixed: {
                    if (self.mixedAIMessage == nil) {
                        newMessage = [[JYMessageAI alloc] init];
                        newMessage.model = JYMessageAIModelMixed;
                        self.mixedAIMessage = newMessage;
                    }
                    aiMessage = self.mixedAIMessage;
                    break;
                }
                case JYMessageAIModelDeepseek: {
                    if (self.deepseekAIMessage == nil) {
                        newMessage = [[JYMessageAI alloc] init];
                        newMessage.model = JYMessageAIModelDeepseek;
                        self.deepseekAIMessage = newMessage;
                    }
                    aiMessage = self.deepseekAIMessage;
                    break;
                }
                case JYMessageAIModelDoubao: {
                    if (self.doubaoAIMessage == nil) {
                        newMessage = [[JYMessageAI alloc] init];
                        newMessage.model = JYMessageAIModelDoubao;
                        self.doubaoAIMessage = newMessage;
                    }
                    aiMessage = self.doubaoAIMessage;
                    break;
                }
                default:
                    break;
            }
            if (newMessage) {
                [self.messageList appendObject:newMessage];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messageList.count - 1 inSection:0];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.messageTableView insertRowAtIndexPath:indexPath];
                });
            }
            if (aiMessage) {
                if (!isContent) {
                    BOOL isBegin = aiMessage.thought.length == 0;
                    BOOL isEnd = data.node_is_finish;
                    if (aiMessage.thoughtId.length == 0) {
                        aiMessage.thoughtId = data.node_execute_uuid;
                        NSString *prefix = [JYMessageAI modelDescriptionWithAIModel:aiMessage.model];
                        [self setStatus:JYMessageStatusAIThinking prefix:prefix];
                    }
                    if ([data.node_execute_uuid isEqualToString:aiMessage.thoughtId]) {
                        NSString *thought = data.content ?: @"";
                        if (isBegin) {
                            thought = [thought stringByTrimmingLeftCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        }
                        if (isEnd) {
                            thought = [thought stringByTrimmingRightCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        }
                        [aiMessage appendThought:thought];
                    }
                } else {
                    BOOL isBegin = aiMessage.content.length == 0;
                    BOOL isEnd = data.node_is_finish;
                    if (aiMessage.contentId.length == 0) {
                        aiMessage.contentId = data.node_execute_uuid;
                        NSString *prefix = [JYMessageAI modelDescriptionWithAIModel:aiMessage.model];
                        [self setStatus:JYMessageStatusAIReplying prefix:prefix];
                    }
                    if ([data.node_execute_uuid isEqualToString:aiMessage.contentId]) {
                        NSString *content = data.content ?: @"";
                        if (isBegin) {
                            content = [content stringByTrimmingLeftCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        }
                        if (isEnd) {
                            content = [content stringByTrimmingRightCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        }
                        [aiMessage appendContent:content];
                    }
                }
                NSInteger index = [self.messageList indexOfObject:aiMessage];
                if (index != NSNotFound) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.messageTableView refreshRowAtIndexPath:indexPath];
                        [self.messageTableView qmui_scrollToBottomAnimated:NO];
                    });
                }
            }
        }
    }
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

#pragma mark - JYNonReusableTableViewDelegate & JYNonReusableTableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(JYNonReusableTableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(JYNonReusableTableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messageList.count;
}

- (JYNonReusableTableViewCell *)tableView:(JYNonReusableTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JYMessage *message = [self.messageList objectOrNilAtIndex:indexPath.row];
    if (message == nil) {
        return [[JYNonReusableTableViewCell alloc] init];
    }
    switch (message.type) {
        case JYMessageTypeUser: {
            JYMessageUser *castMessage = JY_SAFE_CAST(message, JYMessageUser);
            JYChatMessageUserCell *cell = [[JYChatMessageUserCell alloc] init];
            [cell refreshWithMessage:castMessage];
            return cell;
        }
        case JYMessageTypeAI: {
            JYMessageAI *castMessage = JY_SAFE_CAST(message, JYMessageAI);
            JYChatMessageAICell *cell = [[JYChatMessageAICell alloc] init];
            [cell refreshWithMessage:castMessage];
            return cell;
        }
        case JYMessageTypeSearch: {
            JYMessageSearch *castMessage = JY_SAFE_CAST(message, JYMessageSearch);
            JYChatMessageSearchCell *cell = [[JYChatMessageSearchCell alloc] init];
            [cell refreshWithMessage:castMessage];
            return cell;
        }
        case JYMessageTypeUnknown: {
            return [[JYNonReusableTableViewCell alloc] init];
        }
    }
}

- (void)tableView:(JYNonReusableTableView *)tableView refreshCell:(JYNonReusableTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    JYMessage *message = [self.messageList objectOrNilAtIndex:indexPath.row];
    if (message == nil) {
        return;
    }
    switch (message.type) {
        case JYMessageTypeUser: {
            JYMessageUser *castMessage = JY_SAFE_CAST(message, JYMessageUser);
            JYChatMessageUserCell *castCell = JY_SAFE_CAST(cell, JYChatMessageUserCell);
            if (castMessage && castCell) {
                [castCell refreshWithMessage:castMessage];
            }
            break;
        }
        case JYMessageTypeAI: {
            JYMessageAI *castMessage = JY_SAFE_CAST(message, JYMessageAI);
            JYChatMessageAICell *castCell = JY_SAFE_CAST(cell, JYChatMessageAICell);
            if (castMessage && castCell) {
                [castCell refreshWithMessage:castMessage];
            }
            break;
        }
        case JYMessageTypeSearch: {
            JYMessageSearch *castMessage = JY_SAFE_CAST(message, JYMessageSearch);
            JYChatMessageSearchCell *castCell = JY_SAFE_CAST(cell, JYChatMessageSearchCell);
            if (castMessage && castCell) {
                [castCell refreshWithMessage:castMessage];
            }
            break;
        }
        case JYMessageTypeUnknown: {
            break;
        }
    }
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

- (JYNonReusableTableView *)messageTableView {
    if (_messageTableView == nil) {
        JYNonReusableTableView *tableView = [[JYNonReusableTableView alloc] init];
        tableView.backgroundColor = UIColor.whiteColor;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 24, 0);
        tableView.bounces = YES;
        _messageTableView = tableView;
    }
    return _messageTableView;
}

@end
