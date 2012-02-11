//
//  FMJson.h
//  SkronkMini
//
//  Created by John Sheets on 2/4/12.
//  Copyright (c) 2012 FourFringe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FMJson : NSObject

@property (retain) NSString *jsonText;
@property (retain) id jsonObject;

- (id)initWithJson:(NSString *)json;
- (id)valueForProperty:(NSString *)keyPath;

@end
