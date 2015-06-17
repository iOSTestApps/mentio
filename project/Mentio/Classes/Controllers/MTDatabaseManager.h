//
//  MTDatabaseManager.h
//  Mentio
//
//  Created by Martin Hartl on 15/03/14.
//  Copyright (c) 2014 Martin Hartl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTDatabaseManager : NSObject

+ (void)setUpFCModel;
+ (void)restoreFromMentioFileAtURL:(NSURL *)url;

@end
