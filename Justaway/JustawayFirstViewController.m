//
//  JustawayFirstViewController.m
//  Justaway
//
//  Created by Shinichiro Aska on 2014/01/20.
//  Copyright (c) 2014年 Shinichiro Aska. All rights reserved.
//

#import "JustawayAppDelegate.h"
#import "JustawayFirstViewController.h"
#import "JFIStatusCell.h"

@interface JustawayFirstViewController ()

@end

#define _JFICellId @"Cell"

@implementation JustawayFirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    JustawayAppDelegate *delegate = (JustawayAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    NSLog(@"-- find accounts: %lu", (unsigned long)[delegate.accounts count]);

    [_tableView registerNib:[UINib nibWithNibName:@"JFIStatusCell" bundle:nil] forCellReuseIdentifier:_JFICellId];
    _tableView.dataSource = self;
    _tableView.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.statuses == nil) {
        return 0;
    } else {
        return [self.statuses count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JFIStatusCell *cell = [tableView dequeueReusableCellWithIdentifier:_JFICellId forIndexPath:indexPath];
    NSDictionary *status = [self.statuses objectAtIndex:indexPath.row];
    
    cell.displayNameLabel.text = [status valueForKeyPath:@"user.name"];
    cell.screenNameLabel.text = [status valueForKeyPath:@"user.screen_name"];
    cell.statusTextView.text = [status valueForKey:@"text"];
    cell.createdAtLabel.text = [status valueForKey:@"created_at"];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 85;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Statusを選択された時の処理
}

- (IBAction)loadAction:(id)sender {
    
    JustawayAppDelegate *delegate = (JustawayAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    // 必ず先頭のアカウントの情報を引いてくる罪深い処理
    NSInteger index = 0;
    STTwitterAPI *twitter = [delegate getTwitterByIndex:&index];

    [twitter getHomeTimelineSinceID:nil
                               count:20
                        successBlock:^(NSArray *statuses) {
                            NSLog(@"-- statuses: %@", statuses);
                            self.statuses = statuses;
                            [self.tableView reloadData];
                        } errorBlock:^(NSError *error) {
                            NSLog(@"-- error: %@", [error localizedDescription]);
                        }];
}

@end
