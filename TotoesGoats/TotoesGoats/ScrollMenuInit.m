//
//  ScrollMenuInit.m
//  TotoesGoats
//
//  Created by Guo Xiaoyu on 2/22/16.
//  Copyright © 2016 Xiaoyu Guo. All rights reserved.
//

#import "ScrollMenuInit.h"

@implementation ScrollMenuInit

+ (void)setUpACPScroll: (ACPScrollMenu *) scrollMenu inUIViewController: (UIViewController*) thisVC{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSArray *names = [[NSArray alloc] initWithObjects:@"Face", @"Blink", @"Smile", @"Gradient", nil];
    for (int i = 1; i < 5; i++)
    {
        NSString *imgName = [NSString stringWithFormat:@"%d.png", i];
        NSString *imgSelectedName = [NSString stringWithFormat:@"%ds.png", i];
        
        //You can choose between work with delegates or with blocks
        //This sample project has commented the delegate functionality
        
        //ACPItem *item = [[ACPItem alloc] initACPItem:[UIImage imageNamed:@"bg.png"] iconImage:[UIImage imageNamed:imgName] andLabel:@"Test"];
        
        //Item working with blocks
        ACPItem *item = [[ACPItem alloc] initACPItem:[UIImage imageNamed:@"bg.png"]
                                           iconImage:[UIImage imageNamed:imgName]
                                               label:[names objectAtIndex:i-1]
                                           andAction: ^(ACPItem *item) {
                                               
                                               NSLog(@"Block called! %d", i);
                                               //DO somenthing here
                                           }];
        
        //Set highlighted behaviour
        [item setHighlightedBackground:nil iconHighlighted:[UIImage imageNamed:imgSelectedName] textColorHighlighted:[UIColor redColor]];
        [array addObject:item];
    }
    
    [scrollMenu setUpACPScrollMenu:array];
    
    //We choose an animation when the user touch the item (you can create your own animation)
    [scrollMenu setAnimationType:ACPZoomOut];
    [thisVC.view bringSubviewToFront:scrollMenu];
    scrollMenu.delegate = thisVC;
}

@end
