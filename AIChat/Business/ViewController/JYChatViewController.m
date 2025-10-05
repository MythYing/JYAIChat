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
#import <JYEventSource/EventSource.h>
#import <JYNonReusableTableView/JYNonReusableTableView.h>

@interface JYChatViewController () <JYNonReusableTableViewDelegate, JYNonReusableTableViewDataSource>

@property(nonatomic, strong) JYChatNavigationBar *navBar;
@property(nonatomic, strong) JYChatInputView *inputView;
@property(nonatomic, strong) JYNonReusableTableView *messageTableView;

@property(nonatomic, copy) YYThreadSafeArray *messageList;
@property(nonatomic, strong) EventSource *eventSource;

@property(nonatomic, strong) JYMessage *deepseekMessage;
@property(nonatomic, strong) JYMessage *doubaoMessage;
@property(nonatomic, strong) JYMessage *mixedMessage;

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
    
    JYMessage *userMessage = [[JYMessage alloc] init];
    userMessage.role = JYMessageRoleUser;
    userMessage.model = JYMessageModelNone;
    userMessage.contentId = [NSUUID UUID].UUIDString.lowercaseString;
    userMessage.content = text;
    [self.messageList appendObject:userMessage];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messageList.count - 1 inSection:0];
    [self.messageTableView insertRowAtIndexPath:indexPath];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messageTableView qmui_scrollToBottomAnimated:NO];
    });
    
    // 消息清空
    self.deepseekMessage = nil;
    self.doubaoMessage = nil;
    self.mixedMessage = nil;
    
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
            @"deepThinking": @(self.inputView.deepThinkingOptionView.isSelected),
            @"modelDeepseek": @(YES),
            @"modelDoubao": @(YES),
            @"modelHunyuan": @(YES),
            @"query": text ?: @"",
            @"searchBaidu": @(YES),
            @"searchSougou": @(YES),
            @"searchToutiao": @(YES),
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
        // 消息清空
        self.deepseekMessage = nil;
        self.doubaoMessage = nil;
        self.mixedMessage = nil;
        
        EventSource *eventSource = self.eventSource;
        self.eventSource = nil;
        [eventSource close];
    } else if ([event.event isEqualToString:JYMessageEventMessage]) {
        JYCozeData *data = [JYCozeData modelWithJSON:event.data];
        NSArray<NSString *> *arr = [data.node_title componentsSeparatedByString:@"_"];
        if (arr.count != 3) {
            return;
        }
        NSString *model = arr[0];
        BOOL isContent = [arr[2] isEqualToString:JYMessageOutputContent];
        
        JYMessage *aiMessage;
        if ([model isEqualToString:JYMessageModelNameDeepseek]) {
            if (self.deepseekMessage == nil) {
                JYMessage *newMessage = [[JYMessage alloc] init];
                newMessage.role = JYMessageRoleAI;
                newMessage.model = JYMessageModelDeepseek;
                [self.messageList appendObject:newMessage];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messageList.count - 1 inSection:0];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.messageTableView insertRowAtIndexPath:indexPath];
                });
                self.deepseekMessage = newMessage;
            }
            aiMessage = self.deepseekMessage;
        } else if ([model isEqualToString:JYMessageModelNameDoubao]) {
            if (self.doubaoMessage == nil) {
                JYMessage *newMessage = [[JYMessage alloc] init];
                newMessage.role = JYMessageRoleAI;
                newMessage.model = JYMessageModelDoubao;
                [self.messageList appendObject:newMessage];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messageList.count - 1 inSection:0];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.messageTableView insertRowAtIndexPath:indexPath];
                });
                self.doubaoMessage = newMessage;
            }
            aiMessage = self.doubaoMessage;
        } else if ([model isEqualToString:JYMessageModelNameMixed]) {
            if (self.mixedMessage == nil) {
                JYMessage *newMessage = [[JYMessage alloc] init];
                newMessage.role = JYMessageRoleAI;
                newMessage.model = JYMessageModelMixed;
                [self.messageList appendObject:newMessage];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messageList.count - 1 inSection:0];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.messageTableView insertRowAtIndexPath:indexPath];
                });
                self.mixedMessage = newMessage;
            }
            aiMessage = self.mixedMessage;
        }
        if (aiMessage) {
            if (!isContent) {
                if (aiMessage.thoughtId.length == 0) {
                    aiMessage.thoughtId = data.node_execute_uuid;
                }
                if ([data.node_execute_uuid isEqualToString:aiMessage.thoughtId]) {
                    aiMessage.thought = [aiMessage.thought stringByAppendingString:data.content];
                }
            } else {
                if (aiMessage.contentId.length == 0) {
                    aiMessage.contentId = data.node_execute_uuid;
                }
                if ([data.node_execute_uuid isEqualToString:aiMessage.contentId]) {
                    aiMessage.content = [aiMessage.content stringByAppendingString:data.content];
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
    if (message.role == JYMessageRoleUser) {
        JYChatMessageUserCell *cell = [[JYChatMessageUserCell alloc] init];
        [cell refreshWithMessage:message];
        return cell;
    } else if (message.role == JYMessageRoleAI) {
        JYChatMessageAICell *cell = [[JYChatMessageAICell alloc] init];
        [cell refreshWithMessage:message];
        return cell;
    }
    return [[JYNonReusableTableViewCell alloc] init];
}

- (void)tableView:(JYNonReusableTableView *)tableView refreshCell:(JYNonReusableTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    JYMessage *message = [self.messageList objectOrNilAtIndex:indexPath.row];
    if (message == nil) {
        return;
    }
    if (message.role == JYMessageRoleUser) {
        JYChatMessageUserCell *castCell = (JYChatMessageUserCell *)([cell isKindOfClass:JYChatMessageUserCell.class] ? cell : nil);
        if (cell) {
            [castCell refreshWithMessage:message];
        }
    } else if (message.role == JYMessageRoleAI) {
        JYChatMessageAICell *castCell = (JYChatMessageAICell *)([cell isKindOfClass:JYChatMessageAICell.class] ? cell : nil);
        if (cell) {
            [castCell refreshWithMessage:message];
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
