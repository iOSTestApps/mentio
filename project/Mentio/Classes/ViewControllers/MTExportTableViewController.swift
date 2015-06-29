//
//  MTExportTableViewController.swift
//  
//
//  Created by Martin Hartl on 18/06/15.
//
//

import UIKit

class MTExportTableViewController: UITableViewController {

    @IBOutlet weak var labelExport: UILabel!
    
    var interactionController: UIDocumentInteractionController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let prefFont = UIFont.preferredAvenirFontForTextStyle(UIFontTextStyleBody);
        self.labelExport.font = prefFont
        self.labelExport.text = NSLocalizedString("mtsettingsviewcontroller.exportlabel.text", comment: "more information");
        self.labelExport.textColor = MHFancyPants.colorForKey(MTHeadingTextColor)
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return NSLocalizedString("mtexporttableviewcontroller.tableview.footer.text", comment: "export text");
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
        case 0:
            self.exportDatabase()
        default:
            return
        }
    }
    
    // MARK: - Helper
    
    func exportDatabase() {
        if let url = NSURL(fileURLWithPath: MTDatabaseManager.databasePath()) {
            self.interactionController = UIDocumentInteractionController(URL: url)
            let success = self.interactionController?.presentOptionsMenuFromRect(self.labelExport.bounds, inView: self.view, animated: true)
            
        }
        
    }
}
