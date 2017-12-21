//
//  ServerAPI.m
//  Photomaniahp
//
//  Created by hp ios on 12/20/17.
//  Copyright © 2017 hp ios. All rights reserved.
//

#import "ServerAPI.h"

@implementation ServerAPI

+ (NSURL *)URLForServerData;
{
    NSString *urlstring = [NSString stringWithFormat:@"https://jsonplaceholder.typicode.com/posts"];
    NSURL *url = [NSURL URLWithString:urlstring];
   
    return url;
}


@end
