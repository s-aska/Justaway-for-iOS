//
//  JustawayFirstViewController.h
//  Justaway
//
//  Created by Shinichiro Aska on 2014/01/20.
//  Copyright (c) 2014年 Shinichiro Aska. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JustawayFirstViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *statuses;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)loadAction:(id)sender;

@end
