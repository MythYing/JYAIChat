//
//  JYChatMessageAICell.m
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import "JYChatMessageAICell.h"
#import "JYMacro.h"
#import <JYSegmentedLabel/JYSegmentedLabel.h>

@interface JYChatMessageAICell () <JYSegmentedLabelDelegate>

@property(nonatomic, strong) UIView *thoughtLineView;
@property(nonatomic, strong) JYSegmentedLabel *thoughtLabel;
@property(nonatomic, strong) JYSegmentedLabel *contentLabel;

@end

@implementation JYChatMessageAICell

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
    
    [self.contentView addSubview:self.thoughtLineView];
    [self.contentView addSubview:self.thoughtLabel];
    [self.contentView addSubview:self.contentLabel];
    
    [self.thoughtLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).inset(24);
        make.leading.trailing.equalTo(self.contentView).inset(36);
    }];
    [self.thoughtLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@2);
        make.top.bottom.equalTo(self.thoughtLabel);
        make.leading.equalTo(self.contentView).inset(24);
    }];
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.thoughtLabel.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self.contentView).inset(24);
        make.bottom.equalTo(self.contentView);
    }];
}

#pragma mark - Data

- (void)refreshWithMessage:(JYMessage *)message {
    if ([message.thought hasPrefix:self.thoughtLabel.text] || self.thoughtLabel.text.length == 0) {
        NSString *newText = [message.thought substringFromIndex:self.thoughtLabel.text.length];
        [self.thoughtLabel appendText:newText];
    }
    if ([message.content hasPrefix:self.contentLabel.text] || self.contentLabel.text.length == 0) {
        NSString *newText = [message.content substringFromIndex:self.contentLabel.text.length];
        [self.contentLabel appendText:newText];
    }
    [self setNeedsLayout];
}

#pragma mark - JYSegmentedLabelDelegate

- (void)segmentedLabel:(JYSegmentedLabel *)segmentedLabel configLabel:(UILabel *)label {
    if (segmentedLabel == self.thoughtLabel) {
        label.font = [UIFont systemFontOfSize:14];
        label.textColor = UIColor.thirdTextColor;
        label.numberOfLines = 0;
    } else if (segmentedLabel == self.contentLabel) {
        label.font = [UIFont systemFontOfSize:16];
        label.textColor = UIColor.firstTextColor;
        label.numberOfLines = 0;
    }
}

#pragma mark - Getter

- (UIView *)thoughtLineView {
    if (_thoughtLineView == nil) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = UIColor.separatorLineColor;
        _thoughtLineView = view;
    }
    return _thoughtLineView;
}

- (JYSegmentedLabel *)thoughtLabel {
    if (_thoughtLabel == nil) {
        JYSegmentedLabel *segmentedLabel = [[JYSegmentedLabel alloc] init];
        segmentedLabel.delegate = self;
        _thoughtLabel = segmentedLabel;
    }
    return _thoughtLabel;
}

- (JYSegmentedLabel *)contentLabel {
    if (_contentLabel == nil) {
        JYSegmentedLabel *segmentedLabel = [[JYSegmentedLabel alloc] init];
        segmentedLabel.delegate = self;
        _contentLabel = segmentedLabel;
    }
    return _contentLabel;
}

@end
