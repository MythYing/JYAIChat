//
//  JYChatInputView.m
//  AIChat
//
//  Created by JiangYing on 2025/10/4.
//

#import "JYChatInputView.h"
#import "JYMacro.h"

@interface JYChatInputView () <UITextViewDelegate, QMUIKeyboardManagerDelegate>

@property(nonatomic, strong) UIView *topLineView;
@property(nonatomic, strong) UILabel *placeholderLabel;
@property(nonatomic, strong) UIView *optionListView;
@property(nonatomic, strong) UIView *keyboardPlaceholderView;
@property(nonatomic, strong) UIView *bottomPlaceholderView;

@property(nonatomic, strong) QMUIKeyboardManager *keyboardManager;
@property(nonatomic, assign) CGFloat textViewHeight;
@property(nonatomic, assign) CGFloat keyboardPlaceholderHeight;
@property(nonatomic, assign) CGFloat bottomPlaceholderHeight;

@end

@implementation JYChatInputView

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _textViewHeight = 44;
        _keyboardPlaceholderHeight = 0;
        _bottomPlaceholderHeight = 34;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithRGB:0xFAFAFA];
    
    [self addSubview:self.topLineView];
    [self addSubview:self.textView];
    [self addSubview:self.placeholderLabel];
    [self addSubview:self.optionListView];
    [self addSubview:self.keyboardPlaceholderView];
    [self addSubview:self.bottomPlaceholderView];
    
    [self.optionListView addSubview:self.deepThinkingOptionView];
    [self.optionListView addSubview:self.onlineSearchOptionView];
    
    [self.topLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@1);
        make.leading.trailing.top.equalTo(self);
    }];
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self).inset(16);
        make.top.equalTo(self).inset(12);
        make.height.equalTo(@(self.textViewHeight));
    }];
    [self.placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.textView);
        make.leading.trailing.equalTo(self.textView).inset(12);
        make.height.equalTo(@44);
    }];
    [self.optionListView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self).inset(16);
        make.top.equalTo(self.textView.mas_bottom).offset(8);
        make.height.equalTo(@24);
    }];
    [self.keyboardPlaceholderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self);
        make.top.equalTo(self.optionListView.mas_bottom).offset(12);
        make.height.equalTo(@(self.keyboardPlaceholderHeight));
    }];
    [self.bottomPlaceholderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self);
        make.top.equalTo(self.keyboardPlaceholderView.mas_bottom);
        make.height.equalTo(@(self.bottomPlaceholderHeight));
        make.bottom.equalTo(self);
    }];
    
    [self.deepThinkingOptionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.equalTo(self.optionListView);
    }];
    [self.onlineSearchOptionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.deepThinkingOptionView.mas_trailing).offset(12);
        make.top.bottom.equalTo(self.optionListView);
    }];
    
    self.keyboardManager = [[QMUIKeyboardManager alloc] initWithDelegate:self];
}

- (void)didMoveToWindow {
    if (self.window) {
        CGFloat bottomInset = self.window.safeAreaInsets.bottom;
        if (bottomInset != self.bottomPlaceholderHeight) {
            self.bottomPlaceholderHeight = bottomInset;
            [self.bottomPlaceholderView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.equalTo(@(bottomInset));
            }];
            [self.bottomPlaceholderView setNeedsUpdateConstraints];
        }
    }
}

#pragma mark - Action

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.placeholderLabel.hidden = YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    self.placeholderLabel.hidden = self.textView.text.length > 0;
}

- (void)textViewDidChange:(UITextView *)textView {
    CGFloat height = [textView sizeThatFits:CGSizeMake(SCREEN_WIDTH - 32, CGFLOAT_MAX)].height;
    height = fmin(fmax(height, 44), 120);
    if (height != self.textViewHeight) {
        self.textViewHeight = height;
        [self.textView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(height));
        }];
        [self.textView setNeedsUpdateConstraints];
    }
    self.placeholderLabel.hidden = self.textView.text.length > 0 || self.textView.isFirstResponder;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        if (textView.text.length > 0) {
            JY_SAFE_BLOCK(self.sendAction);
        }
        return NO;
    }
    return YES;
}

#pragma mark - QMUIKeyboardManagerDelegate

- (void)keyboardWillShowWithUserInfo:(QMUIKeyboardUserInfo *)keyboardUserInfo {
    [self handleKeyboardWillChangeFrameWithUserInfo:keyboardUserInfo endFrameHeight:keyboardUserInfo.endFrame.size.height];
}

- (void)keyboardWillHideWithUserInfo:(QMUIKeyboardUserInfo *)keyboardUserInfo {
    [self handleKeyboardWillChangeFrameWithUserInfo:keyboardUserInfo endFrameHeight:0];
}

- (void)keyboardWillChangeFrameWithUserInfo:(QMUIKeyboardUserInfo *)keyboardUserInfo {
    [self handleKeyboardWillChangeFrameWithUserInfo:keyboardUserInfo endFrameHeight:keyboardUserInfo.endFrame.size.height];
}

- (void)handleKeyboardWillChangeFrameWithUserInfo:(QMUIKeyboardUserInfo *)keyboardUserInfo endFrameHeight:(CGFloat)endFrameHeight {
    CGFloat bottomInset = JYUIHelper.getKeyWindow.safeAreaInsets.bottom;
    CGFloat height = fmax(endFrameHeight - bottomInset, 0);
    if (self.keyboardPlaceholderHeight != height) {
        self.keyboardPlaceholderHeight = height;
        [UIView animateWithDuration:keyboardUserInfo.animationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.keyboardPlaceholderView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.equalTo(@(height));
            }];
            [self.keyboardPlaceholderView layoutIfNeeded];
        } completion:nil];
    }
}

#pragma mark - Getter

- (UIView *)topLineView {
    if (_topLineView == nil) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = UIColor.separatorLineColor;
        _topLineView = view;
    }
    return _topLineView;
}

- (UITextView *)textView {
    if (_textView == nil) {
        UITextView *textView = [[UITextView alloc] init];
//        textView.font = [UIFont systemFontOfSize:14];
//        textView.textColor = UIColor.firstTextColor;
        textView.backgroundColor = UIColor.whiteColor;
//        textView.placeholder = @"请输入文字";
//        textView.placeholderColor = UIColor.placeholderColor;
        textView.returnKeyType = UIReturnKeySend;
        textView.textContainerInset = UIEdgeInsetsMake(12, 12, 12, 12);
        textView.layer.cornerRadius = 22;
        textView.layer.borderColor = UIColor.separatorLineColor.CGColor;
        textView.layer.borderWidth = 1;
        textView.clipsToBounds = true;
        textView.delegate = self;
        textView.typingAttributes = @{
            NSFontAttributeName: [UIFont systemFontOfSize:14],
            NSParagraphStyleAttributeName: [NSMutableParagraphStyle qmui_paragraphStyleWithLineHeight:20],
            NSForegroundColorAttributeName: UIColor.firstTextColor,
            NSBaselineOffsetAttributeName: @((20 - [UIFont systemFontOfSize:14].lineHeight) / 2),
        };
        _textView = textView;
    }
    return _textView;
}

- (UILabel *)placeholderLabel {
    if (_placeholderLabel == nil) {
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:14];
        label.textColor = UIColor.placeholderColor;
        label.text = @"请输入文字进行提问";
        _placeholderLabel = label;
    }
    return _placeholderLabel;
}

- (UIView *)optionListView {
    if (_optionListView == nil) {
        UIView *view = [[UIView alloc] init];
        _optionListView = view;
    }
    return _optionListView;
}

- (JYChatInputOptionView *)deepThinkingOptionView {
    if (_deepThinkingOptionView == nil) {
        JYChatInputOptionView *optionView = [[JYChatInputOptionView alloc] init];
        [optionView refreshWithImage:UIImageMake(@"deep_thinking") title:@"深度思考"];
        optionView.isSelected = true;
        @weakify(self);
        optionView.selectAction = ^{
            @strongify(self);
            self.deepThinkingOptionView.isSelected = !self.deepThinkingOptionView.isSelected;
        };
        _deepThinkingOptionView = optionView;
    }
    return _deepThinkingOptionView;
}

- (JYChatInputOptionView *)onlineSearchOptionView {
    if (_onlineSearchOptionView == nil) {
        JYChatInputOptionView *optionView = [[JYChatInputOptionView alloc] init];
        [optionView refreshWithImage:UIImageMake(@"online_search") title:@"联网搜索"];
        optionView.isSelected = true;
        @weakify(self);
        optionView.selectAction = ^{
            @strongify(self);
            self.onlineSearchOptionView.isSelected = !self.onlineSearchOptionView.isSelected;
        };
        _onlineSearchOptionView = optionView;
    }
    return _onlineSearchOptionView;
}

- (UIView *)keyboardPlaceholderView {
    if (_keyboardPlaceholderView == nil) {
        UIView *view = [[UIView alloc] init];
        _keyboardPlaceholderView = view;
    }
    return _keyboardPlaceholderView;
}

- (UIView *)bottomPlaceholderView {
    if (_bottomPlaceholderView == nil) {
        UIView *view = [[UIView alloc] init];
        _bottomPlaceholderView = view;
    }
    return _bottomPlaceholderView;
}

@end
