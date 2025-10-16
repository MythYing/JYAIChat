//
//  JYModel.m
//  AIChat
//
//  Created by JiangYing on 2025/10/5.
//

#import "JYModel.h"
#import "JYMacro.h"

NSString *const JYMessageEventThought = @"Thought";
NSString *const JYMessageEventContent = @"Content";
NSString *const JYMessageEventError = @"Error";

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
        _thought = [NSMutableString string];
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

@end

#pragma mark - JYMessageSearch

@implementation JYMessageSearchResult

- (instancetype)init
{
    self = [super init];
    if (self) {
        _title = @"";
        _url = @"";
        _content = @"";
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
    return [self.title isEqualToString:otherObj.title] && [self.url isEqualToString:otherObj.url] && [self.content isEqualToString:otherObj.content];
}

- (NSUInteger)hash
{
    return [self.title hash] ^ [self.url hash] ^ [self.content hash];
}

@end

@interface JYMessageSearch () {
    YYThreadSafeArray *_resultList;
}

@end

@implementation JYMessageSearch

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = JYMessageTypeSearch;
        _engine = JYMessageSearchEngineNone;
        _resultList = [YYThreadSafeArray array];
    }
    return self;
}

- (void)setResultList:(NSArray<JYMessageSearchResult *> *)resultList {
    [_resultList removeAllObjects];
    if (resultList) {
        [_resultList addObjectsFromArray:resultList];
    }
}

- (void)refreshResult:(JYMessageSearchResult *)result {
    if (result == nil) {
        return;
    }
    JYMessageSearchResult *item = [_resultList qmui_firstMatchWithBlock:^BOOL(JYMessageSearchResult * _Nonnull item) {
        return [item.url isEqualToString:result.url];
    }];
    if (item) {
        NSUInteger index = [_resultList indexOfObject:item];
        if (index != NSNotFound) {
            JYMessageSearchResult *realResult = _resultList[index];
            realResult.content = result.content;
        }
    }
}

- (NSArray<JYMessageSearchResult *> *)resultList {
    return [_resultList copy];
}

@end

#pragma mark - JYAIModelData

@implementation JYAIModelData

- (instancetype)init
{
    self = [super init];
    if (self) {
        _content = @"";
        _isBegin = NO;
        _isEnd = NO;
    }
    return self;
}

@end


#pragma mark - Transform

JYMessageAIModel aiModel(NSString *modelName) {
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

NSString *aiModelName(JYMessageAIModel model) {
    switch (model) {
        case JYMessageAIModelMixed:
            return JYMessageModelNameMixed;
        case JYMessageAIModelDeepseek:
            return JYMessageModelNameDeepseek;
        case JYMessageAIModelDoubao:
            return JYMessageModelNameDoubao;
        case JYMessageAIModelHunyuan:
            return JYMessageModelNameHunyuan;
        case JYMessageAIModelNone:
            return @"";
    }
}

NSString *aiModelDescription(JYMessageAIModel model) {
    switch (model) {
        case JYMessageAIModelMixed:
            return @"最终答案";
        case JYMessageAIModelDeepseek:
            return @"DeepSeek";
        case JYMessageAIModelDoubao:
            return @"豆包大模型";
        case JYMessageAIModelHunyuan:
            return @"混元大模型";
        case JYMessageAIModelNone:
            return @"";
    }
}

JYMessageSearchEngine searchEngine(NSString *engineName) {
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

NSString *searchEngineName(JYMessageSearchEngine engine) {
    switch (engine) {
        case JYMessageSearchEngineToutiao:
            return JYMessageSearchEngineNameToutiao;
        case JYMessageSearchEngineBaidu:
            return JYMessageSearchEngineNameBaidu;
        case JYMessageSearchEngineSogou:
            return JYMessageSearchEngineNameSogou;
        case JYMessageSearchEngineNone:
            return @"";
    }
}

NSString *searchEngineDescription(JYMessageSearchEngine engine) {
    switch (engine) {
        case JYMessageSearchEngineToutiao:
            return @"头条";
        case JYMessageSearchEngineBaidu:
            return @"百度";
        case JYMessageSearchEngineSogou:
            return @"搜狗";
        case JYMessageSearchEngineNone:
            return @"";
    }
}
