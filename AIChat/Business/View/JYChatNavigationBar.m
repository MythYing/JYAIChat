//
//  JYChatNavigationBar.m
//  AIChat
//
//  Created by JiangYing on 2025/10/4.
//

#import "JYChatNavigationBar.h"
#import "JYMacro.h"

@interface JYChatNavigationBar ()

@property(nonatomic, strong) UIView *topPlaceholderView;
@property (nonatomic, strong) UIView *navView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *newChatImageView;
@property(nonatomic, strong) UIView *bottomLineView;

@property(nonatomic, assign) CGFloat topPlaceholderHeight;

@end

@implementation JYChatNavigationBar

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _topPlaceholderHeight = 47;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithRGB:0xFAFAFA];
    
    [self addSubview:self.topPlaceholderView];
    [self addSubview:self.navView];
    [self.navView addSubview:self.titleLabel];
    [self.navView addSubview:self.newChatImageView];
    [self.navView addSubview:self.bottomLineView];
    
    [self.topPlaceholderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(self.topPlaceholderHeight));
        make.leading.trailing.top.equalTo(self);
    }];
    [self.navView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topPlaceholderView.mas_bottom);
        make.height.equalTo(@44);
        make.leading.trailing.bottom.equalTo(self);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.navView).inset(16);
        make.centerY.equalTo(self.navView);
    }];
    [self.newChatImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@44);
        make.centerY.equalTo(self.navView);
        make.trailing.equalTo(self.navView).inset(16);
    }];
    [self.bottomLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@1);
        make.leading.trailing.bottom.equalTo(self.navView);
    }];
}

- (void)didMoveToWindow {
    if (self.window) {
        CGFloat topInset = self.window.safeAreaInsets.top;
        if (topInset != self.topPlaceholderHeight) {
            self.topPlaceholderHeight = topInset;
            [self.topPlaceholderView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.equalTo(@(topInset));
            }];
            [self.topPlaceholderView setNeedsUpdateConstraints];
        }
    }
}

#pragma mark - Action

- (void)onNewChat {
    JY_SAFE_BLOCK(self.newChatAction);
}

#pragma mark - Getter

- (UIView *)topPlaceholderView {
    if (_topPlaceholderView == nil) {
        UIView *view = [[UIView alloc] init];
        _topPlaceholderView = view;
    }
    return _topPlaceholderView;
}

- (UIView *)navView {
    if (_navView == nil) {
        UIView *view = [[UIView alloc] init];
        _navView = view;
    }
    return _navView;
}

- (UIView *)titleLabel {
    if (_titleLabel == nil) {
        UILabel *label = [[UILabel alloc] init];
        label.text = @"超级AI助手";
        label.font = [UIFont qmui_mediumSystemFontOfSize:16];
        label.textColor = UIColor.firstTextColor;
        label.numberOfLines = 1;
        _titleLabel = label;
    }
    return _titleLabel;
}

- (UIImageView *)newChatImageView {
    if (_newChatImageView == nil) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = [UIImageMake(@"new_chat") imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        imageView.contentMode = UIViewContentModeCenter;
        imageView.tintColor = UIColor.firstTextColor;
        imageView.userInteractionEnabled = true;
        [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onNewChat)]];
        _newChatImageView = imageView;
    }
    return _newChatImageView;
}

- (UIView *)bottomLineView {
    if (_bottomLineView == nil) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = UIColor.separatorLineColor;
        _bottomLineView = view;
    }
    return _bottomLineView;
}

@end
