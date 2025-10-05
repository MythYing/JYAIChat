//
//  JYChatInputOptionView.m
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import "JYChatInputOptionView.h"
#import "JYMacro.h"

@interface JYChatInputOptionView ()

@property(nonatomic, strong) UIImageView *iconImageView;
@property(nonatomic, strong) UILabel *titleLabel;

@end

@implementation JYChatInputOptionView

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.iconImageView];
    [self addSubview:self.titleLabel];
    
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@24);
        make.leading.equalTo(self);
        make.centerY.equalTo(self);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.iconImageView.mas_trailing).offset(4);
        make.trailing.equalTo(self);
        make.centerY.equalTo(self);
    }];
    
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSelect)]];
}

#pragma mark - Data

- (void)refreshWithImage:(UIImage *)image title:(NSString *)title {
    self.iconImageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.titleLabel.text = title;
}

#pragma mark - Action

- (void)onSelect {
    JY_SAFE_BLOCK(self.selectAction);
}

#pragma mark - Getter & Setter

- (UIImageView *)iconImageView {
    if (_iconImageView == nil) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.tintColor = UIColor.secondTextColor;
        _iconImageView = imageView;
    }
    return _iconImageView;
}

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont qmui_mediumSystemFontOfSize:14];
        label.textColor = UIColor.secondTextColor;
        _titleLabel = label;
    }
    return _titleLabel;
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    self.iconImageView.tintColor = isSelected ? UIColor.highlightColor : UIColor.secondTextColor;
    self.titleLabel.textColor = isSelected ? UIColor.highlightColor : UIColor.secondTextColor;
}

@end
