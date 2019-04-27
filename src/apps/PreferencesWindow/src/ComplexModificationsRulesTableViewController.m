#import "ComplexModificationsRulesTableViewController.h"
#import "ComplexModificationsAssetsOutlineCellView.h"
#import "KarabinerKit/KarabinerKit.h"
#import "NotificationKeys.h"

@interface ComplexModificationsRulesTableViewController ()

@property(weak) IBOutlet NSButton* downButton;
@property(weak) IBOutlet NSButton* upButton;
@property(weak) IBOutlet NSOutlineView* assetsOutlineView;
@property(weak) IBOutlet NSPanel* addRulePanel;
@property(weak) IBOutlet NSTabViewItem* complexModificationsTabViewItem;
@property(weak) IBOutlet NSTabViewItem* rulesTabViewItem;
@property(weak) IBOutlet NSTableView* tableView;
@property(weak) IBOutlet NSWindow* window;
@property id configurationLoadedObserver;

@end

@implementation ComplexModificationsRulesTableViewController

- (void)setup {
  self.configurationLoadedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kKarabinerKitConfigurationIsLoaded
                                                                                       object:nil
                                                                                        queue:[NSOperationQueue mainQueue]
                                                                                   usingBlock:^(NSNotification* note) {
                                                                                     [self.tableView reloadData];
                                                                                   }];

  [self updateUpDownButtons];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self.configurationLoadedObserver];
}

- (IBAction)openRulesSite:(id)sender {
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://pqrs.org/osx/karabiner/complex_modifications/"]];
}

- (void)removeRule:(id)sender {
  NSInteger row = [self.tableView rowForView:sender];

  KarabinerKitCoreConfigurationModel* coreConfigurationModel = [KarabinerKitConfigurationManager sharedManager].coreConfigurationModel;
  [coreConfigurationModel removeSelectedProfileComplexModificationsRule:row];
  [coreConfigurationModel save];

  [self.tableView reloadData];
}

- (void)updateUpDownButtons {
  self.downButton.enabled = NO;
  self.upButton.enabled = NO;

  if (self.tableView.selectedRow < 0) {
    return;
  }

  if (self.tableView.selectedRow > 0) {
    self.upButton.enabled = YES;
  }
  if (self.tableView.selectedRow < self.tableView.numberOfRows - 1) {
    self.downButton.enabled = YES;
  }
}

- (IBAction)moveRuleUp:(id)sender {
  NSInteger row = self.tableView.selectedRow;

  if (row < 0) {
    return;
  }

  if (row > 0) {
    KarabinerKitCoreConfigurationModel* coreConfigurationModel = [KarabinerKitConfigurationManager sharedManager].coreConfigurationModel;
    [coreConfigurationModel swapSelectedProfileComplexModificationsRules:row
                                                                  index2:row - 1];
    [coreConfigurationModel save];

    [self.tableView reloadData];

    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:(row - 1)];
    [self.tableView selectRowIndexes:indexes byExtendingSelection:NO];
  }
}

- (IBAction)moveRuleDown:(id)sender {
  NSInteger row = self.tableView.selectedRow;

  if (row < 0) {
    return;
  }

  if (row < self.tableView.numberOfRows - 1) {
    KarabinerKitCoreConfigurationModel* coreConfigurationModel = [KarabinerKitConfigurationManager sharedManager].coreConfigurationModel;
    [coreConfigurationModel swapSelectedProfileComplexModificationsRules:row
                                                                  index2:row + 1];
    [coreConfigurationModel save];

    [self.tableView reloadData];

    NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:(row + 1)];
    [self.tableView selectRowIndexes:indexes byExtendingSelection:NO];
  }
}

- (IBAction)openAddRulePanel:(id)sender {
  if (self.complexModificationsTabViewItem.tabState != NSSelectedTab) {
    [self.complexModificationsTabViewItem.tabView selectTabViewItem:self.complexModificationsTabViewItem];
  }
  if (self.rulesTabViewItem.tabState != NSSelectedTab) {
    [self.rulesTabViewItem.tabView selectTabViewItem:self.rulesTabViewItem];
  }

  [[KarabinerKitComplexModificationsAssetsManager sharedManager] reload];
  [self.assetsOutlineView reloadData];
  [self.assetsOutlineView expandItem:nil expandChildren:YES];

  [self.window beginSheet:self.addRulePanel
        completionHandler:^(NSModalResponse returnCode){}];
}

- (void)eraseImportedFile:(NSButton*)sender {
  if (sender.superview.class == ComplexModificationsAssetsOutlineCellView.class) {
    ComplexModificationsAssetsOutlineCellView* view = (ComplexModificationsAssetsOutlineCellView*)(sender.superview);

    NSArray* files = [KarabinerKitComplexModificationsAssetsManager sharedManager].assetsFileModels;
    if (view.fileIndex < files.count) {
      KarabinerKitComplexModificationsAssetsFileModel* model = files[view.fileIndex];

      NSAlert* alert = [NSAlert new];

      alert.messageText = @"确认";
      alert.informativeText = @"您确定要删除此导入的文件吗？";
      [alert addButtonWithTitle:@"删除"];
      [alert addButtonWithTitle:@"取消"];

      [alert beginSheetModalForWindow:self.addRulePanel
                    completionHandler:^(NSModalResponse returnCode) {
                      if (returnCode == NSAlertFirstButtonReturn) {
                        [model unlinkFile];

                        [[KarabinerKitComplexModificationsAssetsManager sharedManager] reload];
                        [self.assetsOutlineView reloadData];
                        [self.assetsOutlineView expandItem:nil expandChildren:YES];
                      }
                    }];
    }
  }
}

- (void)addAllRules:(NSButton*)sender {
  if (sender.superview.class == ComplexModificationsAssetsOutlineCellView.class) {
    ComplexModificationsAssetsOutlineCellView* view = (ComplexModificationsAssetsOutlineCellView*)(sender.superview);

    NSArray* files = [KarabinerKitComplexModificationsAssetsManager sharedManager].assetsFileModels;
    if (view.fileIndex < files.count) {
      KarabinerKitComplexModificationsAssetsFileModel* fileModel = files[view.fileIndex];
      KarabinerKitCoreConfigurationModel* coreConfigurationModel = [KarabinerKitConfigurationManager sharedManager].coreConfigurationModel;
      for (KarabinerKitComplexModificationsAssetsRuleModel* ruleModel in fileModel.rules) {
        [ruleModel addRuleToCoreConfigurationProfile:coreConfigurationModel];
      }
      [coreConfigurationModel save];
      [self.tableView reloadData];
    }
  }
  [self.window endSheet:self.addRulePanel];
}

- (void)addRule:(NSButton*)sender {
  if (sender.superview.class == ComplexModificationsAssetsOutlineCellView.class) {
    ComplexModificationsAssetsOutlineCellView* view = (ComplexModificationsAssetsOutlineCellView*)(sender.superview);

    NSArray* files = [KarabinerKitComplexModificationsAssetsManager sharedManager].assetsFileModels;
    if (view.fileIndex < files.count) {
      KarabinerKitComplexModificationsAssetsFileModel* fileModel = files[view.fileIndex];
      if (view.ruleIndex < fileModel.rules.count) {
        KarabinerKitCoreConfigurationModel* coreConfigurationModel = [KarabinerKitConfigurationManager sharedManager].coreConfigurationModel;
        KarabinerKitComplexModificationsAssetsRuleModel* ruleModel = fileModel.rules[view.ruleIndex];
        [ruleModel addRuleToCoreConfigurationProfile:coreConfigurationModel];
        [coreConfigurationModel save];
        [self.tableView reloadData];
      }
    }
  }
  [self.window endSheet:self.addRulePanel];
}

- (IBAction)expandRules:(id)sender {
  [self.assetsOutlineView expandItem:nil expandChildren:YES];
}

- (IBAction)collapseRules:(id)sender {
  [self.assetsOutlineView collapseItem:nil collapseChildren:YES];
}

- (IBAction)closeAddRulePanel:(id)sender {
  [self.window endSheet:self.addRulePanel];
}

@end