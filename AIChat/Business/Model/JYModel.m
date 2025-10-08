//
//  JYModel.m
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import "JYModel.h"

NSString *const JYMessageEventMessage = @"Message";
NSString *const JYMessageEventDone = @"Done";

NSString *const JYMessageTypeNameUser = @"user";
NSString *const JYMessageTypeNameAI = @"ai";
NSString *const JYMessageTypeNameSearch = @"search";

NSString *const JYMessageModelNameMixed = @"mixed";
NSString *const JYMessageModelNameDeepseek = @"deepseek";
NSString *const JYMessageModelNameDoubao = @"doubao";
NSString *const JYMessageModelNameHunyuan = @"hunyuan";

NSString *const JYMessageModelDeepThinking = @"think";
NSString *const JYMessageModelFast = @"fast";

NSString *const JYMessageOutputThought = @"thought";
NSString *const JYMessageOutputContent = @"content";

NSString *const JYMessageSearchEngineNameToutiao = @"toutiao";
NSString *const JYMessageSearchEngineNameBaidu = @"baidu";
NSString *const JYMessageSearchEngineNameSogou = @"sogou";

#pragma mark - JYMessage

@interface JYMessage ()

@property(nonatomic, assign, readwrite) JYMessageType type;
@property(nonatomic, strong) NSLock *lock;

@end

@implementation JYMessage

- (instancetype)init
{
    self = [super init];
    if (self) {
        _type = JYMessageTypeUnknown;
        _lock = [[NSLock alloc] init];
    }
    return self;
}

@end

#pragma mark - JYMessageUser

@implementation JYMessageUser

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = JYMessageTypeUser;
        _content = @"";
    }
    return self;
}

@end

#pragma mark - JYMessageAI

@interface JYMessageAI () {
    NSMutableString *_thought;
    NSMutableString *_content;
}

@end

@implementation JYMessageAI

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = JYMessageTypeAI;
        _model = JYMessageAIModelNone;
        _thoughtId = @"";
        _thought = [NSMutableString string];
        _contentId = @"";
        _content = [NSMutableString string];
    }
    return self;
}

- (void)appendThought:(NSString *)thought {
    if (thought.length == 0) {
        return;
    }
    [self.lock lock];
    [_thought appendString:thought];
    [self.lock unlock];
}

- (void)appendContent:(NSString *)content {
    if (content.length == 0) {
        return;
    }
    [self.lock lock];
    [_content appendString:content];
    [self.lock unlock];
}

- (NSString *)thought {
    [self.lock lock];
    NSString *thought = [_thought copy];
    [self.lock unlock];
    return thought;
}

- (NSString *)content {
    [self.lock lock];
    NSString *content = [_content copy];
    [self.lock unlock];
    return content;
}

+ (JYMessageAIModel)aiModelFromModelName:(NSString *)modelName {
    if ([modelName isEqualToString:JYMessageModelNameMixed]) {
        return JYMessageAIModelMixed;
    } else if ([modelName isEqualToString:JYMessageModelNameDeepseek]) {
        return JYMessageAIModelDeepseek;
    } else if ([modelName isEqualToString:JYMessageModelNameDoubao]) {
        return JYMessageAIModelDoubao;
    } else if ([modelName isEqualToString:JYMessageModelNameHunyuan]) {
        return JYMessageAIModelHunyuan;
    } else {
        return JYMessageAIModelNone;
    }
}

+ (NSString *)modelDescriptionWithAIModel:(JYMessageAIModel)aiModel {
    switch (aiModel) {
        case JYMessageAIModelMixed:
            return @"最终答案";
        case JYMessageAIModelDeepseek:
            return @"DeepSeek";
        case JYMessageAIModelDoubao:
            return @"豆包大模型";
        case JYMessageAIModelHunyuan:
            return @"混元大模型";
        default:
            return @"";
    }
}

@end

#pragma mark - JYMessageSearch

@implementation JYMessageSearchResult

- (instancetype)init
{
    self = [super init];
    if (self) {
        _title = @"";
        _url = @"";
    }
    return self;
}

- (BOOL)isEqual:(id)other
{
    if (self == other) {
        return YES;
    }
    if (![other isKindOfClass:[JYMessageSearchResult class]]) {
        return NO;
    }
    JYMessageSearchResult *otherObj = (JYMessageSearchResult *)other;
    return [self.title isEqualToString:otherObj.title] && [self.url isEqualToString:otherObj.url];
}

- (NSUInteger)hash
{
    return [self.title hash] ^ [self.url hash];
}

@end

@interface JYMessageSearch () {
    NSMutableArray<JYMessageSearchResult *> *_resultList;
}

@end

@implementation JYMessageSearch

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = JYMessageTypeSearch;
        _engine = JYMessageSearchEngineNone;
        _resultList = [NSMutableArray array];
    }
    return self;
}

- (void)appendResult:(JYMessageSearchResult *)result {
    if (result == nil) {
        return;
    }
    [self.lock lock];
    [_resultList addObject:result];
    [self.lock unlock];
}

- (NSArray<JYMessageSearchResult *> *)resultList {
    [self.lock lock];
    NSArray<JYMessageSearchResult *> *resultList = [_resultList copy];
    [self.lock unlock];
    return resultList;
}

+ (JYMessageSearchEngine)searchEngineFromEngineName:(NSString *)engineName {
    if ([engineName isEqualToString:JYMessageSearchEngineNameToutiao]) {
        return JYMessageSearchEngineToutiao;
    } else if ([engineName isEqualToString:JYMessageSearchEngineNameBaidu]) {
        return JYMessageSearchEngineBaidu;
    } else if ([engineName isEqualToString:JYMessageSearchEngineNameSogou]) {
        return JYMessageSearchEngineSogou;
    } else {
        return JYMessageSearchEngineNone;
    }
}

+ (NSString *)engineDescriptionWithSearchEngine:(JYMessageSearchEngine)searchEngine {
    switch (searchEngine) {
        case JYMessageSearchEngineToutiao:
            return @"头条";
        case JYMessageSearchEngineBaidu:
            return @"百度";
        case JYMessageSearchEngineSogou:
            return @"搜狗";
        default:
            return @"";
    }
}

@end

#pragma mark - JYCozeData

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
