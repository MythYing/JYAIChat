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

@interface JYChatViewController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) JYChatNavigationBar *navBar;
@property(nonatomic, strong) JYChatInputView *inputView;
@property(nonatomic, strong) UITableView *messageTableView;

@property(nonatomic, copy) YYThreadSafeArray *messageList;
@property(nonatomic, strong) EventSource *eventSource;
@property(nonatomic, assign) NSTimeInterval lastTimeReloadTableView;

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
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

#pragma mark - Notification

- (void)keyboardWillShow:(NSNotification *)notification {
    [self.messageTableView scrollToBottomAnimated:YES];
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
    
    JYMessage *userMessage = [[JYMessage alloc] init];
    userMessage.role = JYMessageRoleUser;
    userMessage.model = JYMessageModelNone;
    userMessage.contentId = [NSUUID UUID].UUIDString.lowercaseString;
    userMessage.content = text;
    [self.messageList appendObject:userMessage];
    
    [self.messageTableView reloadData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messageTableView scrollToBottomAnimated:YES];
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.messageTableView reloadData];
            [self.messageTableView scrollToBottomAnimated:NO];
        });
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
                self.deepseekMessage = newMessage;
            }
            aiMessage = self.deepseekMessage;
        } else if ([model isEqualToString:JYMessageModelNameDoubao]) {
            if (self.doubaoMessage == nil) {
                JYMessage *newMessage = [[JYMessage alloc] init];
                newMessage.role = JYMessageRoleAI;
                newMessage.model = JYMessageModelDoubao;
                [self.messageList appendObject:newMessage];
                self.doubaoMessage = newMessage;
            }
            aiMessage = self.doubaoMessage;
        } else if ([model isEqualToString:JYMessageModelNameMixed]) {
            if (self.mixedMessage == nil) {
                JYMessage *newMessage = [[JYMessage alloc] init];
                newMessage.role = JYMessageRoleAI;
                newMessage.model = JYMessageModelMixed;
                [self.messageList appendObject:newMessage];
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
        }
        NSTimeInterval now = NSDate.date.timeIntervalSince1970;
        if (now - self.lastTimeReloadTableView >= 0.5) {
            self.lastTimeReloadTableView = now;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.messageTableView reloadData];
                [self.messageTableView scrollToBottomAnimated:NO];
            });
        }
    }
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messageList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    JYMessage *message = [self.messageList objectOrNilAtIndex:indexPath.row];
    if (message == nil) {
        return 0;
    }
    if (message.role == JYMessageRoleUser) {
        return [JYChatMessageUserCell cellHeightWithMessage:message];
    } else if (message.role == JYMessageRoleAI) {
        return [JYChatMessageAICell cellHeightWithMessage:message];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JYMessage *message = [self.messageList objectOrNilAtIndex:indexPath.row];
    if (message == nil) {
        return nil;
    }
    if (message.role == JYMessageRoleUser) {
        JYChatMessageUserCell *cell = [tableView dequeueReusableCellWithIdentifier:JYChatMessageUserCell.identifier forIndexPath:indexPath];
        [cell refreshWithMessage:message];
        return cell;
    } else if (message.role == JYMessageRoleAI) {
        JYChatMessageAICell *cell = [tableView dequeueReusableCellWithIdentifier:JYChatMessageAICell.identifier forIndexPath:indexPath];
        [cell refreshWithMessage:message];
        return cell;
    }
    return nil;
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

- (UITableView *)messageTableView {
    if (_messageTableView == nil) {
        UITableView *tableView = [[UITableView alloc] init];
        tableView.backgroundColor = UIColor.whiteColor;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 24, 0);
        tableView.bounces = YES;
        tableView.estimatedRowHeight = 0;
        tableView.estimatedSectionHeaderHeight = 0;
        tableView.estimatedSectionFooterHeight = 0;
        [tableView registerClass:JYChatMessageUserCell.class forCellReuseIdentifier:JYChatMessageUserCell.identifier];
        [tableView registerClass:JYChatMessageAICell.class forCellReuseIdentifier:JYChatMessageAICell.identifier];
        _messageTableView = tableView;
    }
    return _messageTableView;
}

@end
