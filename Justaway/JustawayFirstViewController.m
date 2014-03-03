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
#import "ISDiskCache.h"
#import "ISMemoryCache.h"

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

    self.operationQueue = [[NSOperationQueue alloc] init];
    [self.operationQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];

    
    NSURL *url = [NSURL URLWithString:@"http://pbs.twimg.com/profile_images/418049488645677056/o2cmo8o2_normal.jpeg"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData:data];
    self.imageView.image = image;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.operationQueue && [keyPath isEqualToString:@"operationCount"]) {
        NSInteger count = [self.operationQueue operationCount];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = count > 0;
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
    
    NSURL *URL = [NSURL URLWithString:[status valueForKeyPath:@"user.profile_image_url"]];

    ISMemoryCache *memCache = [ISMemoryCache sharedCache];
    ISDiskCache *diskCache = [ISDiskCache sharedCache];

    cell.imageView.image = [memCache objectForKey:URL];

    if (cell.imageView.image == nil) {

        if ([diskCache hasObjectForKey:URL]) {
            NSLog(@"-- from disk %@", URL);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *image = [diskCache objectForKey:URL];
                dispatch_async(dispatch_get_main_queue(), ^{
                    JFIStatusCell *cell = (JFIStatusCell *) [tableView cellForRowAtIndexPath:indexPath];
                    cell.imageView.image = image;
                    [cell setNeedsLayout];
                });
            });
        } else {
            NSLog(@"-- from network %@", URL);
            NSURLRequest *request = [NSURLRequest requestWithURL:URL];
            [NSURLConnection sendAsynchronousRequest:request
                                               queue:self.operationQueue
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       UIImage *image = [UIImage imageWithData:data];
                                       if (image) {
                                           [memCache setObject:image forKey:URL];
                                           [diskCache setObject:image forKey:URL];
                                           dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   JFIStatusCell *cell = (JFIStatusCell *) [tableView cellForRowAtIndexPath:indexPath];
                                                   cell.imageView.image = image;
                                                   [cell setNeedsLayout];
                                               });
                                           });
                                       } else {
                                           NSLog(@"-- sendAsynchronousRequest: fail");
                                       }
                                   }];
            
        }
    } else {
        NSLog(@"-- from memory %@", URL);
    }

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
    NSInteger index = 2;
    STTwitterAPI *twitter = [delegate getTwitterByIndex:&index];

    [twitter getHomeTimelineSinceID:nil
                               count:3
                        successBlock:^(NSArray *statuses) {
//                            NSLog(@"-- statuses: %@", statuses);
                            self.statuses = statuses;
                            [self.tableView reloadData];
                        } errorBlock:^(NSError *error) {
                            NSLog(@"-- error: %@", [error localizedDescription]);
                        }];
}

@end
