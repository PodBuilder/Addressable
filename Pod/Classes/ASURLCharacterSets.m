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

#import "ASURLCharacterSets.h"

@implementation ASURLCharacterSets

+ (NSCharacterSet *)alphabetCharacterSet {
    static NSCharacterSet *cset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cset = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"];
    });
    
    return cset;
}

+ (NSCharacterSet *)decimalDigitCharacterSet {
    static NSCharacterSet *cset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cset = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    });
    
    return cset;
}

+ (NSCharacterSet *)generalDelimiterCharacterSet {
    static NSCharacterSet *cset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cset = [NSCharacterSet characterSetWithCharactersInString:@":/?#[]@"];
    });
    
    return cset;
}

+ (NSCharacterSet *)subdelimiterCharacterSet {
    static NSCharacterSet *cset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cset = [NSCharacterSet characterSetWithCharactersInString:@"!$&'()*+,;="];
    });
    
    return cset;
}

+ (NSCharacterSet *)reservedCharacterSet {
    static NSCharacterSet *cset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *mutableSet = [NSMutableCharacterSet characterSetWithCharactersInString:@""];
        [mutableSet formUnionWithCharacterSet:[self generalDelimiterCharacterSet]];
        [mutableSet formUnionWithCharacterSet:[self subdelimiterCharacterSet]];
        cset = mutableSet;
    });
    
    return cset;
}

+ (NSCharacterSet *)nonReservedCharacterSet {
    static NSCharacterSet *cset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *mutableSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"-._~"];
        [mutableSet formUnionWithCharacterSet:[self alphabetCharacterSet]];
        [mutableSet formUnionWithCharacterSet:[self decimalDigitCharacterSet]];
        cset = mutableSet;
    });
    
    return cset;
}

+ (NSCharacterSet *)innerPathCharacterSet {
    static NSCharacterSet *cset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *mutableSet = [NSMutableCharacterSet characterSetWithCharactersInString:@":@"];
        [mutableSet formUnionWithCharacterSet:[self nonReservedCharacterSet]];
        [mutableSet formUnionWithCharacterSet:[self subdelimiterCharacterSet]];
        cset = mutableSet;
    });
    
    return cset;
}

+ (NSCharacterSet *)schemeCharacterSet {
    static NSCharacterSet *cset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *mutableSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"-+."];
        [mutableSet formUnionWithCharacterSet:[self alphabetCharacterSet]];
        [mutableSet formUnionWithCharacterSet:[self decimalDigitCharacterSet]];
        cset = mutableSet;
    });
    
    return cset;
}

+ (NSCharacterSet *)authorityCharacterSet {
    return [self innerPathCharacterSet];
}

+ (NSCharacterSet *)pathCharacterSet {
    static NSCharacterSet *cset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *mutableSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"/"];
        [mutableSet formUnionWithCharacterSet:[self innerPathCharacterSet]];
        cset = mutableSet;
    });
    
    return cset;
}

+ (NSCharacterSet *)queryCharacterSet {
    static NSCharacterSet *cset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *mutableSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"/?"];
        [mutableSet formUnionWithCharacterSet:[self innerPathCharacterSet]];
        cset = mutableSet;
    });
    
    return cset;
}

+ (NSCharacterSet *)fragmentCharacterSet {
    static NSCharacterSet *cset;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *mutableSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"/?"];
        [mutableSet formUnionWithCharacterSet:[self innerPathCharacterSet]];
        cset = mutableSet;
    });
    
    return cset;
}

@end

#pragma mark -

@implementation NSCharacterSet (ASRegularExpressionSupport)

+ (NSString *)calculateRegularExpressionCharacterSetStringForCharacterSet:(NSCharacterSet *)set {
    const unsigned char *bitmap = [set.bitmapRepresentation bytes];
    NSMutableString *string = [NSMutableString string];
    
    for (NSUInteger i = 0; i < 65536; i++) {
        if (bitmap[i >> 3] & (((unsigned int)1) << (i & 7))) {
            [string appendFormat:@"%C", (unichar) i];
        }
    }
    
    return [NSRegularExpression escapedPatternForString:string];
}

- (NSString *)regularExpressionCharacterSetString {
    return [NSString stringWithFormat:@"[%@]", [[self class] calculateRegularExpressionCharacterSetStringForCharacterSet:self]];
}

- (NSString *)invertedRegularExpressionCharacterSetString {
    return [NSString stringWithFormat:@"[^%@]", [[self class] calculateRegularExpressionCharacterSetStringForCharacterSet:self]];
}

@end
