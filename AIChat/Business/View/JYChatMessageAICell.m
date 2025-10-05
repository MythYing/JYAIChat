//
//  JYChatMessageAICell.m
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import "JYChatMessageAICell.h"
#import "JYMacro.h"

@interface JYChatMessageAICell ()

@property(nonatomic, strong) UIView *thoughtLineView;
@property(nonatomic, strong) UILabel *thoughtLabel;
@property(nonatomic, strong) UILabel *contentLabel;

@end

@implementation JYChatMessageAICell

#pragma mark - Init

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
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
    self.thoughtLabel.text = message.thought;
    self.contentLabel.text = message.content;
}

#pragma mark - Class Method

static JYChatMessageAICell *calculateCell;

+ (CGFloat)cellHeightWithMessage:(JYMessage *)message {
    if (calculateCell == nil) {
        calculateCell = [[JYChatMessageAICell alloc] init];
    }
    [calculateCell refreshWithMessage:message];
    CGFloat height = [calculateCell.contentView systemLayoutSizeFittingSize:CGSizeMake(SCREEN_WIDTH, CGFLOAT_MAX) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
    return height;
}

+ (NSString *)identifier {
    return @"JYChatMessageAICell";
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

- (UILabel *)thoughtLabel {
    if (_thoughtLabel == nil) {
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:14];
        label.textColor = UIColor.thirdTextColor;
        label.numberOfLines = 0;
        _thoughtLabel = label;
    }
    return _thoughtLabel;
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
