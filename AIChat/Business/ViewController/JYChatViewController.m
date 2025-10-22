//
//  JYChatViewController.m
//  AIChat
//
//  Created by JiangYing on 2025/10/3.
//

#import "JYChatViewController.h"
#import "JYMacro.h"
#import "JYModel.h"
#import "JYWorkFlowStatus.h"
#import "JYChatNavigationBar.h"
#import "JYChatMessageUserCell.h"
#import "JYChatMessageAICell.h"
#import "JYChatMessageSearchCell.h"

#pragma mark - JYChatViewController

@interface JYChatViewController ()

@property(nonatomic, strong) JYChatNavigationBar *navBar;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) UIStackView *stackView;
@property(nonatomic, strong) JYChatInputView *inputView;

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
    
    self.workFlowStatus = [[JYWorkFlowStatus alloc] initWithVC:self];
    [self.workFlowStatus startWithQuery:text
                     enableDeepThinking:self.inputView.deepThinkingOptionView.isSelected
                     enableOnlineSearch:self.inputView.onlineSearchOptionView.isSelected];
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
