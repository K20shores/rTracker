//
//  addValObjController.h
//  rTracker
//
//  Created by Robert Miller on 12/05/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "valueObj.h"
#import "trackerObj.h"

@interface addValObjController : UIViewController <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource> 
{
	valueObj *tempValObj;
	trackerObj *parentTrackerObj;
	NSArray *graphTypes;

	UITextField *labelField;
	UIPickerView *votPicker;
}

@property (nonatomic,retain) valueObj *tempValObj;
@property (nonatomic,retain) trackerObj *parentTrackerObj;  // this makes a retain cycle....
@property (nonatomic,retain) NSArray *graphTypes;

@property (nonatomic,retain) IBOutlet UITextField *labelField;
@property (nonatomic,retain) IBOutlet UIPickerView *votPicker;

+(CGSize) maxLabelFromArray:(const NSArray *)arr;

- (void) updateColorCount;
- (void) updateForPickerRowSelect:(NSInteger)row inComponent:(NSInteger)component;
//- (void) btnSetup;

@end
