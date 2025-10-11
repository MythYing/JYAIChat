//
//  JYChatMessageSearchCell.m
//  AIChat
//
//  Created by JiangYing on 2025/10/8.
//

#import "JYChatMessageSearchCell.h"
#import "JYMacro.h"
#import <SafariServices/SafariServices.h>

@interface JYChatMessageSearchCell ()

@property(nonatomic, strong) UIImageView *iconImageView;
@property(nonatomic, strong) UILabel *titleLabel;

@property(nonatomic, strong) UIStackView *stackView;

@end

@implementation JYChatMessageSearchCell

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = UIColor.whiteColor;
    
    [self addSubview:self.iconImageView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.stackView];
    
    [self.iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@24);
        make.top.leading.equalTo(self).inset(24);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.iconImageView);
        make.leading.equalTo(self.iconImageView.mas_trailing).offset(4);
        make.trailing.equalTo(self).inset(24);
    }];
    [self.stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.iconImageView.mas_bottom).offset(12);
        make.leading.trailing.equalTo(self).inset(24);
        make.bottom.equalTo(self);
    }];
}

#pragma mark - Data

- (void)refreshWithMessage:(JYMessageSearch *)message {
    switch (message.engine) {
        case JYMessageSearchEngineToutiao:
            self.iconImageView.image = [UIImage imageNamed:@"search_toutiao"];
            break;
        case JYMessageSearchEngineBaidu:
            self.iconImageView.image = [UIImage imageNamed:@"search_baidu"];
            break;
        case JYMessageSearchEngineSogou:
            self.iconImageView.image = [UIImage imageNamed:@"search_sogou"];
            break;
        default:
            self.iconImageView.image = nil;
            break;
    }
    NSString *engineDescription = [JYMessageSearch engineDescriptionWithSearchEngine:message.engine];
    self.titleLabel.text = [NSString stringWithFormat:@"%@ 搜索结果：", engineDescription];
}

- (void)appendResult:(JYMessageSearchResult *)result {
    UILabel *label = [self makeNewLabel];
    label.text = result.title;
    label.userInteractionEnabled = YES;
    [self.stackView addArrangedSubview:label];
    
    NSString *urlString = result.url;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithActionBlock:^(id  _Nonnull sender) {
        [self onSelectUrl:urlString];
    }];
    [label addGestureRecognizer:tap];
}

- (UILabel *)makeNewLabel {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = UIColor.firstTextColor;
    label.numberOfLines = 1;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.qmui_textAttributes = @{
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };
    return label;
}

#pragma mark - Action

- (void)onSelectUrl:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url];
        safariVC.modalPresentationStyle = UIModalPresentationPageSheet;
        UIViewController *topVC = [UIApplication sharedApplication].delegate.window.rootViewController;
        [topVC presentViewController:safariVC animated:YES completion:nil];
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

- (UIStackView *)stackView {
    if (_stackView == nil) {
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.alignment = UIStackViewAlignmentFill;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.spacing = 8;
        _stackView = stackView;
    }
    return _stackView;
}

@end
