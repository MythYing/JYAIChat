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

@interface JYChatViewController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) JYChatNavigationBar *navBar;
@property(nonatomic, strong) JYChatInputView *inputView;
@property(nonatomic, strong) UITableView *messageTableView;

@property(nonatomic, copy) NSArray<JYMessage *> *messageList;

@end

@implementation JYChatViewController

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (self) {
        _messageList = @[];
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
    
    
    // TDJY: 发送消息逻辑
    JYMessage *userMessage = [[JYMessage alloc] init];
    userMessage.role = JYMessageRoleUser;
    userMessage.content = text;
    
    JYMessage *aiMessage = [[JYMessage alloc] init];
    aiMessage.role = JYMessageRoleAI;
    aiMessage.thought = @"模拟AI的思考过程...\n模拟AI的思考过程...\n模拟AI的思考过程...\n模拟AI的思考过程...";
    aiMessage.content = @"模拟AI的回复...\n模拟AI的回复...\n模拟AI的回复...\n模拟AI的回复...\n模拟AI的回复...\n模拟AI的回复...\n模拟AI的回复...\n模拟AI的回复...";
    
    NSMutableArray *newMessageList = [NSMutableArray arrayWithArray:self.messageList];
    [newMessageList addObject:userMessage];
    [newMessageList addObject:aiMessage];
    self.messageList = [newMessageList copy];
    
    [self.messageTableView reloadData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messageTableView scrollToBottomAnimated:YES];
    });
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
