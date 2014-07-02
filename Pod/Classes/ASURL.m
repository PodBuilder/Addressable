/*
 * Copyright (C) 2006-2013 Bob Aman
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

// Note: Don't use NSAssert for "can't happen" tests in Addressable because they will disappear in Release builds under CocoaPods.

#import "ASURL.h"

static NSString *ASGetRegularExpressionCaptureGroupString(NSString *whole, NSRange groupRange) {
    if (groupRange.location == NSNotFound && groupRange.length == 0) return nil;
    else return [whole substringWithRange:groupRange];
}

static BOOL ASRegularExpressionMatches(NSString *str, NSString *pattern) {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    if (regex == nil) [NSException raise:NSInternalInconsistencyException format:@"Cannot compile regex '%@': %@", pattern, error];
    
    NSTextCheckingResult *match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, str.length)];
    return match != nil;
}

static NSString *ASRegularExpressionReplace(NSString *str, NSString *pattern, NSString *replacement) {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    if (regex == nil) [NSException raise:NSInternalInconsistencyException format:@"Cannot compile regex '%@': %@", pattern, error];
    
    return [regex stringByReplacingMatchesInString:str options:0 range:NSMakeRange(0, str.length) withTemplate:replacement];
}

#pragma mark -

NSString * const ASInvalidURLException = @"ASInvalidURLException";

NSString * const ASURLComponentScheme = @"scheme";
NSString * const ASURLComponentUserName = @"user";
NSString * const ASURLComponentPassword = @"password";
NSString * const ASURLComponentHostName = @"host";
NSString * const ASURLComponentPortNumber = @"port";
NSString * const ASURLComponentPath = @"path";
NSString * const ASURLComponentQuery = @"query";
NSString * const ASURLComponentQueryValues = @"query_values";
NSString * const ASURLComponentFragment = @"fragment";
NSString * const ASURLComponentAuthority = @"authority";
NSString * const ASURLComponentUserInfo = @"userinfo";

@implementation ASURL
{
    BOOL validationDeferred;
}

+ (NSRegularExpression *)URIRegularExpression {
    static NSRegularExpression *expression;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error;
        expression = [NSRegularExpression regularExpressionWithPattern:@"^(([^:\\/?#]+):)?(\\/\\/([^\\/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?$" options:0 error:&error];
        
        if (expression == nil) [NSException raise:NSInternalInconsistencyException format:@"Could not compile URI regular expression: %@", error];
    });
    
    return expression;
}

+ (NSDictionary *)portMappingDictionary {
    static NSDictionary *dict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = @{ @"http": @80, @"https": @443, @"ftp": @21, @"tftp": @69, @"sftp": @22,
                  @"ssh": @22, @"svn+ssh": @22, @"telnet": @23, @"nntp": @119, @"gopher": @70,
                  @"wais": @210, @"ldap": @389, @"prospero": @1525 };
    });
    
    return dict;
}

#pragma mark Constructors

+ (ASURL *)URLWithCocoaURL:(NSURL *)cocoaURL {
    return [self URLWithString:cocoaURL.absoluteString];
}

+ (ASURL *)URLWithString:(NSString *)URLString {
    if (URLString == nil) return nil;
    
    NSTextCheckingResult *scanResult = [[self URIRegularExpression] firstMatchInString:URLString options:0 range:NSMakeRange(0, URLString.length)];
    NSString *scheme = ASGetRegularExpressionCaptureGroupString(URLString, [scanResult rangeAtIndex:1]);
    NSString *authority = ASGetRegularExpressionCaptureGroupString(URLString, [scanResult rangeAtIndex:3]);
    NSString *path = ASGetRegularExpressionCaptureGroupString(URLString, [scanResult rangeAtIndex:4]);
    NSString *query = ASGetRegularExpressionCaptureGroupString(URLString, [scanResult rangeAtIndex:6]);
    NSString *fragment = ASGetRegularExpressionCaptureGroupString(URLString, [scanResult rangeAtIndex:8]);
    NSString *user = nil;
    NSString *password = nil;
    NSString *host = nil;
    NSString *port = nil;
    
    if (authority != nil) {
        NSError *error;
        NSRegularExpression *userInfoRegex = [NSRegularExpression regularExpressionWithPattern:@"^([^\\[\\]]*)@" options:0 error:&error];
        if (userInfoRegex == nil) [NSException raise:NSInternalInconsistencyException format:@"Cannot compile regular expression: %@", error];
        
        NSTextCheckingResult *match = [userInfoRegex firstMatchInString:authority options:0 range:NSMakeRange(0, authority.length)];
        NSString *userInfo = ASGetRegularExpressionCaptureGroupString(authority, [match rangeAtIndex:1]);
        if (userInfo != nil) {
            NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"^([^:]*):?" options:0 error:&error];
            if (expression == nil) [NSException raise:NSInternalInconsistencyException format:@"Cannot compile regular expression: %@", error];
            match = [expression firstMatchInString:userInfo options:0 range:NSMakeRange(0, userInfo.length)];
            user = ASGetRegularExpressionCaptureGroupString(userInfo, [match rangeAtIndex:1]);
            
            expression = [NSRegularExpression regularExpressionWithPattern:@":(.*)$" options:0 error:&error];
            if (expression == nil) [NSException raise:NSInternalInconsistencyException format:@"Cannot compile regular expression: %@", error];
            match = [expression firstMatchInString:userInfo options:0 range:NSMakeRange(0, userInfo.length)];
            password = ASGetRegularExpressionCaptureGroupString(userInfo, [match rangeAtIndex:1]);
        }
        
        NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"^([^\\[\\]]*)@|:([^:@\\[\\]]*?)$" options:0 error:&error];
        if (expression == nil) [NSException raise:NSInternalInconsistencyException format:@"Cannot compile regular expression: %@", error];
        host = [expression stringByReplacingMatchesInString:authority options:0 range:NSMakeRange(0, authority.length) withTemplate:@""];
        
        expression = [NSRegularExpression regularExpressionWithPattern:@":([^:@\\[\\]]*?)$" options:0 error:&error];
        if (expression == nil) [NSException raise:NSInternalInconsistencyException format:@"Cannot compile regular expression: %@", error];
        match = [expression firstMatchInString:authority options:0 range:NSMakeRange(0, authority.length)];
        port = ASGetRegularExpressionCaptureGroupString(authority, [match rangeAtIndex:1]);
    }
    
    if ([port isEqualToString:@""]) port = nil;
    
    return [[self alloc] initWithComponents:@{ ASURLComponentScheme: scheme,
                                               ASURLComponentUserName: user,
                                               ASURLComponentPassword: password,
                                               ASURLComponentPortNumber: port,
                                               ASURLComponentPassword: path,
                                               ASURLComponentQuery: query,
                                               ASURLComponentFragment: fragment }];
}

+ (ASURL *)URLWithParsedStringUsingHeuristics:(NSString *)URLString {
    if (URLString == nil) return nil;
    
    NSString *realURL = URLString;
    if (ASRegularExpressionMatches(realURL, @"^http:\\/+")) {
        realURL = ASRegularExpressionReplace(realURL, @"^http:\\/+", @"http://");
    } else if (ASRegularExpressionMatches(realURL, @"^https:\\/+")) {
        realURL = ASRegularExpressionReplace(realURL, @"^https:\\/+", @"https://");
    } else if (ASRegularExpressionMatches(realURL, @"feed:\\/+http:\\/+")) {
        realURL = ASRegularExpressionReplace(realURL, @"feed:\\/+http:\\/+", @"feed:http://");
    } else if (ASRegularExpressionMatches(realURL, @"feed:\\/+")) {
        realURL = ASRegularExpressionReplace(realURL, @"feed:\\/+", @"feed://");
    } else if (ASRegularExpressionMatches(realURL, @"file:\\/+")) {
        realURL = ASRegularExpressionReplace(realURL, @"file:\\/+", @"file:///");
    } else if (ASRegularExpressionMatches(realURL, @"^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}")) {
        realURL = ASRegularExpressionReplace(realURL, @"^", @"http://");
    }
    
    ASURL *parsedURL = [self URLWithString:realURL];
    if (ASRegularExpressionMatches(parsedURL.scheme, @"^[^\\/?#\\.]+\\.[^\\/?#]+$")) {
        parsedURL = [self URLWithString:[NSString stringWithFormat:@"http://%@", realURL]];
    }
    
    if ([parsedURL.path rangeOfString:@"."].length != 0) {
        NSString *newHost = ASRegularExpressionReplace(parsedURL.path, @"^([^\\/]+\\.[^\\/]*)", @"$1");
        if (newHost != nil && newHost.length != 0) {
            [parsedURL executeBlockDeferringValidation:^{
                NSString *escaped = [NSRegularExpression escapedPatternForString:newHost];
                NSString *newPath = ASRegularExpressionReplace(parsedURL.path, [NSString stringWithFormat:@"^%@", escaped], @"");
                parsedURL.hostName = newHost;
                parsedURL.path = newPath;
                
                if (parsedURL.scheme == nil) parsedURL.scheme = @"http";
            }];
        }
    }
    
    return parsedURL;
}

+ (ASURL *)URLWithConvertedFilePath:(NSString *)path {
    if (path == nil) return nil;
    
    NSString *strippedPath = [path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (ASRegularExpressionMatches(strippedPath, @"^file:\\/?\\/?")) strippedPath = ASRegularExpressionReplace(strippedPath, @"^file:\\/?\\/?", @"");
    if (ASRegularExpressionMatches(strippedPath, @"^([a-zA-Z])[\\|:]")) strippedPath = [NSString stringWithFormat:@"/%@", strippedPath];
    
    ASURL *parsedURL = [self URLWithString:strippedPath];
    
    if (parsedURL.scheme == nil) {
        // Adjust Windows-style URLs
        NSError *error;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\/?([a-zA-Z])[\\|:][\\\\\\/]" options:0 error:&error];
        if (regex == nil) [NSException raise:NSInternalInconsistencyException format:@"Could not compile regex: %@", error];
        
        NSMutableString *fixedPath = [parsedURL.path mutableCopy];
        [regex enumerateMatchesInString:parsedURL.path options:0 range:NSMakeRange(0, parsedURL.path.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSRange range = [result rangeAtIndex:1];
            if (range.location != NSNotFound && range.length != 0) {
                [fixedPath replaceCharactersInRange:range withString:[[fixedPath substringWithRange:range] lowercaseString]];
            }
        }];
        
        parsedURL.path = ASRegularExpressionReplace(fixedPath, @"\\\\", @"/");
        
        // If the path is absolute, set the scheme and host.
        if (ASRegularExpressionMatches(parsedURL.path, @"^\\/")) {
            parsedURL.scheme = @"file";
            parsedURL.hostName = @"";
        }
    }
    
    return parsedURL;
}

- (id)initWithComponents:(NSDictionary *)components {
    if ([components.allKeys containsObject:ASURLComponentAuthority]) {
        if ([components.allKeys containsObject:ASURLComponentUserInfo] ||
            [components.allKeys containsObject:ASURLComponentUserName] ||
            [components.allKeys containsObject:ASURLComponentPassword] ||
            [components.allKeys containsObject:ASURLComponentHostName] ||
            [components.allKeys containsObject:ASURLComponentPortNumber]) {
            [NSException raise:NSInvalidArgumentException format:@"Cannot specify both an authority and any of the components within the authority"];
            return nil;
        }
    }
    
    if ([components.allKeys containsObject:ASURLComponentUserInfo]) {
        if ([components.allKeys containsObject:ASURLComponentUserName] ||
            [components.allKeys containsObject:ASURLComponentPassword]) {
            [NSException raise:NSInvalidArgumentException format:@"Cannot specify both a userinfo string and the username or password (which compose it)"];
            return nil;
        }
    }
    
    self = [super init];
    
    [self executeBlockDeferringValidation:^{
        if ([components.allKeys containsObject:ASURLComponentScheme]) self.scheme = components[ASURLComponentScheme];
        if ([components.allKeys containsObject:ASURLComponentUserName]) self.userName = components[ASURLComponentUserName];
        if ([components.allKeys containsObject:ASURLComponentPassword]) self.password = components[ASURLComponentPassword];
        if ([components.allKeys containsObject:ASURLComponentHostName]) self.hostName = components[ASURLComponentHostName];
        if ([components.allKeys containsObject:ASURLComponentPortNumber]) self.portNumber = components[ASURLComponentPortNumber];
        if ([components.allKeys containsObject:ASURLComponentAuthority]) self.authority = components[ASURLComponentAuthority];
        if ([components.allKeys containsObject:ASURLComponentPath]) self.path = components[ASURLComponentPath];
        if ([components.allKeys containsObject:ASURLComponentQuery]) self.query = components[ASURLComponentQuery];
        if ([components.allKeys containsObject:ASURLComponentQueryValues]) self.query = components[ASURLComponentQueryValues];
        if ([components.allKeys containsObject:ASURLComponentFragment]) self.fragment = components[ASURLComponentFragment];
    }];
    
    return self;
}

#pragma mark Joining

+ (ASURL *)combinedURLWithComponentURLs:(NSArray *)URLArray {
    NSMutableArray *fixedArray = [URLArray mutableCopy];
    ASURL *result = fixedArray[0];
    [fixedArray removeObjectAtIndex:0];
    
    NSInteger limit = fixedArray.count;
    for (NSInteger i = 0; i < limit; i++) {
        [result appendURL:fixedArray[i]];
    }
    
    return result;
}

- (ASURL *)URLByAppendingURL:(ASURL *)other {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented"];
    return nil;
}

- (void)appendURL:(ASURL *)other {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented"];
}

#pragma mark Validation

- (void)validate {
    NSLog(@"-[%@ %@] is unimplemented", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (void)executeBlockDeferringValidation:(void (^)(void))block {
    if (block == NULL) [NSException raise:NSInvalidArgumentException format:@"A block must be provided"];
    
    validationDeferred = YES;
    block();
    validationDeferred = NO;
    
    [self validate];
}

@end
