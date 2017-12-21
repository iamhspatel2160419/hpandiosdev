//
//  User+Data.h
//  Photomaniahp
//
//  Created by hp ios on 12/20/17.
//  Copyright © 2017 hp ios. All rights reserved.
//

#import "User.h"

@interface User (Data)

+ (User *)userWithInfo:(NSDictionary *)userDictionary
        inManagedObjectContext:(NSManagedObjectContext *)context;

+ (void)loadInfoFromUserArray:(NSArray *)users // of Fake id NSDictionary
         intoManagedObjectContext:(NSManagedObjectContext *)context;
@end
