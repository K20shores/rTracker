/***************
 voText.m
 Copyright 2010-2016 Robert T. Miller
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 *****************/

//
//  voText.m
//  rTracker
//
//  Created by Robert Miller on 01/11/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

#import "voText.h"
#import "dbg-defs.h"
#import "rTracker-constants.h"
#import "rTracker-resource.h"

@implementation voText

@synthesize dtf=_dtf;

- (int) getValCap {  // NSMutableString size for value
    return 32;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	//DBGLog(@"tf begin editing");
    self.startStr = textField.text;
	((trackerObj*) self.vo.parentTracker).activeControl = (UIControl*) textField;
}

- (void)textFieldDidChange:(UITextField *)textField {
    //[[NSNotificationCenter defaultCenter] postNotificationName:rtValueUpdatedNotification object:self];
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
	//DBGLog(@"tf end editing");
    if (! [self.startStr isEqualToString:textField.text]) {
        [self.vo.value setString:textField.text];
        //textField.textColor = [UIColor blackColor];
        [[NSNotificationCenter defaultCenter] postNotificationName:rtValueUpdatedNotification object:self];
        self.startStr=nil;
    }
	((trackerObj*) self.vo.parentTracker).activeControl = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	// the user pressed the "Done" button, so dismiss the keyboard
	//DBGLog(@"textField done: %@", textField.text);
	[textField resignFirstResponder];
	return YES;
}



- (UITextField*) dtf {
    safeDispatchSync(^{
        if (self->_dtf && self->_dtf.frame.size.width != self.vosFrame.size.width) self->_dtf=nil;  // first time around thinks size is 320, handle larger devices
    });
    
    if (nil == _dtf) {
        _dtf = [[UITextField alloc] initWithFrame:self.vosFrame];
        
        if (@available(iOS 13.0, *)) {
            _dtf.textColor = [UIColor labelColor];
            _dtf.backgroundColor = [UIColor secondarySystemBackgroundColor];
        } else {
            _dtf.textColor = [UIColor blackColor];
            _dtf.backgroundColor = [UIColor whiteColor];
        }
        
        _dtf.borderStyle = UITextBorderStyleRoundedRect;  //Bezel;
        _dtf.font = PrefBodyFont;  //[UIFont systemFontOfSize:17.0];
        _dtf.autocorrectionType = UITextAutocorrectionTypeNo;	// no auto correction support
        
        _dtf.keyboardType = UIKeyboardTypeDefault;	// use the full keyboard
        _dtf.placeholder = @"<enter text>";
        
        _dtf.returnKeyType = UIReturnKeyDone;
        
        _dtf.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right
        
        //dtf.tag = kViewTag;		// tag this control so we can remove it later for recycled cells
        _dtf.delegate = self;	// let us be the delegate so we know when the keyboard's "Done" button is pressed
        
        // Add an accessibility label that describes what the text field is for.
        [_dtf setAccessibilityLabel:NSLocalizedString(@"NormalTextField", @"")];
        _dtf.text = @"";
        [_dtf addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }
    
    return _dtf;
}

- (void) resetData {
    if (nil != _dtf) { // not self, do not instantiate
        if ([NSThread isMainThread]) {
            self.dtf.text = @"";
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                self.dtf.text = @"";
            });
        }
    }
    self.vo.useVO = YES;
}

- (UIView*)voDisplay:(CGRect)bounds {
	self.vosFrame = bounds;

	if (![self.vo.value isEqualToString:self.dtf.text]) {
        safeDispatchSync(^{
            self.dtf.text = self.vo.value;
        });
        DBGLog(@"dtf: vo val= %@ dtf txt= %@", self.vo.value, self.dtf.text);
    }
	
    DBGLog(@"textfield voDisplay: %@", self.dtf.text);
	return self.dtf;
}


- (NSString*) update:(NSString*)instr {   // confirm textfield not forgotten
    if ((nil == _dtf) // NOT self.dtf as we want to test if is instantiated
        ||
        !([instr isEqualToString:@""])
        ){ 
        return instr;
    }
    __block NSString *cpy;
    safeDispatchSync(^{
        cpy = [NSString stringWithString:self.dtf.text];
    });
    return cpy;
}

#pragma mark -
#pragma mark options page 

- (void) setOptDictDflts {
    
    
    return [super setOptDictDflts];
}

- (BOOL) cleanOptDictDflts:(NSString*)key {
    /*
    NSString *val = [self.vo.optDict objectForKey:key];
    if (nil == val) 
        return YES;
    if (([key isEqualToString:@"shrinkb"] && [val isEqualToString:(SHRINKBDFLT ? @"1" : @"0")])
        ) {
        [self.vo.optDict removeObjectForKey:key];
        return YES;
    }
    */
    return [super cleanOptDictDflts:key];
}

- (void) voDrawOptions:(configTVObjVC*)ctvovc {
	CGRect labframe = [ctvovc configLabel:@"Options:" 
								  frame:(CGRect) {MARGIN,ctvovc.lasty,0.0,0.0}
									key:@"gooLab" 
								  addsv:YES ];
	
	ctvovc.lasty += labframe.size.height + MARGIN;
	[super voDrawOptions:ctvovc];
}

#pragma mark -
#pragma mark graph display
/*
- (void) transformVO:(NSMutableArray *)xdat ydat:(NSMutableArray *)ydat dscale:(double)dscale height:(CGFloat)height border:(float)border firstDate:(int)firstDate {
    
    [self transformVO_note:xdat ydat:ydat dscale:dscale height:height border:border firstDate:firstDate];
    
}
*/

- (id) newVOGD {
    return [[vogd alloc] initAsNote:self.vo];
}



@end
