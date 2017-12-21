//
//  User+Data.m
//  Photomaniahp
//
//  Created by hp ios on 12/20/17.
//  Copyright © 2017 hp ios. All rights reserved.
//

#import "User+Data.h"
#import "ServerAPI.h"

@implementation User (Data)

+ (User *)userWithInfo:(NSDictionary *)userDictionary
inManagedObjectContext:(NSManagedObjectContext *)context
{
    User *user =nil;

    NSString *user_id=[NSString stringWithFormat:@"%@",userDictionary[USER_ID]];
    NSString *unique_user_id =user_id;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    request.predicate = [NSPredicate predicateWithFormat:@"dataid = %@", unique_user_id];
    
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches || error || ([matches count] > 1)) {
        // handle error
    } else if ([matches count]) {
        user = [matches firstObject];
    } else {
        user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                              inManagedObjectContext:context];
        
         NSString *user_id_new=[NSString stringWithFormat:@"%@",[userDictionary valueForKeyPath:USER_ID]];
        
        user.dataid =user_id_new;
        
        
        
        user.title = [userDictionary valueForKeyPath:USER_TITLE];
        user.body = [userDictionary valueForKeyPath:USER_BODY];
    }
  return user;
}

+ (void)loadInfoFromUserArray:(NSArray *)users // of Fake id NSDictionary
     intoManagedObjectContext:(NSManagedObjectContext *)context
{
    for (NSDictionary *photo in users) {
        [self userWithInfo:photo inManagedObjectContext:context];
    }

}
@end
