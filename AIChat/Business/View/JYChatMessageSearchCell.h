//
//  JYChatMessageSearchCell.h
//  AIChat
//
//  Created by JiangYing on 2025/10/8.
//

#import <UIKit/UIKit.h>
#import "JYModel.h"

@interface JYChatMessageSearchCell : UIView

@property(nonatomic, copy, nullable) void (^startAnimationAction)(void);
@property(nonatomic, copy, nullable) void (^stopAnimationAction)(void);

- (void)refreshWithEngine:(JYMessageSearchEngine)engine;

- (void)setResultList:(NSArray<JYMessageSearchResult *> *_Nonnull)resultList;

@end
