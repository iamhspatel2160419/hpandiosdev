//
//  ServerAPI.h
//  Photomaniahp
//
//  Created by hp ios on 12/20/17.
//  Copyright © 2017 hp ios. All rights reserved.
//

#import <Foundation/Foundation.h>
#define USER_ID @"id"
#define USER_TITLE @"title"
#define USER_BODY @"body"

@interface ServerAPI : NSObject

+ (NSURL *)URLForServerData;
@end
