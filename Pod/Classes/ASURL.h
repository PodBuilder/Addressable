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

#import <Foundation/Foundation.h>

extern NSString * const ASInvalidURLException;

// These are keys for the components dictionary passed to -[ASURL initWithComponents:].
extern NSString * const ASURLComponentScheme;
extern NSString * const ASURLComponentUserName;
extern NSString * const ASURLComponentPassword;
extern NSString * const ASURLComponentHostName;
extern NSString * const ASURLComponentPortNumber;
extern NSString * const ASURLComponentPath;
extern NSString * const ASURLComponentQuery;
extern NSString * const ASURLComponentQueryValues;
extern NSString * const ASURLComponentFragment;
extern NSString * const ASURLComponentAuthority; // username:password@host.name:port
extern NSString * const ASURLComponentUserInfo; // username:password

@interface ASURL : NSObject

+ (ASURL *)URLWithCocoaURL:(NSURL *)cocoaURL;
+ (ASURL *)URLWithString:(NSString *)URLString;
- (id)initWithComponents:(NSDictionary *)components;

#pragma mark Properties

@property (strong) NSString *scheme;
@property (strong) NSString *userName;
@property (strong) NSString *password;
@property (strong) NSString *userInfo;
@property (strong) NSString *hostName;
@property (strong) NSString *portNumber;
@property (strong) NSString *authority;
@property (strong) NSString *path;
@property (strong) NSString *query;
@property (strong) NSString *queryValues;
@property (strong) NSString *fragment;

#pragma mark Validation

- (void)validate;
- (void)executeBlockDeferringValidation:(void (^)(void))block;

@end
