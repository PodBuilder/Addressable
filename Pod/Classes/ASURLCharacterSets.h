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

@interface ASURLCharacterSets : NSObject

+ (NSCharacterSet *)alphabetCharacterSet;
+ (NSCharacterSet *)decimalDigitCharacterSet;
+ (NSCharacterSet *)generalDelimiterCharacterSet;
+ (NSCharacterSet *)subdelimiterCharacterSet;
+ (NSCharacterSet *)reservedCharacterSet;
+ (NSCharacterSet *)nonReservedCharacterSet;
+ (NSCharacterSet *)innerPathCharacterSet;
+ (NSCharacterSet *)schemeCharacterSet;
+ (NSCharacterSet *)authorityCharacterSet;
+ (NSCharacterSet *)pathCharacterSet;
+ (NSCharacterSet *)queryCharacterSet;
+ (NSCharacterSet *)fragmentCharacterSet;

@end

#pragma mark -

@interface NSCharacterSet (ASRegularExpressionSupport)

- (NSString *)regularExpressionCharacterSetString;
- (NSString *)invertedRegularExpressionCharacterSetString;

@end
