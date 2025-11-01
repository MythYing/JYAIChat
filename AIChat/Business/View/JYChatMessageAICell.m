//
//  JYChatMessageAICell.m
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import "JYChatMessageAICell.h"
#import "JYMacro.h"
#import "AIChat-Swift.h"
#import <JYSegmentedLabel/JYSegmentedLabel.h>

@interface JYChatMessageAICell () <JYSegmentedLabelDelegate>

@property(nonatomic, strong) UIImageView *iconImageView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) JYSegmentedLabel *thoughtLabel;
@property(nonatomic, strong) JYSegmentedLabel *contentLabel;
@property(nonatomic, strong) UIView *thoughtLineView;

@property(nonatomic, assign) JYChatMessageAICellAnimationStatus animationStatus;

@end

@implementation JYChatMessageAICell

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _animationStatus = JYChatMessageAICellAnimationStatusNone;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = UIColor.whiteColor;
    
    [self addSubview:self.iconImageView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.thoughtLineView];
    [self addSubview:self.thoughtLabel];
    [self addSubview:self.contentLabel];
    
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@24);
        make.top.leading.equalTo(self).inset(24);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.iconImageView);
        make.leading.equalTo(self.iconImageView.mas_trailing).offset(4);
        make.trailing.equalTo(self).inset(24);
    }];
    [self.thoughtLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.iconImageView.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self).inset(36);
    }];
    [self.thoughtLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@2);
        make.top.bottom.equalTo(self.thoughtLabel);
        make.leading.equalTo(self).inset(24);
    }];
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.thoughtLabel.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self).inset(24);
        make.bottom.equalTo(self);
    }];
}

#pragma mark - Data

- (void)refreshWithModel:(JYMessageAIModel)model {
    switch (model) {
        case JYMessageAIModelMixed:
            self.iconImageView.image = [UIImage imageNamed:@"model_mixed"];
            break;
        case JYMessageAIModelDeepseek:
            self.iconImageView.image = [UIImage imageNamed:@"model_deepseek"];
            break;
        case JYMessageAIModelDoubao:
            self.iconImageView.image = [UIImage imageNamed:@"model_doubao"];
            break;
        case JYMessageAIModelHunyuan:
            self.iconImageView.image = [UIImage imageNamed:@"model_hunyuan"];
            break;
        default:
            break;
    }
    self.titleLabel.text = [NSString stringWithFormat:@"%@ 生成结果：", aiModelDescription(model)];
}

- (void)appendThought:(NSString *)thought {
    if (thought.length == 0) {
        return;
    }
    [self.thoughtLabel appendText:thought];
    [self tryStartAnimation];
}

- (void)finishAppendThought {
    [self.thoughtLabel finishAppend];
}

- (void)appendContent:(NSString *)content {
    if (content.length == 0) {
        return;
    }
    [self.contentLabel appendText:content];
    [self tryStartAnimation];
}

- (void)finishAppendContent {
    [self.contentLabel finishAppend];
}

#pragma mark - Animation

- (void)startAnimation {
    self.animationStatus = JYChatMessageAICellAnimationStatusReady;
    [self tryStartAnimation];
}

- (void)tryStartAnimation {
    if (self.animationStatus != JYChatMessageAICellAnimationStatusReady) {
        return;
    }
    if (self.thoughtLabel.text.length == 0 && self.contentLabel.text.length == 0) {
        return;
    }
    self.animationStatus = JYChatMessageAICellAnimationStatusRunning;
    @weakify(self);
    self.thoughtLabel.startAnimationAction = ^{
        @strongify(self);
        JY_SAFE_BLOCK(self.startThoughtAnimationAction);
    };
    self.thoughtLabel.stopAnimationAction = ^{
        @strongify(self);
        JY_SAFE_BLOCK(self.stopThoughtAnimationAction);
        [self.contentLabel startAnimation];
    };
    self.contentLabel.startAnimationAction = ^{
        @strongify(self);
        JY_SAFE_BLOCK(self.startContentAnimationAction);
    };
    self.contentLabel.stopAnimationAction = ^{
        @strongify(self);
        JY_SAFE_BLOCK(self.stopContentAnimationAction);
        self.animationStatus = JYChatMessageAICellAnimationStatusFulfilled;
        if (self.stopAnimationAction) {
            self.stopAnimationAction();
        }
    };
    if (self.thoughtLabel.text.length > 0
        && self.thoughtLabel.animationStatus == JYSegmentedLabelAnimationStatusNone) {
        [self.thoughtLabel startAnimation];
        if (self.startAnimationAction) {
            self.startAnimationAction();
        }
    } else if (self.thoughtLabel.text.length == 0
               && self.contentLabel.text.length > 0
               && self.contentLabel.animationStatus == JYSegmentedLabelAnimationStatusNone) {
        [self.contentLabel startAnimation];
        if (self.startAnimationAction) {
            self.startAnimationAction();
        }
    }
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

- (NSAttributedString *)segmentedLabel:(JYSegmentedLabel *)segmentedLabel attributedStringWithMarkdown:(NSString *)markdown {
    if (segmentedLabel == self.thoughtLabel) {
        return [JYMarkdownParser parseThoughtWithMarkdown:markdown];
    } else {
        return [JYMarkdownParser parseContentWithMarkdown:markdown];
    }
}

#pragma mark - Getter

- (UIImageView *)iconImageView {
    if (_iconImageView == nil) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.tintColor = UIColor.firstTextColor;
        _iconImageView = imageView;
    }
    return _iconImageView;
}

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont qmui_mediumSystemFontOfSize:16];
        label.textColor = UIColor.firstTextColor;
        _titleLabel = label;
    }
    return _titleLabel;
}

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
