//
//  FMJson.m
//  SkronkMini
//
//  Created by John Sheets on 2/4/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import "FMJson.h"

@implementation FMJson

@synthesize jsonText = _jsonText;
@synthesize jsonObject = _jsonObject;

- (id)initWithJson:(NSString *)jsonText
{
    if ((self = [super init]))
    {
        _jsonText = jsonText;

        NSError *error = nil;
        NSData *jsonData = [jsonText dataUsingEncoding:NSUTF8StringEncoding];
        self.jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    }

    return self;
}

- (NSInteger)arrayIndex:(NSString *)keyPath
{
    NSInteger index = NSNotFound;

    NSUInteger leftBrace = [keyPath rangeOfString:@"["].location;
    NSUInteger rightBrace = [keyPath rangeOfString:@"]"].location;
    if (leftBrace != NSNotFound && rightBrace != NSNotFound && leftBrace < rightBrace)
    {
        NSString *indexString = [keyPath substringWithRange:NSMakeRange(leftBrace + 1, 1)];
        index = [indexString integerValue];
    }

    return index;
}

- (NSString *)basePathPart:(NSString *)keyPath
{
    NSString *baseKey = keyPath;

    // Strip off left brace and everything after.
    NSUInteger leftBrace = [keyPath rangeOfString:@"["].location;
    if (leftBrace != NSNotFound)
    {
        baseKey = [keyPath substringToIndex:leftBrace];
    }

    return baseKey;
}

// keyPath is a blend of KVO and XPath (KVO with array accessors), but that allows properties
// such as "@attr" and "#text".
- (NSString *)valueForProperty:(NSString *)keyPath
{
    id currentObject = self.jsonObject;
    NSArray *pathParts = [keyPath componentsSeparatedByString:@"."];

    for (NSString *pathPart in pathParts)
    {
        // Check for array element.
        NSInteger index = [self arrayIndex:pathPart];
        if (index != NSNotFound)
        {
            // Path part is an array. Update currentObject to point to the
            // Requested array element.
            NSString *basePathPart = [self basePathPart:pathPart];
            NSArray *array = [currentObject objectForKey:basePathPart];
            currentObject = [array objectAtIndex:index];
        }
        else
        {
            currentObject = [currentObject objectForKey:pathPart];
        }
    }

    return currentObject;
}

@end
