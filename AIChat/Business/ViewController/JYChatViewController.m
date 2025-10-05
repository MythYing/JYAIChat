//
//  JYChatViewController.m
//  AIChat
//
//  Created by JiangYing on 2025/10/3.
//

#import "JYChatViewController.h"
#import "JYMacro.h"
#import "JYChatNavigationBar.h"
#import "JYChatInputView.h"

@interface JYChatViewController ()

@property(nonatomic, strong) JYChatNavigationBar *navBar;
@property(nonatomic, strong) JYChatInputView *inputView;

@end

@implementation JYChatViewController

#pragma mark - Init

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
    
    [self.navBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
    }];
    [self.inputView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.leading.trailing.equalTo(self.view);
    }];
}

#pragma mark - Action

- (void)onNewChat {
    JYChatViewController *vc = [[JYChatViewController alloc] init];
    [self.navigationController setViewControllers:@[vc] animated:false];
}

- (void)onSend {
    NSString *text = self.inputView.textView.text;
    // TDJY: 发送消息逻辑
    self.inputView.textView.text = @"";
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

@end
