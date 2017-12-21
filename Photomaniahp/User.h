//
//  User.h
//  Photomaniahp
//
//  Created by hp ios on 12/20/17.
//  Copyright © 2017 hp ios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
@interface User   : NSManagedObject

@property(nonatomic,retain) NSString *dataid;
@property(nonatomic,retain) NSString *title;
@property(nonatomic,retain) NSString *body;

@end
