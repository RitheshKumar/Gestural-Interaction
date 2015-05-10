//
//  Bjorklidean.h
//  Bjorclid
//
//  Created by Rithesh Kumar on 5/8/15.
//  Copyright (c) 2015 Rithesh Kumar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Bjorklidean : NSObject

@property int beats;
@property int hits;

-(void) arrayInit: (int *)array  withbeats: (int)beats  withhits: (int)hits;
-(void) bjorcimp_noofbeats: (int) beats noofhits: (int) hits;

@end
