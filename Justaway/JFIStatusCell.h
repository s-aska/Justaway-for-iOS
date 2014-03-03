//
//  JFIStatusCell.h
//  Justaway
//
//  Created by Shinichiro Aska on 2014/03/02.
//  Copyright (c) 2014年 Shinichiro Aska. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JFIStatusCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *screenNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property (weak, nonatomic) IBOutlet UITextView *statusTextView;
@property (weak, nonatomic) IBOutlet UILabel *createdAtLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@end
