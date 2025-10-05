//
//  JYModel.h
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    JYMessageRoleUnknown = 0,
    JYMessageRoleUser = 1,
    JYMessageRoleAI = 2,
} JYMessageRole;

@interface JYMessage : NSObject

@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, assign) JYMessageRole role;
@property(nonatomic, copy) NSString *thought;
@property(nonatomic, copy) NSString *content;

@end
