//
//  MTListViewController.m
//  Mentio
//
//  Created by Martin Hartl on 06/10/13.
//  Copyright (c) 2013 Martin Hartl. All rights reserved.
//

#import "MTListViewController.h"
#import "MTScrollCell.h"
#import "FCModel.h"
#import "MTModelProtocol.h"
#import "UIImageView+AFNetworking.h"
#import "MTDetailViewController.h"
#import "MTIndexPathMutableDictionary.h"
#import "MusicAlbum.h"
#import "Movie.h"
#import "App.h"
#import "TVSeason.h"
#import "Book.h"
#import "TVSeason.h"
#import "MTListViewControllerDataSource.h"
#import "MTListSectionHeader.h"
#import "MTImageCacher.h"
#import "MHAlbumView+RoundCorners.h"
#import "MTOwnMediaViewController.h"
#import "MTSegueConstants.h"
#import "MTStatusBarConstants.h"
#import "MTItunesClient.h"
#import "Mentio-Swift.h"
#import "MTNotificationConstants.h"

@interface MTListViewController () <MTThemeProtocol>

@property (nonatomic, strong) MTIndexPathMutableDictionary *dict;
@property (nonatomic, strong) MTListViewControllerDataSource *dataSource;
@property (nonatomic, strong) UIGestureRecognizer *longPressGestureRecognizer;

@property (nonatomic, strong) UITableViewRowAction *archiveAction;
@property (nonatomic, strong) UITableViewRowAction *deleteAction;
@property (weak, nonatomic) IBOutlet UIRefreshControl *refreshControll;

@property (nonatomic, assign) BOOL cellIsMoving;

@end

@implementation MTListViewController


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"MTScrollCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"Cell"];
    
    self.dict = [MTIndexPathMutableDictionary dictionary];
    
    [self.dict reloadArrayForSection:MTSectionTypeMusic archived:self.archive];
    [self.dict reloadArrayForSection:MTSectionTypeMovie archived:self.archive];
    [self.dict reloadArrayForSection:MTSectionTypeApp archived:self.archive];
    [self.dict reloadArrayForSection:MTSectionTypeBook archived:self.archive];
    [self.dict reloadArrayForSection:MTSectionTypeTVShow archived:self.archive];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableViewOnInsert:) name:FCModelInsertNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableViewOnUpdate:) name:FCModelUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyTheme:) name:MTThemeChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showAddView) name:[MTAddViewConstants didShow] object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showAddView) name:[MTAddViewConstants didHide] object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAll) name:MTDatabaseGotImportedNotification object:nil];
    
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 44, 0)];
    
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    
    self.dataSource = [[MTListViewControllerDataSource alloc] initWithIndexPathMutableDict:self.dict archive:self.archive];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.tableView.dataSource = self.dataSource;
    self.tableView.rowHeight = 90;
    
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognized:)];
    [self.tableView addGestureRecognizer:self.longPressGestureRecognizer];
    
    [[MTThemer sharedInstance] themeMTListViewController:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self manageStatusBarVisiblity];
}


- (void)applyTheme:(NSNotification *)notification {
    
    [[MTThemer sharedInstance] themeDefaultUITableView:self.tableView];
    [self.tableView reloadData];
    [[MTThemer sharedInstance] themeMTListViewController:self];
}


#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self.dict nilOrEmptyArrayForSection:indexPath.section]) {
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    FCModel<MTModelProtocol> *model = [self.dict objectAtIndexPath:indexPath];
    
    
    if (model.ownMedia) {
        [self performSegueWithIdentifier:MTShowOwnMediaSegueIdentifier sender:indexPath];
        return;
    }
    
    [self performSegueWithIdentifier:MTShowDetailSegueIdentifier sender:indexPath];
    
    return;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    NSString *title = [self.dataSource tableView:tableView titleForHeaderInSection:section];
    MTListSectionHeader *view = [[MTListSectionHeader alloc] initWithTitle:title];
    return view;
    
}


- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
        NSInteger row = 0;
        if (sourceIndexPath.section < proposedDestinationIndexPath.section) {
            row = [tableView numberOfRowsInSection:sourceIndexPath.section] - 1;
        }
        return [NSIndexPath indexPathForRow:row inSection:sourceIndexPath.section];
    }
    
    return proposedDestinationIndexPath;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return @[self.archiveAction, self.deleteAction];
}


#pragma mark - FCModel Notifications

- (void)updateTableViewOnInsert:(NSNotification *)notification {
    
    for (FCModel *insertModel in notification.userInfo[FCModelInstanceSetKey]) {
        NSInteger section = -1;
        
        section = [self sectionForModelType:insertModel];
        
        if (section == -1) {
            return;
        }
        [self.dict reloadArrayForSection:section archived:self.archive];
        [self.tableView reloadData];
        
        NSInteger numerOfRowsInSection = [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:section];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numerOfRowsInSection-1 inSection:section] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    
    
    
    [self.navigationController popViewControllerAnimated:NO];
    
}


- (void)updateTableViewOnUpdate:(NSNotification *)notification {
    
    if (self.cellIsMoving) {
        return;
    }
    
    
    for (FCModel<MTModelProtocol> *insertModel in notification.userInfo[FCModelInstanceSetKey]) {
        
        if (self.archive && insertModel.archived) {
            NSLog(@"archive: receive new entry");
        }
                  
        if (!self.archive && insertModel.archived) {
            NSLog(@"normal list: remove entry to archive");
            return;
        }
        
        if (self.archive && !insertModel.archived) {
            NSLog(@"archive: unarchive entry");
            return;
        }
        
        if (!self.archive && !insertModel.archived) {
            NSLog(@"normal list: receive unarchived entry");
        }
        
        NSInteger section = -1;
        
        section = [self sectionForModelType:insertModel];
        
        if (section == -1) {
            return;
        }
        
        [self.dict reloadArrayForSection:section archived:self.archive];
        [self.tableView reloadData];
    }
}


#pragma mark - Dealloc 

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Getter/Setter

- (UITableViewRowAction *)archiveAction {
    if (!_archiveAction) {
        
        __weak MTListViewController *welf = self;
        
        NSString *localizedContextAwareArchiveString;
        
        if (self.archive) {
            localizedContextAwareArchiveString = NSLocalizedString(@"mtlistviewcontroller.rowaction.unarchive", "unarchive");
        } else {
            localizedContextAwareArchiveString = NSLocalizedString(@"mtlistviewcontroller.rowaction.archive", @"archive");
        }
        
        _archiveAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:localizedContextAwareArchiveString handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            
            [welf.dataSource tableView:welf.tableView archiveOrUnarchive:!self.archive rowAtIndexPath:indexPath];
            
        }];
        _archiveAction.backgroundColor = [MHFancyPants colorForKey:MTTintColor];
        
    }
    
    return _archiveAction;
}

- (UITableViewRowAction *)deleteAction {
    if (!_deleteAction) {
        __weak MTListViewController *welf = self;
        _deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"mtlistviewcontroller.rowaction.delete", @"delete") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [welf.dataSource tableView:welf.tableView deleteRowAtIndexPath:indexPath];
        }];
    }
    
    return _deleteAction;
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = (NSIndexPath *)sender;
        
    FCModel<MTModelProtocol> *selectedModel = [self.dict objectAtIndexPath:indexPath ];
    
    if ([segue.identifier isEqualToString:MTShowOwnMediaSegueIdentifier]) {
        MTOwnMediaViewController *ownDetail = (MTOwnMediaViewController *)segue.destinationViewController;
        ownDetail.fromSearchViewController = NO;
        ownDetail.fromArchiveViewController = self.archive;
        ownDetail.detailModel = selectedModel;
        return;
    } else if ([segue.identifier isEqualToString:MTShowDetailSegueIdentifier]){
        MTDetailViewController *detailController = (MTDetailViewController *)segue.destinationViewController;
        detailController.fromSearchViewController = NO;
        detailController.fromArchiveViewController = self.archive;
        detailController.detailModel = selectedModel;
    }
    
}


#pragma mark - Editingmode

- (void)enterEditingMode {
    self.tableView.editing = YES;
}

- (void)leaveEditingMode {
    self.tableView.editing = NO;
    [self.dict updateArrayOrders];
}


- (void)longPressGestureRecognized:(id)sender {

    if (self.tableView.editing) {
        return;
    }
    
    self.tableView.scrollEnabled = NO;
    
    UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)sender;
    UIGestureRecognizerState state = longPress.state;
    
    CGPoint location = [longPress locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    static UIView       *snapshot = nil;
    static NSIndexPath  *sourceIndexPath = nil;
    
    MTScrollCell *cell = (MTScrollCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    switch (state) {
        case UIGestureRecognizerStateBegan: {
            if (![self.tableView.dataSource tableView:self.tableView canMoveRowAtIndexPath:indexPath]) {
                break;
            }
            
            self.cellIsMoving = YES;
            
            if (indexPath) {
                sourceIndexPath = indexPath;

                
                snapshot = [self customSnapshoFromView:cell];
                
                CGPoint center = cell.center;
                snapshot.center = center;
                snapshot.alpha = 0.98f;
                
                [self.tableView addSubview:snapshot];
                
                if ([cell respondsToSelector:@selector(hideAllElements:)]) {
                    [cell hideAllElements:YES];
                }
            }
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            CGPoint center = snapshot.center;
            center.y = location.y;
            snapshot.center = center;
            
            if (indexPath.section != sourceIndexPath.section) {
                break;
            }
            
            if (indexPath && ![indexPath isEqual:sourceIndexPath]) {
                [self.tableView.dataSource tableView:self.tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:indexPath];
                [self.tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:indexPath];
                sourceIndexPath = indexPath;
            }
            break;
        }
            
        default: {
            UITableViewCell *sourceCell = [self.tableView cellForRowAtIndexPath:sourceIndexPath];
            
            [UIView animateWithDuration:0.4 animations:^{
                snapshot.center = sourceCell.center;
            } completion:^(BOOL finished) {
                if ([sourceCell respondsToSelector:@selector(hideAllElements:)]) {
                    [(MTScrollCell *)sourceCell hideAllElements:NO];
                }
                
                self.cellIsMoving = NO;
                self.tableView.scrollEnabled = YES;
                
                [snapshot removeFromSuperview];
                snapshot = nil;
                
            }];
            
            [self.dataSource saveSectionToDatabase:sourceIndexPath.section];
            sourceIndexPath = nil;
            break;
        }
            
    }
}

#pragma mark - RefreshControl

- (IBAction)triggerRefreshControl:(id)sender {
    
    [[MTItunesClient sharedClient] refreshAllMedia:^(NSArray *results, NSError *error) {
        [self.refreshControll endRefreshing];
    }];
    
}


#pragma mark - Helper methods

- (UIView *)customSnapshoFromView:(UIView *)inputView {
    
    UIView *snapshot = [inputView snapshotViewAfterScreenUpdates:NO];
    snapshot.layer.masksToBounds = NO;
    snapshot.layer.cornerRadius = 0.0;
    snapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0);
    snapshot.layer.shadowRadius = 5.0;
    snapshot.layer.shadowOpacity = 0.4f;
    
    return snapshot;
}

- (NSInteger)sectionForModelType:(id)model {
    NSInteger section = -1;
    
    if ([model isKindOfClass:[MusicAlbum class]]) {
        section = MTSectionTypeMusic;
    } else if ([model isKindOfClass:[Movie class]]) {
        section = MTSectionTypeMovie;
    } else if ([model isKindOfClass:[App class]]) {
        section = MTSectionTypeApp;
    } else if ([model isKindOfClass:[Book class]]) {
        section = MTSectionTypeBook;
    } else if ([model isKindOfClass:[TVSeason class]]) {
        section = MTSectionTypeTVShow;
    }
    
    return section;
}

- (void)showAddView {
    [self hideStatusBarIfNoArchive];
    [self.tableView setContentOffset:self.tableView.contentOffset animated:NO];
}

- (void)hideAddView {
    [self manageStatusBarVisiblity];
}

- (void)manageStatusBarVisiblity {
    if (self.archive) {
        self.navigationItem.title = NSLocalizedString(@"mtlistviewcontroller.navigationitem.title.archive", "archive");
        [[NSNotificationCenter defaultCenter] postNotificationName:MTHideStatusBarView object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:MTShowStatusBarView object:nil];
    }
}

- (void)hideStatusBarIfNoArchive {
    if (self.archive) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MTHideStatusBarView object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:MTHideStatusBarView object:nil];
    }
}

- (void)reloadAll {
    [self.dict reloadArrayForSection:MTSectionTypeMusic archived:self.archive];
    [self.dict reloadArrayForSection:MTSectionTypeMovie archived:self.archive];
    [self.dict reloadArrayForSection:MTSectionTypeApp archived:self.archive];
    [self.dict reloadArrayForSection:MTSectionTypeBook archived:self.archive];
    [self.dict reloadArrayForSection:MTSectionTypeTVShow archived:self.archive];
    [self.tableView reloadData];
}

@end
