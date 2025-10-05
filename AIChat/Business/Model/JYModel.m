//
//  JYModel.m
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import "JYModel.h"

NSString *const JYMessageEventMessage = @"Message";
NSString *const JYMessageEventDone = @"Done";

NSString *const JYMessageModelNameMixed = @"mixed";
NSString *const JYMessageModelNameDeepseek = @"deepseek";
NSString *const JYMessageModelNameDoubao = @"doubao";

NSString *const JYMessageModelDeepThinking = @"think";
NSString *const JYMessageModelFast = @"fast";

NSString *const JYMessageOutputThought = @"thought";
NSString *const JYMessageOutputContent = @"content";


@implementation JYMessage

- (instancetype)init
{
    self = [super init];
    if (self) {
        _role = JYMessageRoleUnknown;
        _model = JYMessageModelNone;
        _thoughtId = @"";
        _thought = @"";
        _contentId = @"";
        _content = @"";
    }
    return self;
}

@end


@implementation JYCozeData

- (instancetype)init
{
    self = [super init];
    if (self) {
        _content = @"";
        _content_type = @"";
        _node_type = @"";
        _node_id = @"";
        _node_title = @"";
        _node_execute_uuid = @"";
        _node_seq_id = @"";
        _node_is_finish = NO;
    }
    return self;
}

@end
