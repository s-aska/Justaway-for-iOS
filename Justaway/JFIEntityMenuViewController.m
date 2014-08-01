#import "JFIEntityMenuViewController.h"
#import "JFITheme.h"
#import "JFIEntityMenu.h"

@interface JFIEntityMenuViewController ()

@property (nonatomic, strong) NSMutableArray *menus;

@end

@implementation JFIEntityMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    JFITheme *theme = [JFITheme sharedTheme];
    [self.tableView setSeparatorColor:theme.mainHighlightBackgroundColor];
    self.tableView.backgroundColor = theme.mainBackgroundColor;
    self.view.backgroundColor = theme.mainBackgroundColor;
    [self.titleLabel setTextColor:theme.titleTextColor];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.menus = [[JFIEntityMenu loadSettings] mutableCopy];
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [JFIEntityMenu saveSettings:self.menus];
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.menus count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        JFITheme *theme = [JFITheme sharedTheme];
        cell.backgroundColor = theme.mainBackgroundColor;
        [cell.textLabel setTextColor:theme.titleTextColor];
    }
    
    NSDictionary *menu = [self.menus objectAtIndex:indexPath.row];
    
	if ([menu[JFIEntityMenuEnableKey] boolValue]) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
    
    cell.textLabel.text = NSLocalizedString([menu valueForKey:JFIEntityMenuIDKey], nil);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *menu = [self.menus objectAtIndex:indexPath.row];
    
	if ([menu[JFIEntityMenuEnableKey] boolValue]) {
        [menu setValue:@NO forKey:JFIEntityMenuEnableKey];
	} else {
        [menu setValue:@YES forKey:JFIEntityMenuEnableKey];
	}
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:NO];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableview shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableview canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    if (destinationIndexPath.row < self.menus.count) {
        NSDictionary *menu = [self.menus objectAtIndex:sourceIndexPath.row];
        [self.menus removeObjectAtIndex:sourceIndexPath.row];
        [self.menus insertObject:menu atIndex:destinationIndexPath.row];
    }
}

#pragma mark -

- (IBAction)sortAction:(id)sender
{
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    if (self.tableView.editing) {
        [self.rightButton setTitle:@"Done" forState:UIControlStateNormal];
    } else {
        [self.rightButton setTitle:@"Sort" forState:UIControlStateNormal];
    }
}

- (IBAction)closeAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
