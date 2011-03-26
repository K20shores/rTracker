//
//  RootViewController.m
//  rTracker
//
//  Created by Robert Miller on 16/03/2010.
//  Copyright Robert T. Miller 2010. All rights reserved.
//

#import "RootViewController.h"
#import "rTrackerAppDelegate.h"
#import "addTrackerController.h"
#import "configTlistController.h"
#import "useTrackerController.h"
#import "rTracker-resource.h"
#import "privacyV.h"

#import "CSVParser.h"

@implementation RootViewController

@synthesize tlist;
@synthesize privateBtn, privacyObj;

#pragma mark -
#pragma mark core object methods and support

- (void)dealloc {
	
	NSLog(@"rvc dealloc");
	self.tlist = nil;
	[tlist release];
	
    [super dealloc];
}

/*
- (void)applicationWillTerminate:(NSNotification *)notification {
	NSLog(@"rvc: app will terminate");
	// close trackerList
	
}
*/

#pragma mark -
#pragma mark load CSV files waiting for input

//
// original code:
//-------------------
//  Created by Matt Gallagher on 2009/11/30.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//-------------------
//
// receiveRecord:
//
// Receives a row from the CSVParser
//
// Parameters:
//    aRecord - the row
//
/*
- (void)receiveRecord:(NSDictionary *)aRecord
{
	for (NSString *key in aRecord)
	{
        NSLog(@"key= %@  value=%@",key,[aRecord objectForKey:key]);
	}
}
*/

- (void) loadInputFiles {
    NSLog(@"loadInputFiles");
    NSString *docsDir = [rTracker_resource ioFilePath:nil access:YES];
    NSFileManager *localFileManager=[[NSFileManager alloc] init];
    NSDirectoryEnumerator *dirEnum = [localFileManager enumeratorAtPath:docsDir];

    [self.tlist loadTopLayoutTable];
	//[self.tableView reloadData];
    
    NSString *file;
    while ((file = [dirEnum nextObject])) {
        if ([[file pathExtension] isEqualToString: @"csv"]) {
            NSString *fname = [file lastPathComponent];
            NSRange inmatch = [fname rangeOfString:@"_in.csv" options:NSBackwardsSearch|NSAnchoredSearch];
            NSLog(@"consider input: %@",fname);
            
            if (inmatch.location == NSNotFound) {
                
            } else if (inmatch.length == 7) {
                NSString *tname = [fname substringToIndex:inmatch.location];
                NSLog(@"load input: %@ as %@",fname,tname);
                int ndx=0;
                for (NSString *tracker in self.tlist.topLayoutNames) {
                    if ([tracker isEqualToString:tname]) {
                        NSLog(@"match to: %@",tracker);
                        NSString *target = [docsDir stringByAppendingPathComponent:file];
                        //NSError *error = nil;
                        NSString *csvString = [NSString stringWithContentsOfFile:target encoding:NSUTF8StringEncoding error:NULL];
                        
                        /*
                        if (!csvString)
                        {
                         NSLog(@"Couldn't read file at path %s\n. Error: %s",
                                   [file UTF8String],
                                   [[error localizedDescription] ? [error localizedDescription] : [error description] UTF8String]);
                            NSAssert(0,@"file issue.");
                        }
                        */
                        if (csvString)
                        {
                            trackerObj *to = [[trackerObj alloc] init:[self.tlist getTIDfromName:tname]];

                            CSVParser *parser = [[CSVParser alloc] initWithString:csvString separator:@"," hasHeader:YES fieldNames:nil];
                            [parser parseRowsForReceiver:to selector:@selector(receiveRecord:)];
                            
                            [to release];
                        }
                        ndx++;
                    }
                }
            }
            
        }
    }
    [localFileManager release];    
}

#pragma mark -
#pragma mark view support

- (void)viewDidLoad {
	NSLog(@"rvc: viewDidLoad privacy= %d",[privacyV getPrivacyValue]);
    self.title = @"rTracker";

	UIBarButtonItem *addBtn = [[UIBarButtonItem alloc]
								initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
								target:self
								action:@selector(btnAddTracker)];
	self.navigationItem.rightBarButtonItem = addBtn;
	[addBtn release];
	
	[self setToolbarItems:[NSArray arrayWithObjects: 
						   //self.flexibleSpaceButtonItem,
						   //self.payBtn, 
                           self.privateBtn, 
                           //self.multiGraphBtn, 
						   //self.flexibleSpaceButtonItem, 
						   nil] 
				 animated:NO];
	
	//[payBtn release];
	[privateBtn release];
	//[multiGraphBtn release];

	self.tlist = [[trackerList alloc] init];

    [self loadInputFiles];
    
	/*
	UIApplication *app = [UIApplication sharedApplication];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(applicationWillTerminate:) 
												 name:UIApplicationWillTerminateNotification
											   object:app];
	
	 */
	
	[super viewDidLoad];
	
}

- (void) refreshView {
	[self.tlist loadTopLayoutTable];
	[self.tableView reloadData];
    
	if ([self.tlist.topLayoutNames count] == 0) {
		if (self.navigationItem.leftBarButtonItem != nil) {
			self.navigationItem.leftBarButtonItem = nil;
		}
	} else {
		if (self.navigationItem.leftBarButtonItem == nil) {
			
			UIBarButtonItem *editBtn = [[UIBarButtonItem alloc]
										initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
										target:self
										action:@selector(btnEdit)];
			self.navigationItem.leftBarButtonItem = editBtn;
			[editBtn release];
		}
	}
}

- (void)viewWillAppear:(BOOL)animated {

	NSLog(@"rvc: viewWillAppear privacy= %d", [privacyV getPrivacyValue]);	
	[self refreshView];
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	
	NSLog(@"rvc didReceiveMemoryWarning");
	// Release any cached data, images, etc that aren't in use.

    [super didReceiveMemoryWarning];


}

- (void)viewDidUnload {
	// Release anything that can be recreated in viewDidLoad or on demand.
	// e.g. self.myOutlet = nil;
	
	NSLog(@"rvc viewDidUnload");

	self.title = nil;
	self.navigationItem.rightBarButtonItem = nil;
	self.navigationItem.leftBarButtonItem = nil;
	[self setToolbarItems:nil
				 animated:NO];
	
	self.tlist = nil;
	
	//NSLog(@"pb rc= %d  mgb rc= %d", [self.privateBtn retainCount], [self.multiGraphBtn retainCount]);
	
}


#pragma mark -
#pragma mark button accessor getters

/*
 - (UIBarButtonItem *) payBtn {
	if (payBtn == nil) {
		payBtn = [[UIBarButtonItem alloc]
					  initWithTitle:@"$"
					  style:UIBarButtonItemStyleBordered
					  target:self
					  action:@selector(btnPay)];
	}
	return payBtn;
}
*/

- (UIBarButtonItem *) privateBtn {
	if (privateBtn == nil) {
		privateBtn = [[UIBarButtonItem alloc]
					   initWithTitle:@"private"
					   style:UIBarButtonItemStyleBordered
					   target:self
					   action:@selector(btnPrivate)];
	}
	return privateBtn;
}

/*
 - (UIBarButtonItem *) multiGraphBtn {
	if (multiGraphBtn == nil) {
		multiGraphBtn = [[UIBarButtonItem alloc]
					  initWithTitle:@"Multi-Graph"
					  style:UIBarButtonItemStyleBordered
					  target:self
					  action:@selector(btnMultiGraph)];
	}
	return multiGraphBtn;
}
*/

- (privacyV*) privacyObj {
	if (privacyObj == nil) {
		privacyObj = [[privacyV alloc] initWithParentView:self.view];
	}
	privacyObj.tob = (id) self.tlist;  // not set at init
	return privacyObj;
}

#pragma mark -
#pragma mark button action methods

- (void) btnAddTracker {
	//NSLog(@"btnAddTracker was pressed!");
	
	addTrackerController *atc = [[addTrackerController alloc] initWithNibName:@"addTrackerController" bundle:nil ];
	atc.tlist = self.tlist;
	[self.navigationController pushViewController:atc animated:YES];
	[atc release];
	
}

- (IBAction)btnEdit {
	//NSLog(@"btnConfig was pressed!");
	
	configTlistController *ctlc = [[configTlistController alloc] initWithNibName:@"configTlistController" bundle:nil ];
	ctlc.tlist = self.tlist;
	[self.navigationController pushViewController:ctlc animated:YES];
	[ctlc release];
	
}
	
- (void)btnMultiGraph {
	NSLog(@"btnMultiGraph was pressed!");
}

- (void)btnPrivate {
	NSLog(@"btnPrivate was pressed!");
	
	[self.privacyObj togglePrivacySetter ];
	if (0 != self.privacyObj.showing) {
		self.privateBtn.title = @"dismiss";
	} else {
		self.privateBtn.title = @"private";
		[self refreshView];
		
	}
}

- (void)btnPay {
	NSLog(@"btnPay was pressed!");
	
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.tlist.topLayoutNames count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"rvc table cell at index %d label %@",[indexPath row],[tlist.topLayoutNames objectAtIndex:[indexPath row]]);
	
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	// Configure the cell.
	NSUInteger row = [indexPath row];
	cell.textLabel.text = [self.tlist.topLayoutNames objectAtIndex:row];

    return cell;
}



// Override to support row selection in the table view.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	NSUInteger row = [indexPath row];
	NSLog(@"selected row %d : %@", row, [self.tlist.topLayoutNames objectAtIndex:row]);
	
	trackerObj *to = [[trackerObj alloc] init:[self.tlist getTIDfromIndex:row]];
	[to describe];

	useTrackerController *utc = [[useTrackerController alloc] initWithNibName:@"useTrackerController" bundle:nil ];
	utc.tracker = to;
	[self.navigationController pushViewController:utc animated:YES];
	[utc release];
	
	[to release];
	
}

@end

