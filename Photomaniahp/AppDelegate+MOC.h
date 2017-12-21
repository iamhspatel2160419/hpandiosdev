//
//  AppDelegate+MOC.h
//  Photomaniahp
//
//  Created by hp ios on 12/20/17.
//  Copyright © 2017 hp ios. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate (MOC)
- (NSManagedObjectContext *)createMainQueueManagedObjectContext;
@end
