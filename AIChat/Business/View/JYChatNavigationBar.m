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
@property(nonatomic, strong) UIView *navView;
@property(nonatomic, strong) UIView *titleView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *subtitleLabel;
@property(nonatomic, strong) UIImageView *newChatImageView;
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
    [self.navView addSubview:self.titleView];
    [self.titleView addSubview:self.titleLabel];
    [self.titleView addSubview:self.subtitleLabel];
    [self.navView addSubview:self.newChatImageView];
    [self.navView addSubview:self.bottomLineView];
    
    [self.topPlaceholderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(self.topPlaceholderHeight));
        make.leading.trailing.top.equalTo(self);
    }];
    [self.navView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topPlaceholderView.mas_bottom);
        make.height.equalTo(@48);
        make.leading.trailing.bottom.equalTo(self);
    }];
    [self.titleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.navView).inset(16);
        make.centerY.equalTo(self.navView);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.equalTo(self.titleView);
        make.trailing.lessThanOrEqualTo(self.titleView);
    }];
    [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(2);
        make.bottom.leading.equalTo(self.titleView);
        make.trailing.lessThanOrEqualTo(self.titleView);
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

- (UIView *)titleView {
    if (_titleView == nil) {
        UIView *view = [[UIView alloc] init];
        _titleView = view;
    }
    return _titleView;
}

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        UILabel *label = [[UILabel alloc] init];
        label.text = @"超级AI助手";
        label.font = [UIFont qmui_mediumSystemFontOfSize:14];
        label.textColor = UIColor.firstTextColor;
        label.numberOfLines = 1;
        _titleLabel = label;
    }
    return _titleLabel;
}

- (UILabel *)subtitleLabel {
    if (_subtitleLabel == nil) {
        UILabel *label = [[UILabel alloc] init];
        label.text = @"全网搜索+多模型回答";
        label.font = [UIFont systemFontOfSize:12];
        label.textColor = UIColor.thirdTextColor;
        label.numberOfLines = 1;
        _subtitleLabel = label;
    }
    return _subtitleLabel;
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
