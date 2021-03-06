//
//  MLSearchViewController.m
//  Networking
//
//  Created by Mauricio Minestrelli on 8/25/14.
//  Copyright (c) 2014 mercadolibre. All rights reserved.
//

#import "MLSearchViewController.h"
#import "MLItemListViewController.h"
#import "MLHistoryTableViewCell.h"
#import "MLDaoHistoryManager.h"
#import "MLKeyboardToolbar.h"

static NSInteger const kHistoryCellHeight=36;

@interface MLSearchViewController ()
//Search history
@property (nonatomic,strong)NSMutableArray* history;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *footerConstraint;
@property (nonatomic,strong) UIActivityIndicatorView* spinner;
@end

@implementation MLSearchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.history=[[NSMutableArray alloc]init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if(![MLUtils isRunningIos7]){
        self.topConstraint.constant=0.0;
        self.topViewConstraint.constant=0.0;
        self.footerConstraint.constant=0.0;
        self.searchBar.tintColor = [UIColor blackColor];
    }
    self.tableViewHistory.scrollEnabled=YES;
    self.searchBar.delegate=self;
    [self registerForKeyboardNotifications];
    
    // Particular de la search
    UIImage* logoImage = [UIImage imageNamed:@"mercadolibre.png"];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:logoImage];
    [self.searchBar setPlaceholder:@"Buscar en Mercadolibre"];
    //history loading
    [self setSpinnerCenteredInView:self.tableViewHistory];
    [[MLDaoHistoryManager sharedManager]  getHistoryOnCompletion:^(NSMutableArray*array){
        self.history=array;
        [self.tableViewHistory reloadData];
        [self.spinner stopAnimating];
    }];
    MLKeyboardToolbar *toolBar = [[MLKeyboardToolbar alloc] initWithFrame:CGRectMake(0.0f,
                                                                                 0.0f,
                                                                                 self.view.window.frame.size.width,
                                                                                 35.0f)];
    toolBar.okButton.action=@selector(doneEditing);
    self.searchBar.inputAccessoryView = toolBar;
    //Registrar la celda
    [self.tableViewHistory registerNib:[UINib nibWithNibName:@"MLHistoryTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"SearchHistoryCellIdentifier"];
    
    [self setTitle:@"Buscar"];
}

-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableViewHistory reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self deregisterForKeyboardNotifications];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.history.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   MLHistoryTableViewCell * historyCell = [tableView dequeueReusableCellWithIdentifier:@"SearchHistoryCellIdentifier"];
    
    [self setCellContent:historyCell cellForRowAtIndexPath:indexPath];
    historyCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return historyCell;
    
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    MLHistoryItem* item=[self.history objectAtIndex:indexPath.row];
    [self.history removeObject:item];
    [self.history addObject:[[MLHistoryItem alloc]initWithItem:item.searchedItem andDate:[NSDate date]]];
    
    [[MLDaoHistoryManager sharedManager] saveHistory:self.history];
    [self searchWithInput:item.searchedItem];
    [self.tableViewHistory deselectRowAtIndexPath:indexPath animated:YES];
}

-(void) setCellContent:(MLHistoryTableViewCell *) cell cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    MLHistoryItem * item=[self.history objectAtIndex:indexPath.row];
    cell.labelHistoryItem.text=item.searchedItem;
    
    //FEO
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if([item.searchDate isToday]){
        [formatter setDateFormat:@"hh:mm"];
    }
    else{
        [formatter setDateFormat:@"dd/MM/yyyy"];
    }
    
    NSString *stringFromDate = [formatter stringFromDate:item.searchDate];
    cell.labelDate.text=stringFromDate;

}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    MLHistoryTableViewCell* cell=[self.tableViewHistory dequeueReusableCellWithIdentifier:@"SearchHistoryCellIdentifier"];
    [self setCellContent:cell cellForRowAtIndexPath:indexPath];
    return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingExpandedSize].height;
}

-(CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return kHistoryCellHeight;
}
#pragma mark keyboard
/*Dismisses searchbar keyboard*/
-(void)dismissKeyboard{
    [self.searchBar resignFirstResponder];
}

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)deregisterForKeyboardNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    self.tableViewHistory.scrollEnabled=YES;
        NSDictionary* info = [aNotification userInfo];
        CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height -55.0, 0.0);
        self.tableViewHistory.contentInset = contentInsets;
        self.tableViewHistory.scrollIndicatorInsets = contentInsets;
}


// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0,0.0, 0.0);;
        self.tableViewHistory.contentInset = contentInsets;
       self.tableViewHistory.scrollIndicatorInsets = contentInsets;
    
}
#pragma mark searchbar
/*Search bar button clicked pushes item list view controller, adds input from search to history*/
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self dismissKeyboard];
    
    [self.history addObject:[[MLHistoryItem alloc]initWithItem:self.searchBar.text andDate:[NSDate date]]];
    MLDaoHistoryManager * daoHistoryManager=[MLDaoHistoryManager sharedManager];
    [daoHistoryManager saveHistory:self.history];
    
    [self searchWithInput:self.searchBar.text];
    self.searchBar.text=@"";
}

-(void)searchWithInput:(NSString*)input{
    [self dismissKeyboard];
    MLItemListViewController * controller=[[MLItemListViewController alloc]initWithInput:input];
    [self.navigationController pushViewController:controller animated:YES];
}
-(void) doneEditing{
    [self.searchBar resignFirstResponder];
}
#pragma mark aux
-(void) setSpinnerCenteredInView:(UIView*) containerView{
    self.spinner=[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = CGPointMake(containerView.frame.size.width/2,containerView.frame.size.height/2);
    [containerView addSubview:self.spinner];
    [self.spinner startAnimating];
}
#pragma mark dealloc
- (void)dealloc {
    [self deregisterForKeyboardNotifications];
}

@end