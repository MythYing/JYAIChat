//
//  JYChatMessageUserCell.m
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import "JYChatMessageUserCell.h"
#import "JYMacro.h"

@interface JYChatMessageUserCell ()

@property(nonatomic, strong) UIView *bubbleView;
@property(nonatomic, strong) UILabel *contentLabel;

@end

@implementation JYChatMessageUserCell

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.contentView.backgroundColor = UIColor.whiteColor;
    
    [self.contentView addSubview:self.bubbleView];
    [self.bubbleView addSubview:self.contentLabel];
    
    [self.bubbleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).inset(24);
        make.bottom.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).inset(24);
        make.width.lessThanOrEqualTo(@(SCREEN_WIDTH - 24 - 100));
    }];
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.bubbleView).inset(12);
    }];
}

#pragma mark - Data

- (void)refreshWithMessage:(JYMessageUser *)message {
    self.contentLabel.text = message.content;
    [self setNeedsLayout];
}

#pragma mark - Getter

- (UIView *)bubbleView {
    if (_bubbleView == nil) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor colorWithRGB:0xECECEC];
        view.layer.cornerRadius = 12;
        view.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner;
        _bubbleView = view;
    }
    return _bubbleView;
}

- (UILabel *)contentLabel {
    if (_contentLabel == nil) {
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:16];
        label.textColor = UIColor.firstTextColor;
        label.numberOfLines = 0;
        _contentLabel = label;
    }
    return _contentLabel;
}

@end
