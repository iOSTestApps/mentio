//
//  MTSettingsViewController.m
//  Mentio
//
//  Created by Martin Hartl on 11/11/13.
//  Copyright (c) 2013 Martin Hartl. All rights reserved.
//

#import "MTSettingsViewController.h"
#import "MTThemer.h"
#import "UIFont+CustomFontsContentSizes.h"
#import <MessageUI/MessageUI.h>
#import "MTStatusBarConstants.h"

@interface MTSettingsViewController () <MTThemeProtocol, MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *useLightThemeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *labelCountrySettings;
@property (weak, nonatomic) IBOutlet UILabel *labelUseLightTheme;
@property (weak, nonatomic) IBOutlet UILabel *labelContact;
@property (weak, nonatomic) IBOutlet UILabel *labelFollowOnTwitter;
@property (weak, nonatomic) IBOutlet UILabel *labelRateMentio;
@property (weak, nonatomic) IBOutlet UILabel *labelAttribution;
@property (weak, nonatomic) IBOutlet UILabel *labelAffiliateToken;
@property (weak, nonatomic) IBOutlet UILabel *labelArchive;
@property (weak, nonatomic) IBOutlet UILabel *labelExport;
@end

@implementation MTSettingsViewController

- (void)applyTheme:(NSNotification *)notification {
    [[MTThemer sharedInstance] themeDefaultUITableView:self.tableView];
    [[MTThemer sharedInstance] themeMTSettingsViewController:self];
    [self.tableView reloadData];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = NSLocalizedString(@"Settings", @"Settings");
    self.labelCountrySettings.text = NSLocalizedString(@"Country Settings", @"Country Settings");
    self.labelUseLightTheme.text = NSLocalizedString(@"Use light theme", @"Use light theme");
    
    self.labelContact.text = NSLocalizedString(@"contact/sendfeedback", @"contactsendfeedback");
    self.labelFollowOnTwitter.text = NSLocalizedString(@"followMeOnTwitter", @"followMeOnTwitter");
    self.labelRateMentio.text = NSLocalizedString(@"rateMentio", @"rateMentio");
    self.labelAttribution.text = NSLocalizedString(@"acknowledgment.title", @"Attribution");
    self.labelAffiliateToken.text = NSLocalizedString(@"mtsettingsviewcontroller.settokenlabel.text", @"use own token");
    self.labelArchive.text = NSLocalizedString(@"mtsettingsviewcontroller.archivelabel.text", "archive");
    self.labelExport.text = NSLocalizedString(@"mtsettingsviewcontroller.exportlabel.text", @"export");
    
    UIFont *prefFont = [UIFont preferredAvenirFontForTextStyle:UIFontTextStyleBody];
    
    self.labelAttribution.font = prefFont;
    self.labelContact.font = prefFont;
    self.labelCountrySettings.font = prefFont;
    self.labelFollowOnTwitter.font = prefFont;
    self.labelRateMentio.font = prefFont;
    self.labelUseLightTheme.font = prefFont;
    self.labelAffiliateToken.font = prefFont;
    self.labelArchive.font = prefFont;
    self.labelExport.font = prefFont;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 50, 0)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyTheme:) name:MTThemeChangedNotification object:nil];
    
    if ([[MTThemer sharedInstance] usesLightTheme]) {
        self.useLightThemeSwitch.on = YES;
    }
    
    [self.navigationController.navigationBar setBarStyle:[MHFancyPants integerForKey:@"tabBarStyle"]];
    [[MTThemer sharedInstance] themeMTSettingsViewController:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MTHideStatusBarView object:nil];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            return NSLocalizedString(@"Settings", @"Settings");
            break;
        case 1:
            return NSLocalizedString(@"About", @"About");
            break;
        default:
            return nil;
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1) {
        NSString *str = [NSString stringWithFormat:@"Version %@ \n%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], NSLocalizedString(@"thankforusing", "thankforusing")];
        return str;
    }
    
    return nil;
}


- (IBAction)ibaUseLightThemeSwitchTriggered:(id)sender {
    MTThemer *theme = [[MTThemer alloc] init];
    
    UISwitch *senderSwitch = (UISwitch *)sender;
    
    if (senderSwitch.on) {
        [theme setLightThemeToDefault];
    } else {
        [theme setDarkThemeToDefault];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self contactSupportMail];
        } else if (indexPath.row == 1) {
            [self followMeOnTwitter];
        } else if (indexPath.row == 2) {
            [self rateMentio];
        }
    }
}

- (void)contactSupportMail {
    
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        
        mailer.mailComposeDelegate = self;

        [mailer setSubject:[NSString stringWithFormat:@"Mentio %@",NSLocalizedString(@"contact/sendfeedback", @"contactsendfeedback")]];
        
        NSMutableString * body = [NSMutableString string];
        [body appendString:@"</br>\n"];
        [body appendString:@"</br>\n"];
        [body appendString:@"</br>\n"];
        [body appendString:@"</br>\n"];
        [body appendString:@"</br>\n"];
        [body appendString:@"</br>\n"];
        [body appendString:@"</br>\n"];
        [body appendString:@"</br>\n"];
        [body appendString:[NSString stringWithFormat:@"App-Name: %@</br>\n",  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]]];
        [body appendString:[NSString stringWithFormat:@"App-Version: %@</br>\n",   [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]];
        [body appendString:[NSString stringWithFormat:@"OS-Version: %@</br>\n",   [UIDevice currentDevice].systemVersion]];
        
        
        
        
        [mailer setMessageBody:body isHTML:YES];
        NSArray *toRecipients = [NSArray arrayWithObjects:@"mentio@mhaddl.me" ,nil];
        [mailer setToRecipients:toRecipients];
        
        [self presentViewController:mailer animated:YES completion:Nil];
    } else {
        [self cantSendMail];
    }
    
}

- (void)cantSendMail {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SETTINGS_NO_MAIL_TITLE", @"ups")
                                                    message:NSLocalizedString(@"SETTINGS_NO_MAIL_ACCOUNT_SET_UP", @"it seems no email")
                                                   delegate:nil cancelButtonTitle:NSLocalizedString(@"SETTINGS_ALERT_OK", @"ok") otherButtonTitles:nil];
    [alert show];
}

- (void)followMeOnTwitter {
    NSURL *twitterUrl = [NSURL URLWithString:@"twitter://user?screen_name=mhaddl"];
    
    if (![[UIApplication sharedApplication] openURL: twitterUrl]) {
        
        //fanPageURL failed to open. Open the website in Safari instead
        
        NSURL *webURL = [NSURL URLWithString:@"http://twitter.com/mhaddl"];
        
        [[UIApplication sharedApplication] openURL: webURL];
        
    }
}

- (void)rateMentio {
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/mentio-personal-media-wish/id796557338"]];
}

#pragma mark -
#pragma mark - Mail Composer Delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:Nil];
}

@end
