/***************
 voFunction.m
 Copyright 2010-2021 Robert T. Miller
 
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
//  voFunction.m
//  rTracker
//
//  Created by Robert Miller on 01/11/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

#import "voFunction.h"
#import "rTracker-constants.h"
#import "dbg-defs.h"
#import "rTracker-resource.h"

#if FABRIC
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#endif

@interface voFunction ()
- (void) updateFnTitles;
- (void) showConstTF;
- (void) hideConstTF;
//@property (nonatomic, retain) NSNumber *foo;
@end


@implementation voFunction

@synthesize fnStrDict=_fnStrDict, fn1args=_fn1args, fn2args=_fn2args, fnTimeOps=_fnTimeOps, epTitles=_epTitles, fnTitles=_fnTitles, fnArray=_fnArray, fnSegNdx=_fnSegNdx, ctvovcp=_ctvovcp, currFnNdx=_currFnNdx, rlab=_rlab, votWoSelf=_votWoSelf;

#pragma mark -
#pragma mark core object methods and support

BOOL FnErr=NO;

- (void) saveFnArray {
	// note this converts NSNumbers to NSStrings
	// works because NSNumber returns an NSString for [description]
	
	//[self.vo.optDict setObject:[self.fnArray componentsJoinedByString:@" "] forKey:@"func"];
	// don't save an empty string
	NSString *ts = [self.fnArray componentsJoinedByString:@" "];
    //DBGLog(@"saving fnArray ts= .%@.",ts);
	if (0 < [ts length]) {
		(self.vo.optDict)[@"func"] = ts;
	}
}

- (void) loadFnArray {

	[self.fnArray removeAllObjects];  
	// all works fine if we load as strings with 
	// [self.fnArray addObjectsFromArray: [[self.vo.optDict objectForKey:@"func"] componentsSeparatedByString:@" "];
	// but prefer to keep as NSNumbers 
	
	NSArray *tmp = [(self.vo.optDict)[@"func"] componentsSeparatedByString:@" "];
	for (NSString *s in tmp) {
        if (![@"" isEqualToString:s]) {
            //[self.fnArray addObject:[NSNumber numberWithInteger:[s integerValue]]];
            [self.fnArray addObject:@([s doubleValue])];  // because of constant
        }
	}
}

#pragma mark protocol: getValCap

- (int) getValCap {  // NSMutableString size for value
    return 32;
}

#pragma mark protocol: loadConfig

- (void) loadConfig {
	[self loadFnArray];
    if ((nil == [self.vo.optDict valueForKey:@"frep0"])) {
        (self.vo.optDict)[@"frep0"] = @FREPDFLT;
    }
    if ((nil == [self.vo.optDict valueForKey:@"frep1"])) {
        (self.vo.optDict)[@"frep1"] = @FREPDFLT;
    }
    
}

#pragma mark protocol: updateVORefs

// called to instantiate tempTrackerObj with -vid to real trackerObj on save tracker config

- (void) updateVORefs:(NSInteger)newVID old:(NSInteger)oldVID {
	[self loadFnArray];
	NSUInteger i=0;
	NSUInteger max = [self.fnArray count];
#if FUNCTIONDBG
    DBGLog(@"start fnArray= %@",self.fnArray);
#endif
	for (i=0; i< max; i++) {
		if ([(self.fnArray)[i] integerValue] == oldVID) {
			(self.fnArray)[i] = @(newVID);
		}
	}
#if FUNCTIONDBG
    DBGLog(@"fin fnArray= %@",self.fnArray);
#endif
	[self saveFnArray];
	
	for (i=0;i<2;i++) {
		NSString *key = [NSString stringWithFormat:@"frep%lu",(unsigned long)i];
		NSNumber *nep = (self.vo.optDict)[key];
		NSInteger ep = [nep integerValue];
		if (ep == oldVID) {
			(self.vo.optDict)[key] = @(newVID);
		}
	}
}


#pragma mark voFunction ivar getters

- (NSArray*) epTitles {
	if (_epTitles == nil) {
		// n.b.: tied to FREP symbol defns in voFunctions.h
		_epTitles = @[@"entry", @"hours", @"days", @"weeks", @"months", @"years",
                    @"cal days",@"cal weeks",@"cal months", @"cal years", @"<none>"];
	}
	return _epTitles;
}

// current titles to display in picker for building function
- (NSMutableArray*) fnTitles {
	if (_fnTitles == nil) {
		_fnTitles = [[NSMutableArray alloc] init];
	}
	return _fnTitles;
}

// function as built so far
- (NSMutableArray*) fnArray {
	if (_fnArray == nil) {
		_fnArray = [[NSMutableArray alloc] init];
	}
	return _fnArray;
}


// enumerate function class tokens

- (NSArray*) fn1args {
    if (nil == _fn1args) {
        int fn1argToks[] = { ARG1FNS };
        NSNumber *fn1argsArr[ARG1CNT];
        int i;
        for (i=0;i<ARG1CNT;i++) {
            fn1argsArr[i] = @(fn1argToks[i]);
        }
        _fn1args = [[NSArray alloc] initWithArray:[NSArray arrayWithObjects:fn1argsArr count:ARG1CNT] copyItems:YES];
    }
    return _fn1args;
}

- (NSArray*) fn2args {
    if (nil == _fn2args) {
        int fn2argToks[] = { ARG2FNS };
        NSNumber *fn2argsArr[ARG2CNT];
        int i;
        for (i=0;i<ARG2CNT;i++) {
            fn2argsArr[i] = @(fn2argToks[i]);
        }
        _fn2args = [[NSArray alloc] initWithArray:[NSArray arrayWithObjects:fn2argsArr count:ARG2CNT] copyItems:YES];
    }

    return _fn2args;
}

- (NSArray*) fnTimeOps {
    if (nil == _fnTimeOps) {
        int fnTimeOpToks[] = { TIMEFNS };
        NSNumber *fnTimeOpsArr[TIMECNT];
        int i;
        for (i=0;i<TIMECNT;i++) {
            fnTimeOpsArr[i] = @(fnTimeOpToks[i]);
        }
        _fnTimeOps = [[NSArray alloc] initWithArray:[NSArray arrayWithObjects:fnTimeOpsArr count:TIMECNT] copyItems:YES];
    }
    return _fnTimeOps;
}


// map from token, vid to str

- (NSDictionary*) fnStrDict {
    if (nil == _fnStrDict) {
        int fnTokArr[] = { PARENFNS, OTHERFNS };
        NSString *fnStrArr[] = { ARG1STRS, ARG2STRS, TIMESTRS, PARENSTRS, OTHERSTRS };
        NSNumber *fnTokNSNarr[TOTFNCNT];
        
        int i,j=0;
        for (i=0; i< ARG1CNT; i++) {
            fnTokNSNarr[j++] = (self.fn1args)[i];
        }
        for (i=0; i< ARG2CNT; i++) {
            fnTokNSNarr[j++] = (self.fn2args)[i];
        }
        for (i=0; i< TIMECNT; i++) {
            fnTokNSNarr[j++] = (self.fnTimeOps)[i];
        }
        for (i=0; i< (PARENCNT+OTHERCNT); i++) {
            fnTokNSNarr[j++] = @(fnTokArr[i]);
        }
        //fnStrDict = [NSDictionary dictionaryWithObjects:fnStrArr forKeys:fnTokNSNarr count:TOTFNCNT];
        _fnStrDict = [[NSDictionary alloc] initWithObjects:fnStrArr forKeys:fnTokNSNarr count:TOTFNCNT];
    }
    return _fnStrDict;
}

/*
- (NSMutableArray*) fnStrs {
    
    // don't actually use vo.valuename entries
	if (fnStrs == nil) {
		fnStrs = [[NSMutableArray alloc] initWithObjects:FnArrStrs,nil];
		for (valueObj* valo in MyTracker.valObjTable) {
			[fnStrs addObject:valo.valueName];
		}
	}
	return fnStrs;
}
*/

- (NSArray*)votWoSelf {
    if (nil == _votWoSelf) {
        //if (0 > self.vo.vid) {  // temporary vo waiting for save so not included in tracker's vo table
        //  -> no, could be editinging an already existing entry
        //    votWoSelf = [NSArray arrayWithArray:MyTracker.valObjTable];
        //} else {

            NSMutableArray *tvot = [NSMutableArray arrayWithCapacity:[MyTracker.valObjTable count]];
            for (valueObj *tvo in MyTracker.valObjTable) {
                if (tvo.vid != self.vo.vid) {
                    [tvot addObject:tvo];
                }
            }
            //votWoSelf = [NSArray arrayWithArray:tvot];
            _votWoSelf = [[NSArray alloc] initWithArray:tvot];
            // not needed? [tvot release];
        //}
/*
        DBGLog(@"instantiate votWoSelf:");
        DBGLog(@"self.vo vid=%d  name= %@",self.vo.vid,self.vo.valueName);
        for (valueObj *mvo in votWoSelf) {
            DBGLog(@"  %d: %@",mvo.vid,mvo.valueName);
        }
        DBGLog(@".");
*/
    }
    return _votWoSelf;
}

#pragma mark -
#pragma mark protocol: voDisplay value 

- (NSString*) qdate:(NSInteger)d {
	return [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)d] 
										  dateStyle:NSDateFormatterShortStyle 
										  timeStyle:NSDateFormatterShortStyle];
}


- (NSInteger) getEpDate:(int)ndx maxdate:(NSInteger)maxdate {
	NSString *key = [NSString stringWithFormat:@"frep%d",ndx];
	NSNumber *nep = (self.vo.optDict)[key];
	NSInteger ep = [nep integerValue];
	NSInteger epDate;
	trackerObj *to = MyTracker;
    NSString *sql;

	if (nep == nil || ep == FREPENTRY) {  // also FREPDFLT  -- no value specified
		// use last entry
        sql = [NSString stringWithFormat:@"select date from trkrData where date < %ld order by date desc limit 1;",(long)maxdate];
		epDate = [to toQry2Int:sql];
		//DBGLog(@"ep %d ->entry: %@", ndx, [self qdate:epDate] );
    } else if (ep >= 0) {
		// ep is vid
        sql = [NSString stringWithFormat:@"select date from voData where id=%ld and date < %ld and val <> 0 and val <> '' order by date desc limit 1;",(long)ep,(long)maxdate]; // add val<>0,<>"" 5.vii.12
#if FUNCTIONDBG
        DBGLog(@"get ep qry: %@",sql);
#endif
		epDate = [to toQry2Int:sql];
#if FUNCTIONDBG
		DBGLog(@"ep %d ->vo %@: %@", ndx, self.vo.valueName, [self qdate:epDate] );
#endif
	} else {
		// ep is (offset * -1)+1 into epTitles, with optDict:frv0 multiplier

		NSString *vkey = [NSString stringWithFormat:@"frv%d",ndx];
		NSInteger ival = [(self.vo.optDict)[vkey] integerValue] * ( ndx ? 1 : -1 ) ; // negative offset if ep0
		NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        [gregorian setLocale:[NSLocale currentLocale]];
		NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
        
		//NSString *vt=nil;
		
		switch (ep) {
            case FREPNONE :
                // no previous endpoint - find nothing prior to now
                break;
			case FREPHOURS :
				[offsetComponents setHour:ival];
				//vt = @"hours";
				break;
			case FREPCDAYS :
                ival += (ndx ? 0 : 1);   // for -1 calendar day, we want offset -0 day and normalize to previous midnight below
			case FREPDAYS :
				[offsetComponents setDay:ival];
				//vt = @"days";
				break;
			case FREPCWEEKS :
                ival += (ndx ? 0 : 1);
            case FREPWEEKS :
                [offsetComponents setWeekOfYear:ival];
				//vt = @"weeks";
				break;
			case FREPCMONTHS :
                ival += (ndx ? 0 : 1);
			case FREPMONTHS :
				[offsetComponents setMonth:ival];
				//vt = @"months";
				break;
			case FREPCYEARS :
                ival += (ndx ? 0 : 1);
			case FREPYEARS :
				//vt = @"years";
				[offsetComponents setYear:ival];
				break;
			default:
				dbgNSAssert1(0,@"getEpDate: failed to identify ep %ld",(long)ep);
				break;
		}
	
        NSDate *targ = [gregorian dateByAddingComponents:offsetComponents
                                                  toDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)maxdate]
                                                 options:0];
        
        unsigned unitFlags = 0;
        
		switch (ep) {
                // if calendar week, we need to get to beginning of week as per calendar
			case FREPCWEEKS :
            {
                DBGLog(@"first day of week= %lu targ= %@",(unsigned long)[gregorian firstWeekday],targ);
                NSDate *beginOfWeek=nil;
                /*
                 // ios8 deprecation of NSWeekCalendarUnit -- WeekOfMonth and WeekOfYear below give same result; NSCalendarUnitWeekday does not respect locale preferences
                 // note dbg messages time given in GMT but we fall through cases below and wipe the time component
                 // so we need to get the begin of week date utc time 00:00:00 to be the date in the local time zone
                 BOOL rslt = [gregorian rangeOfUnit:NSWeekCalendarUnit startDate:&beginOfWeek interval:NULL forDate: targ];
                 DBGLog(@"NSWeekCalendarUnit (iOS7) %d %@ ",rslt,beginOfWeek);
                 rslt = [gregorian rangeOfUnit:NSCalendarUnitWeekOfMonth startDate:&beginOfWeek interval:NULL forDate: targ];
                 DBGLog(@"NSCalendarUnitWeekOfMonth (iOS8) %d %@ ",rslt,beginOfWeek);
                 rslt = [gregorian rangeOfUnit:NSCalendarUnitWeekday startDate:&beginOfWeek interval:NULL forDate: targ];
                 DBGLog(@"NSCalendarUnitWeekday (iOS8) %d %@ %",rslt,beginOfWeek);
                 */
                
                BOOL rslt = [gregorian rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&beginOfWeek interval:NULL forDate: targ];
                
                DBGLog(@"NSCalendarUnitWeekOfYear (iOS8) %d %@",rslt,beginOfWeek);
                
                if (rslt) {
                    // need to shift date with 00:00:00 UTC ( = 21:00 day before in tz ) to local timezone so day component is correct 
                    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
                    targ = [beginOfWeek dateByAddingTimeInterval:[tz secondsFromGMTForDate:beginOfWeek]];
                    // DBGLog(@"targ= %@",targ);
                }
            }
                // if any of week, day, month, year we need to wipe hour, minute, second components
			case FREPCDAYS :
                unitFlags |= NSCalendarUnitDay;
			case FREPCMONTHS :
                unitFlags |= NSCalendarUnitMonth;
			case FREPCYEARS :
                unitFlags |= NSCalendarUnitYear;
                NSDateComponents *components = [gregorian components:unitFlags fromDate:targ];
                targ = [gregorian dateFromComponents:components];
                break;
                
        }
        
        
		epDate = [targ timeIntervalSince1970];
#if FUNCTIONDBG
        DBGLog(@"ep %d ->offset %ld: %@", ndx, (long)ival, [self qdate:epDate] );
#endif
	}
   //sql = nil;

	return epDate;
}

- (NSNumber *) calcFunctionValue:(NSArray*)datePair {  // TODO: finish this -- not used
	if (datePair == nil) return nil;
    NSString *sql;
    
	int epd0 = [datePair[0] intValue];
	int epd1 = [datePair[1] intValue];

	NSInteger maxc = [self.fnArray count];
	NSInteger vid;
	trackerObj *to = MyTracker;
	
	double result = 0.0f;
	double v0 = 0.0f;
	double v1 = 0.0f;
	
	while (self.currFnNdx < maxc) {
		NSInteger currTok = [(self.fnArray)[self.currFnNdx] integerValue];
		if (isFn1Arg(currTok)) {
			self.currFnNdx++;
			vid = [(self.fnArray)[self.currFnNdx] integerValue];
			switch (currTok) {
				case FN1ARGDELTA :
					if (epd1 == 0) {
						v1 = [[to getValObj:vid].value doubleValue];
					} else {	
					sql = [NSString stringWithFormat:@"select val from voData where vid=%ld and date=%d;",(long)vid,epd1];
						v1 = [to toQry2Double:sql];
					}
                    sql = [NSString stringWithFormat:@"select val from voData where vid=%ld and date=%d;",(long)vid,epd0];
					v0 = [to toQry2Double:sql];
					result = v1 - v0;
					break;
				case FN1ARGAVG :
					if (epd1 == 0) {
						v1 = [[to getValObj:vid].value doubleValue];
                        sql = [NSString stringWithFormat:@"select avg(val) from voData where vid=%ld and date >=%d;",(long)vid,epd0];
                        result = [to toQry2Float:sql] + v1;
					} else {
					sql = [NSString stringWithFormat:@"select avg(val) from voData where vid=%ld and date >=%d and date <=%d;",(long)vid,epd0,epd1];
                        result = [to toQry2Float:sql];
					}
					break;
				default:
					switch (currTok) {
						case FN1ARGSUM :
						case FN1ARGPOSTSUM :
						case FN1ARGPRESUM :
							break;
							//  Not finished!
					}
			}
				
		}
	}
	
	
	return @(result);
	
}

// supplied with previous endpoint (endpoint 0), calculate function to current tracker
- (NSNumber *) calcFunctionValueWithCurrent:(NSInteger)epd0 {
	
	NSInteger maxc = [self.fnArray count];
	NSInteger vid=0;
    trackerObj *to = (trackerObj*) self.vo.parentTracker;  // MyTracker;
    NSString *sql;

    FnErr=NO;
    
#if FUNCTIONDBG
    // print our complete function
	NSInteger i;
    NSString *outstr=@"";
    for (i=0; i< maxc; i++) {
        outstr = [outstr stringByAppendingFormat:@" %@",[self.fnArray objectAtIndex:i]];
    }
    DBGLog(@"%@ calcFnValueWithCurrent fnArray= %@ ", self.vo.valueName, outstr);
#endif    
    
	int epd1;
	if (to.trackerDate == nil) {
        // current tracker entry no date set so epd1=now
		epd1 = (int) [[NSDate date] timeIntervalSince1970];
	} else {
        // set epd1 to date of current (this) tracker entry
		epd1 = (int) [to.trackerDate timeIntervalSince1970];
	}
	
	double result = 0.0f;
	
    while (self.currFnNdx < maxc) {
        // recursive function, self.currFnNdx holds our current processing position
		NSInteger currTok = [(self.fnArray)[self.currFnNdx++] integerValue];
		if (isFn1Arg(currTok)) {
            // currTok is function taking 1 argument, so get it
            if (self.currFnNdx >= maxc) {  // <--- added from line 462
                //DBGErr(@"1-arg fn missing arg: %@",self.fnArray);
                FnErr=YES;
                return @(result);  // crashlytics report past array bounds at next line, so at least return without crashing
            }
            vid = [(self.fnArray)[self.currFnNdx++] integerValue];  // get fn arg, can only be valobj vid
            //valueObj *valo = [to getValObj:vid];
            NSString *sv1 = [to getValObj:vid].value;
            BOOL nullV1 = (nil == sv1 || [@"" isEqualToString:sv1]);
            double v1 = [sv1 doubleValue];
            sql= [NSString stringWithFormat:@"select count(val) from voData where id=%ld and date >=%ld and date <%d;",(long)vid,(long)epd0,epd1];
            int ci= [to toQry2Int:sql];
#if FUNCTIONDBG
            DBGLog(@"v1= %f nullV1=%d vid=%ld %@:%@", v1,
                   nullV1,
                   (long)vid,
                   ((trackerObj*)self.vo.parentTracker).trackerName ,self.vo.valueName);
#endif
            // v1 is value for current tracker entry (epd1) for our arg
            switch (currTok) {  // all these 'date < epd1' because we will add in curr v1 and need to exclude if stored in db
                                // changed to date > epd1 for consistency with other functions
                case FN1ARGDELTA :
                case FN1ARGONRATIO:
                case FN1ARGNORATIO:
                case FN1ARGELAPSEDWEEKS:
                case FN1ARGELAPSEDDAYS:
                case FN1ARGELAPSEDHOURS:
                case FN1ARGELAPSEDMINS:
                case FN1ARGELAPSEDSECS:
                    if (nullV1)
                        return nil;  // delta requires v1 to subtract from, sums and avg just get one less result
                    // epd1 value is ok, get from db value for epd0
                    //to.sql = [NSString stringWithFormat:@"select val from voData where id=%d and date=%d;",vid,epd0];
                    // with per calendar date calcs, epd0 may not match a datapoint
                    // - so get val coming into this time segment or skip for beginning - rtm 17.iii.13
                   sql= [NSString stringWithFormat:@"select count(val) from voData where id=%ld and date>=%ld;",(long)vid,(long)epd0];
                    ci= [to toQry2Int:sql]; // slightly different for delta
                    if (0 == ci)
                        return nil; // skip for beginning
                    
                    if (isFn1ArgElapsed(currTok)) {
                        sql = [NSString stringWithFormat:@"select date from voData where id=%ld and date>=%ld order by date asc limit 1;",(long)vid,(long)epd0];
                        int d0 = [to toQry2Int:sql];
                        result = (double) epd1 - d0;
                        DBGLog(@"elapsed unit: epd0= %ld d0= %d epd1=%d rslt= %lf",(long)epd0,d0,epd1,result);
                        switch (currTok) {
                            case FN1ARGELAPSEDWEEKS:
                                result /= d(7);
                            case FN1ARGELAPSEDDAYS:
                                result /= d(24);
                            case FN1ARGELAPSEDHOURS:
                                result /= d(60);
                            case FN1ARGELAPSEDMINS:
                                result /= d(60);
                            case FN1ARGELAPSEDSECS:
                            default:
                                break;
                        }
                        DBGLog(@"elapsed unit: final result = %lf",result);
                        break;
                    }
                    
                   sql = [NSString stringWithFormat:@"select val from voData where id=%ld and date>=%ld order by date asc limit 1;",(long)vid,(long)epd0]; // desc->asc 22.ii.2016 to match <= -> >= change 25.01.16
                    
                    double v0 = [to toQry2Double:sql];
#if FUNCTIONDBG
                    DBGLog(@"delta/on_ratio/no_ratio: v0= %f", v0);
#endif
                    // do caclulation
                    switch (currTok) {
                        case FN1ARGDELTA :
                            result = v1 - v0;
                            break;
                        case FN1ARGONRATIO:
                            if (0 == v1) return nil;
                            result = v0/v1;
                            break;
                        case FN1ARGNORATIO:
                            if (0 == v0) return nil;
                            result = v1/v0;
                            break;
                    }
                    break;
                case FN1ARGAVG :
                {
                    // below (calculate via sqlite) works but need to include any current but unsaved value
                    //to.sql = [NSString stringWithFormat:@"select avg(val) from voData where id=%d and date >=%d and date <%d;",
                    //		  vid,epd0,epd1];
                    //result = [to toQry2Float:sql];  // --> + v1;
                    
                    double c = [(self.vo.optDict)[@"frv0"] doubleValue];  // if ep has assoc value, then avg is over that num with date/time range already determined
                    // in other words, is it avg over 'frv' number of hours/days/weeks then that is our denominator
                    if (c == 0.0f) {  // else denom is number of entries between epd0 to epd1 
                       sql = [NSString stringWithFormat:@"select count(val) from voData where id=%ld and val <> '' and date >=%ld and date <%d;",
                                  (long)vid,(long)epd0,epd1];
                        c = [to toQry2Float:sql] + (nullV1 ? 0.0f : 1.0f);  // +1 for current on screen
                    }
                    
                    if (c == 0.0f) {
                        return nil;
                    }
                   sql = [NSString stringWithFormat:@"select sum(val) from voData where id=%ld and date >=%ld and date <%d;",
                              (long)vid,(long)epd0,epd1];
                    double v =  [to toQry2Float:sql];
                    result = (v + v1) / c ;
#if FUNCTIONDBG
                    DBGLog(@"avg: v= %f v1= %f (v+v1)= %f c= %f rslt= %f ",v,v1,(v+v1),c,result);
#endif
                    break;
                }
               case FN1ARGMIN :
                {
                    if (0 == ci && nullV1) {
                        return nil;
                    } else if (0 == ci) {
                        result = v1;
                    } else {
                       sql = [NSString stringWithFormat:@"select min(val) from voData where id=%ld and date >=%ld and date <%d;",
                              (long)vid,(long)epd0,epd1];
                        result = [to toQry2Float:sql];
                        if (!nullV1 && v1 < result) {
                            result = v1;
                        
                        }
                    }
#if FUNCTIONDBG
                    DBGLog(@"min: result= %f", result);
#endif
                    break;
                }
                case FN1ARGMAX :
                {
                    if (0 == ci && nullV1) {
                        return nil;
                    } else if (0 == ci) {
                        result = v1;
                    } else {
                       sql = [NSString stringWithFormat:@"select max(val) from voData where id=%ld and date >=%ld and date <%d;",
                              (long)vid,(long)epd0,epd1];
                        result = [to toQry2Float:sql];
                        if (!nullV1 && v1>result) {
                            result = v1;
                        }
                    }
#if FUNCTIONDBG
                    DBGLog(@"max: result= %f", result);
#endif
                    break;
                }
                case FN1ARGCOUNT :
                {
                   sql = [NSString stringWithFormat:@"select count(val) from voData where id=%ld and date >=%ld and date <%d;",
                              (long)vid,(long)epd0,epd1];
                    result = [to toQry2Float:sql];
                    if (!nullV1) {
                        result += 1.0f;
                    }
#if FUNCTIONDBG
                    DBGLog(@"count: result= %f", result);
#endif
                    break;
                }
                default:
                    // remaining options for fn w/ 1 arg are pre/post/all sum
                    switch (currTok) {
                            // by selecting for not null ep0 using total() these sum over intermediate non-endpoint values
                            // -- ignoring passed epd0
                        case FN1ARGPRESUM :
                            // we conditionally add in v1=(date<=%d) below so presum sql query same as sum
                            
                            //to.sql = [NSString stringWithFormat:@"select total(val) from voData where id=%d and date >=%d and date <%d;",
                            //		  vid,epd0,epd1];
                            //break;
#if FUNCTIONDBG
                            DBGLog(@"presum: fall through");
#endif
                        case FN1ARGSUM :
                            // (date<%d) because add in v1 below
                           sql = [NSString stringWithFormat:@"select total(val) from voData where id=%ld and date >=%ld and date <%d;",
                                      (long)vid,(long)epd0,epd1];
#if FUNCTIONDBG
                            DBGLog(@"sum: set sql");
#endif
                            break;
                        case FN1ARGPOSTSUM :
                            // (date<%d) because add in v1 below
                            // 24.ii.2016 below does not really work, was created when start date was exact match to one to skip -- but with e.g. 'current-3 weeks' need to skip earliest value
                            sql = [NSString stringWithFormat:@"select total(val) from voData where id=%ld and date >%ld and date <%d;",(long)vid,(long)epd0,epd1];
                            
                            /*
                             // except
                            sql = [NSString stringWithFormat:@"select date from voData where id=%ld and date >=%ld and date <%d limit 1;",(long)vid,(long)epd0,epd1];
                            int firstDate = [to toQry2Int:sql];
                            if (firstDate) {
                                sql = [NSString stringWithFormat:@"select total(val) from voData where id=%ld and date >%d and date <%d;",(long)vid,firstDate,epd1];
                            } else {
                                sql = @"select 0";
                            }
                             */
#if FUNCTIONDBG
                            DBGLog(@"postsum: set sql");
#endif
                            break;
                    }
                    result = [to toQry2Float:sql];
                    if (currTok != FN1ARGPRESUM)
                        result += v1;
#if FUNCTIONDBG
                    DBGLog(@"pre/post/sum: result= %f", result);
#endif
                    break;
            }
		} else if (isFn2ArgOp(currTok)) {
            // we are processing some combo of previous result and next value, currFnNdx was ++ already so get that result:
			NSNumber *nrnum = [self calcFunctionValueWithCurrent:epd0]; // currFnNdx now at next place already
            if (nil == nrnum) {
                return nil;
            }
			double nextResult = [nrnum doubleValue];
			switch (currTok) {
                    // now just combine with what we have so far
				case FN2ARGPLUS :
					result += nextResult;
#if FUNCTIONDBG
                    DBGLog(@"plus: result= %f", result);
#endif
					break;
				case FN2ARGMINUS :
					result -= nextResult;
#if FUNCTIONDBG
                    DBGLog(@"minus: result= %f", result);
#endif
					break;
				case FN2ARGTIMES :
					result *= nextResult;
#if FUNCTIONDBG
                    DBGLog(@"times: result= %f", result);
#endif
					break;
				case FN2ARGDIVIDE :
					if (nrnum != nil && nextResult != 0.0f) {
						result /= nextResult;
#if FUNCTIONDBG
                        DBGLog(@"divide: result= %f", result);
#endif
					} else {
						//result = nil;
#if FUNCTIONDBG
                        DBGLog(@"divide: rdivide by zero!");
#endif
						return nil;
					}
					break;
			} 
		} else if (currTok == FNPARENOPEN) {
            // open paren means just recurse and return the result up
			NSNumber *nrnum = [self calcFunctionValueWithCurrent:epd0]; // currFnNdx now at next place already
            if (nil == nrnum) {
                return nil;
            }
			result = [nrnum doubleValue];
#if FUNCTIONDBG
            DBGLog(@"paren open: result= %f", result);
#endif
		} else if (currTok == FNPARENCLOSE) {
            // close paren means we are there, return what we have
#if FUNCTIONDBG
            DBGLog(@"paren close: result= %f", result);
#endif
			return @(result);
        } else if (FNCONSTANT == currTok) {
                if (self.currFnNdx >= maxc) {
                    //DBGErr(@"constant fn missing arg: %@",self.fnArray);
                    FnErr=YES;
                    return @(result);  // crashlytics report past array bounds above (1-arg) processing function, so safety check here to return without crashing
                }
                result = [(self.fnArray)[self.currFnNdx++] doubleValue];
                self.currFnNdx++;  // skip the bounding constant tok
#if FUNCTIONDBG
            DBGLog(@"constant: result= %f", result);
#endif
        } else if (isFnTimeOp(currTok)) {
            if (0 == epd0) {
#if FUNCTIONDBG
                DBGLog(@" timefn: at beginning");
#endif
                return nil;
            }
            
            result = (double) epd1 - epd0;
#if FUNCTIONDBG
            DBGLog(@" timefn: %f secs",result);
#endif
            switch (currTok) {
                case FNTIMEWEEKS:
                    result /= 7;            // 7 days /week
#if FUNCTIONDBG
                    DBGLog(@" timefn: weeks : %f ",result);
#endif
                case FNTIMEDAYS :
                    result /= 24;            // 24 hrs / day 
#if FUNCTIONDBG
                    DBGLog(@" timefn: days %f ",result);
#endif
                case FNTIMEHRS :
                    result /= 60;           // 60 mins / hr
#if FUNCTIONDBG
                    DBGLog(@" timefn: hrs %f ",result);
#endif
                case FNTIMEMINS :
                    result /= 60;           // 60 secs / min
#if FUNCTIONDBG
                    DBGLog(@" timefn: mins %f ",result);
#endif
                case FNTIMESECS :
#if FUNCTIONDBG
                    DBGLog(@" timefn: secs %f ",result);
#endif
                default:
                    //result /= d( 60 * 60 );  // 60 secs min * 60 secs hr
                    break;
            }
#if FUNCTIONDBG
            DBGLog(@" timefn: %f final units",result);
#endif
		} else {
            // remaining option is we have some vid as currTok, return its value up the chain
            valueObj *lvo = [to getValObj:currTok];
            result = [lvo.value doubleValue];
#if FUNCTIONDBG
            DBGLog(@"vid %ld: result= %f", (long)lvo.vid,result);
#endif
            //result = [[to getValObj:currTok].value doubleValue];
			//self.currFnNdx++;  // on to next  // already there - postinc on read
		}
	}

#if FUNCTIONDBG
    DBGLog(@"%@ calcFnValueWithCurrent rtn: %@", self.vo.valueName, [NSNumber numberWithDouble:result]);
#endif
    return @(result);

}

- (BOOL) checkEP:(int)ep {
    NSString *epstr = [NSString stringWithFormat:@"frep%d", ep];
    NSInteger epval = [[self.vo.optDict valueForKey:epstr] integerValue];
	if (epval >= 0) {  // if epval is a valueObj
		valueObj *valo = [MyTracker getValObj:epval];
		if ( valo == nil
			|| valo.value == nil
			|| [valo.value isEqualToString:@""] 
			|| (valo.vtype == VOT_BOOLEAN && (![valo.value isEqualToString:@"1"])  )
            )
            return FALSE;
    }
    return TRUE;
}

//- (NSString*) currFunctionValue {
- (NSString*) update:(NSString*)instr {
    instr = @"";
    trackerObj *pto = self.vo.parentTracker;

    if (nil == pto.tDb)   // not set up yet
        return @"";
    
    if (![self checkEP:1])  // current = final endpoint not ok
        return instr;
    

    // search back for start endpoint that is ok
    NSInteger ep0start = [MyTracker.trackerDate timeIntervalSince1970];
	NSInteger ep0date = [self getEpDate:0 maxdate:ep0start];  // start with immed prev to curr record set
/*
    if (ep0date != 0) {
        [MyTracker loadData:ep0date];   // set values for initial checkEP test
        while((ep0date != 0) && (![self checkEP:0])) {
            ep0date = [self getEpDate:0 maxdate:ep0date];  // not ok, back one more
            [MyTracker loadData:ep0date];
        }
        [MyTracker loadData:ep0start];   // reset from search
    }
  */
    
	if (ep0date == 0)  {// start endpoint not ok
        NSNumber *nep = (self.vo.optDict)[@"frep0"];
        NSInteger ep = [nep integerValue];
        if (! (nep == nil || ep == FREPENTRY) ) {  // allow to go through if just looking for previous entry and this is first
            return instr;
        }
    }
    
	self.currFnNdx=0;
	
	NSNumber *val = [self calcFunctionValueWithCurrent:ep0date];
#if FUNCTIONDBG
    DBGLog(@"fn update val= %@",val);
#endif
    if (val != nil) {
        NSNumber *nddp = (self.vo.optDict)[@"fnddp"];
        int ddp = ( nddp == nil ? FDDPDFLT : [nddp intValue] );
        return [NSString stringWithFormat:[NSString stringWithFormat:@"%%0.%df",ddp],[val floatValue]];
    }
#if FUNCTIONDBG
    DBGLog(@"fn update returning: %@",instr);
#endif
    return instr;
}

- (UILabel*) rlab {
    if (_rlab && _rlab.frame.size.width != self.vosFrame.size.width) _rlab = nil;
    
    if (nil == _rlab) {
        _rlab = [[UILabel alloc] initWithFrame:self.vosFrame];
        _rlab.textAlignment = NSTextAlignmentRight; // ios6 UITextAlignmentRight;
        _rlab.font = PrefBodyFont;
    }
    return _rlab;
}
- (UIView*) voDisplay:(CGRect)bounds {
		
	//trackerObj *to = (trackerObj*) parentTracker;
	self.vosFrame = bounds;
    
	//UILabel *rlab = [[UILabel alloc] initWithFrame:bounds];
	//rlab.textAlignment = UITextAlignmentRight;

#if FABRIC
    [CrashlyticsKit setObjectValue:[self voFnDefnStr:TRUE] forKey:@"fnDefn"];
    [CrashlyticsKit setObjectValue:[self voRangeStr:TRUE] forKey:@"fnRange"];
#endif
    
	NSString *valstr = self.vo.value;  // evaluated on read so make copy
    if (FnErr) valstr = [@"❌ " stringByAppendingString:valstr];
	if (![valstr isEqualToString:@""]) {
		self.rlab.backgroundColor = [UIColor clearColor];  // was whiteColor
        self.rlab.text = valstr;
	} else {
		self.rlab.backgroundColor = [UIColor lightGrayColor];
		self.rlab.text = @"-";
	}
	
	//return [rlab autorelease];
    DBGLog(@"fn voDisplay: %@", self.rlab.text);
    //self.rlab.tag = kViewTag;
    return self.rlab;
}

- (NSArray*) voGraphSet {
	return [voState voGraphSetNum];
}

#pragma mark -
#pragma mark function configTVObjVC 
#pragma mark -

#pragma mark range definition page 

//
// convert endpoint from left or right picker to rownum for offset symbol (hours, months, ...) or valobj
//

// ep options are : 
//     row 0:      entry 
//     rows 1..m:  [valObjs] (ep = vid)
//     rows n...:  other epTitles entries

- (NSInteger) epToRow:(NSInteger)component {
	NSString *key = [NSString stringWithFormat:@"frep%ld",(long)component];
	NSNumber *n = (self.vo.optDict)[key];
	NSInteger ep = [n integerValue];
    DBGLog(@"comp= %ld ep= %ld n= %@ ",(long)component,(long)ep,n);
	if (n == nil || ep == FREPDFLT) {// no endpoint defined, so default row 0
        DBGLog(@" returning 0");
		return 0;
    }
	if (ep >= 0  || ep <= -TMPUNIQSTART)  {// ep defined and saved, or ep not saved and has tmp vid, so return ndx in vo table
		//return [MyTracker.valObjTable indexOfObjectIdenticalTo:[MyTracker getValObj:ep]] +1;
        DBGLog(@" returning %lu",(unsigned long)([self.votWoSelf indexOfObjectIdenticalTo:[MyTracker getValObj:ep]] +1));
        return [self.votWoSelf indexOfObjectIdenticalTo:[MyTracker getValObj:ep]] +1;
		//return ep+1;
	}
    DBGLog(@" returning %lu",(unsigned long) ((ep * -1) + [self.votWoSelf count] -1));
	return (ep * -1) + [self.votWoSelf count] -1;  // ep is offset into hours, months list
    //return (ep * -1) + [MyTracker.valObjTable count] -1;  // ep is offset into hours, months list
}

- (NSString *) fnrRowTitle:(NSInteger)row {
	if (row != 0) {
		NSInteger votc = [self.votWoSelf count];   //[MyTracker.valObjTable count];
		if (row <= votc) {
            DBGLog(@" returning %@",((valueObj*) [self.votWoSelf objectAtIndex:row-1]).valueName);
			return ((valueObj*) (self.votWoSelf)[row-1]).valueName;  //((valueObj*) [MyTracker.valObjTable objectAtIndex:row-1]).valueName;
		} else {
			row -= votc;
		}
	}
    DBGLog(@" returning %@",[self.epTitles objectAtIndex:row]);
	return (self.epTitles)[row];
}

// 
// if picker row is offset (not valobj), display a textfield and label to get number of (hours, months,...) offset
// check 
//

- (void) updateValTF:(NSInteger)row component:(NSInteger)component {
	NSInteger votc = [self.votWoSelf count];   //[MyTracker.valObjTable count];
	
	if (row > votc) {
		NSString *vkey = [NSString stringWithFormat:@"frv%ld",(long)component];
		NSString *key = [NSString stringWithFormat:@"frep%ld",(long)component];
        if (FREPNONE == [(self.vo.optDict)[key] integerValue])
            return;
		NSString *vtfkey = [NSString stringWithFormat:@"fr%ldTF",(long)component];
		NSString *pre_vkey = [NSString stringWithFormat:@"frpre%ldvLab",(long)component];
		NSString *post_vkey = [NSString stringWithFormat:@"frpost%ldvLab",(long)component];
		
		UITextField *vtf= (self.ctvovcp.wDict)[vtfkey];
		vtf.text = (self.vo.optDict)[vkey];
		[self.ctvovcp.scroll addSubview:vtf];
		[self.ctvovcp.scroll addSubview:(self.ctvovcp.wDict)[pre_vkey]];
        UILabel *postLab = (self.ctvovcp.wDict)[post_vkey];
		//postLab.text = [[self fnrRowTitle:row] stringByReplacingOccurrencesOfString:@"cal " withString:@"c "];
		postLab.text = [self fnrRowTitle:row];
        DBGLog(@" postlab= %@",postLab.text);
        [self.ctvovcp.scroll addSubview:postLab];
        
        if ((0 == component) && (ISCALFREP([(self.vo.optDict)[key] integerValue]))) {
            UIButton *ckBtn = (self.ctvovcp.wDict)[@"graphLastBtn"];
            BOOL state = (![(self.vo.optDict)[@"graphlast"] isEqualToString:@"0"]) ; // default:1
            [ckBtn setImage:[UIImage imageNamed:(state ? @"checked.png" : @"unchecked.png")]
                         forState: UIControlStateNormal];
            [self.ctvovcp.scroll addSubview:ckBtn];
            UILabel *glLab = (self.ctvovcp.wDict)[@"graphLastLabel"];
            [self.ctvovcp.scroll addSubview:glLab];
        }
        
	}
}

- (void) drawFuncOptsRange {
	CGRect frame = {MARGIN,self.ctvovcp.lasty,0.0,0.0};
	
	CGRect labframe = [self.ctvovcp configLabel:@"Function range endpoints:" 
								  frame:frame
									key:@"freLab" 
								  addsv:YES ];
	frame.origin.x = MARGIN;
	frame.origin.y += labframe.size.height + MARGIN;
	
	/*labframe =*/ [self.ctvovcp configLabel:@"Previous:"
							   frame:frame
								 key:@"frpLab" 
							   addsv:YES ];
	frame.origin.x = (self.ctvovcp.view.frame.size.width / 2.0) + MARGIN;
	
	labframe = [self.ctvovcp configLabel:@"Current:"
						   frame:frame
							 key:@"frcLab" 
						   addsv:YES ];
	
	frame.origin.y += labframe.size.height + MARGIN;
	frame.origin.x = 0.0;
	
	frame = [self.ctvovcp configPicker:frame key:@"frPkr" caller:self];
	UIPickerView *pkr = (self.ctvovcp.wDict)[@"frPkr"];
	
    DBGLog(@"pkr component 0 selectRow %ld",(long)[self epToRow:0]);
	[pkr selectRow:[self epToRow:0] inComponent:0 animated:NO];
    DBGLog(@"pkr component 1 selectRow %ld",(long)[self epToRow:1]);
	[pkr selectRow:[self epToRow:1] inComponent:1 animated:NO];
	
	frame.origin.y += frame.size.height + MARGIN;
	frame.origin.x = MARGIN;
	
	labframe = [self.ctvovcp configLabel:@"-" 
						   frame:frame
							 key:@"frpre0vLab" 
						   addsv:NO ];
	
	frame.origin.x += labframe.size.width + SPACE;
    CGFloat tfWidth = [@"9999" sizeWithAttributes:@{NSFontAttributeName:PrefBodyFont}].width;
	frame.size.width = tfWidth;
	frame.size.height = self.ctvovcp.LFHeight; 
	
	[self.ctvovcp configTextField:frame 
					  key:@"fr0TF" 
				   target:nil
				   action:nil
					  num:YES 
					place:nil
					 text:(self.vo.optDict)[@"frv0"] 
					addsv:NO ];
	
	frame.origin.x += tfWidth + 2*SPACE;
	/*labframe =*/ [self.ctvovcp configLabel:@"cal months" 
							   frame:frame
								 key:@"frpost0vLab" 
							   addsv:NO ];
	
	//[self updateValTF:[self epToRow:0] component:0];
	
	frame.origin.x = (self.ctvovcp.view.frame.size.width / 2.0) + MARGIN;
	
    labframe = [self.ctvovcp configLabel:@"only last:"
                                          frame:frame
                                            key:@"graphLastLabel"
                                          addsv:NO ];
    
    frame.origin.x += labframe.size.width + SPACE;
    [self.ctvovcp configCheckButton:frame
                                key:@"graphLastBtn"
                              state:(![(self.vo.optDict)[@"graphlast"] isEqualToString:@"0"])  // default:1
                              addsv:NO
     ];

    [self updateValTF:[self epToRow:0] component:0];

    /*
	labframe = [self.ctvovcp configLabel:@"+" 
						   frame:frame
							 key:@"frpre1vLab" 
						   addsv:NO ];
	
	frame.origin.x += labframe.size.width + SPACE;
	[self.ctvovcp configTextField:frame 
					  key:@"fr1TF" 
				   target:nil
				   action:nil
					  num:YES 
					place:nil
					 text:[self.vo.optDict objectForKey:@"frv1"] 
					addsv:NO ];
	
	frame.origin.x += tfWidth + 2*SPACE;
	/ *labframe =* / [self.ctvovcp configLabel:@"cal months"
							   frame:frame
								 key:@"frpost1vLab" 
							   addsv:NO ];
	[self updateValTF:[self epToRow:1] component:1];
	*/
	
}

#pragma mark -
#pragma mark function definition page 

//
// generate text to describe function as specified by symbols,vids in fnArray from 
//  strings in fnStrs or valueObj names
//

- (void) reloadEmptyFnArray {
    if (0==[self.fnArray count]) { // one last try if nothing there
        [self loadConfig];
    }
}

- (NSString*) voFnDefnStr:(BOOL)dbg {
	NSMutableString *fstr = [[NSMutableString alloc] init];
	BOOL closePending = NO;             //square brackets around target of Fn1Arg
	BOOL constantPending = NO;          // next item is a number not tok or vid
    BOOL constantClosePending = NO;     // constant bounded on both sides by constant token
    BOOL arg2Pending = NO;              // looking for second argument
    int openParenCount=0;
    
	for (NSNumber *n in self.fnArray) {
		NSInteger i = [n integerValue];
        //DBGLog(@"loop start: closePend=%d constantPend=%d constantClosePend=%d arg2Pend=%d openParen=%d fstr=%@",closePending,constantPending,constantClosePending,arg2Pending, openParenCount, fstr);
        if (constantPending) {
            [fstr appendString:[n stringValue]];
            constantPending = NO;
            constantClosePending = YES;
		} else if (isFn(i)) {
            if (isFn2ArgOp(i))
                arg2Pending = YES;
            else
                arg2Pending = NO;
            if (FNCONSTANT == i) {
                if (constantClosePending) {
                    constantClosePending = NO;
                } else {
                    constantPending = YES;
                }
            } else {
                //NSInteger ndx = (i * -1) -1;
                //[fstr appendString:[self.fnStrs objectAtIndex:ndx]];  xxx   // get str for token
                [fstr appendString:(self.fnStrDict)[@(i)]];
                if (isFn1Arg(i)) {
                    [fstr appendString:@"["];
                    closePending=YES;
                }
                if (FNPARENOPEN == i) openParenCount++;
                else if (FNPARENCLOSE == i) openParenCount--;
            }
		} else {
            if (dbg) {
                NSInteger vt = [MyTracker voGetTypeForVID:i];
                if (0 > vt) {
                    [fstr appendString:@"noType"];
                } else {
                    [fstr appendString:[rTracker_resource vtypeNames][vt]];
                }
            } else {
                [fstr appendString:[MyTracker voGetNameForVID:i]];  // could get from self.fnStrs
            }
			if (closePending) {
				[fstr appendString:@"]"];
				closePending=NO;
			}
            arg2Pending = NO;
		}
		if (! closePending)
            [fstr appendString:@" "];
        DBGLog(@"loop end: closeP=%d constantP=%d constantCloseP=%d arg2P=%d openPC=%d fstr=%@",closePending,constantPending,constantClosePending,arg2Pending, openParenCount, fstr);
    }
    if (arg2Pending || closePending || constantPending || constantClosePending || openParenCount) {
        [fstr appendString:@" ❌"];
        FnErr = YES;
    } else {
        FnErr = NO;
    }
    DBGLog(@"final fstr: %@",fstr);
	return fstr;
}


- (void) updateFnTV {
	UITextView *ftv = (self.ctvovcp.wDict)[@"fdefnTV2"];
    ftv.text = [self voFnDefnStr:FALSE];
}

- (void) btnAdd:(id)sender {
    if (0 >= [self.fnTitles count]) {
        [self noVarsAlert];
        return;
    }
    
	UIPickerView *pkr = (self.ctvovcp.wDict)[@"fdPkr"];
	NSInteger row = [pkr selectedRowInComponent:0];
	NSNumber *ntok = (self.fnTitles)[row];    // get tok from fnTitle and add to fnArray
	[self.fnArray addObject:ntok];
    if (FNCONSTANT == [ntok intValue]) {  // constant has const_tok on both sides to help removal
        UITextField *vtf= (self.ctvovcp.wDict)[CTFKEY];
        [self.fnArray addObject:@([vtf.text doubleValue])];
        [self.fnArray addObject:ntok];
        [self.ctvovcp tfDone:vtf];
    }
	[self updateFnTitles];
	[pkr reloadComponent:0];
	[self updateFnTV];
}

- (void) btnDelete:(id)sender {
    // i= constTok remove token and value  -- done
    //  also [self.tempValObj.optDict removeObjectForKey:@"fdc"]; -- can't be sure with mult consts
	UIPickerView *pkr = (self.ctvovcp.wDict)[@"fdPkr"];
	if (0 < [self.fnArray count]) {
        if (FNCONSTANT == [[self.fnArray lastObject] intValue]) {
            [self.fnArray removeLastObject];  // remove bounding token after
            [self.fnArray removeLastObject];  // remove constant value
        }
        [self.fnArray removeLastObject];
    }
	[self updateFnTitles];
	[pkr reloadComponent:0];
	[self updateFnTV];
}

- (void) drawFuncOptsDefinition {
	[self updateFnTitles];
	
	CGRect frame = {MARGIN,self.ctvovcp.lasty,0.0,0.0};
	
	CGRect labframe = [self.ctvovcp configLabel:@"Function definition:" 
								  frame:frame
									key:@"fdLab" 
								  addsv:YES ];
	
	frame.origin.x = MARGIN;
	frame.origin.y += MARGIN + labframe.size.height;
	frame.size.width = self.ctvovcp.view.frame.size.width - 2*MARGIN; // 300.0f;
	frame.size.height = 2* self.ctvovcp.LFHeight;

    CGFloat maxDim = [rTracker_resource getScreenMaxDim];
    if (maxDim > 480) {
        if (maxDim <= 568) {  // iphone 5
            frame.size.height = 4* self.ctvovcp.LFHeight;
        } else if (maxDim <= 736) { // iphone 6, 6+
            frame.size.height = 6* self.ctvovcp.LFHeight;
        } else {
            frame.size.height = 8* self.ctvovcp.LFHeight;
        }
    }
    [self.ctvovcp configTextView:frame key:@"fdefnTV2" text:[self voFnDefnStr:FALSE]];
	
	frame.origin.x = 0.0;
	frame.origin.y += frame.size.height + MARGIN;

	frame = [self.ctvovcp configPicker:frame key:@"fdPkr" caller:self];
	//UIPickerView *pkr = [self.ctvovcp.wDict objectForKey:@"fdPkr"];
	
	//[pkr selectRow:[self epToRow:0] inComponent:0 animated:NO];
	//[pkr selectRow:[self epToRow:1] inComponent:1 animated:NO];
	
    frame.origin.y += frame.size.height ;//+ MARGIN;
	//frame.origin.x = MARGIN;
	frame.size.height = labframe.size.height;
//
    frame.origin.x = [@"Add" sizeWithAttributes:@{NSFontAttributeName:PrefBodyFont}].width + 3*MARGIN;
    //frame.origin.y += frame.size.height + MARGIN;
    labframe = [self.ctvovcp configLabel:@"Constant value:" 
                                   frame:frame
                                     key:CLKEY 
                                   addsv:NO ];
    
	frame.origin.x += labframe.size.width + SPACE;
    CGFloat tfWidth = [@"9999.99" sizeWithAttributes:@{NSFontAttributeName:PrefBodyFont}].width;
	frame.size.width = tfWidth;
	frame.size.height = self.ctvovcp.LFHeight; 
	
	[self.ctvovcp configTextField:frame 
                              key:@"fdcTF" 
                           target:nil
                           action:nil
                              num:YES 
                            place:nil
                             text:nil 
                            addsv:NO ];
    
    frame.origin.x = MARGIN;
    frame.origin.y -= 3*MARGIN; // I DO NOT UNDERSTAND THIS!!!!!
    
    [self.ctvovcp configActionBtn:frame key:@"fdaBtn" label:@"Add" target:self action:@selector(btnAdd:)];
    frame.origin.x = -1.0f;
    [self.ctvovcp configActionBtn:frame key:@"fddBtn" label:@"Delete" target:self action:@selector(btnDelete:)];

}

#pragma mark -
#pragma mark function overview page 

//
// nice text string to describe a specified range endpoint
//

- (NSString*) voEpStr:(NSInteger)component dbg:(BOOL)dbg {
	NSString *key = [NSString stringWithFormat:@"frep%ld",(long)component];
	NSString *vkey = [NSString stringWithFormat:@"frv%ld",(long)component];
	NSString *pre = component ? @"current" : @"previous";
	
	NSNumber *n = (self.vo.optDict)[key];
	NSInteger ep = [n integerValue];
	NSUInteger ep2 = n ? (ep+1)*-1 : 0; // invalid if ep is tmpUniq (negative)
	
    if (nil == n || FREPDFLT == ep || FREPNONE == ep) // no endpoint defined, default is 'entry'
		return [NSString stringWithFormat:@"%@ %@", pre, (self.epTitles)[ep2]];  // FREPDFLT

    if (ep >= 0 || ep <= -TMPUNIQSTART )  { // endpoint is vid and valobj saved, or tmp vid as valobj not saved
        if (dbg) {
            return [NSString stringWithFormat:@"%@ %@", pre,[rTracker_resource vtypeNames][((valueObj*)[MyTracker getValObj:ep]).vtype]];
        } else {
            return [NSString stringWithFormat:@"%@ %@", pre, ((valueObj*)[MyTracker getValObj:ep]).valueName];
        }
    }
    
    // ep is hours / days / months entry
    return [NSString stringWithFormat:@"%@%d %@",
        (component ? @"+" : @"-"), [(self.vo.optDict)[vkey] intValue], (self.epTitles)[ep2]];
    
}

- (NSString*) voRangeStr:(BOOL)dbg {
    return [NSString stringWithFormat:@"%@ to %@", [self voEpStr:0 dbg:dbg], [self voEpStr:1 dbg:dbg]];
}

- (void) drawFuncOptsOverview {

    CGRect frame = {MARGIN,self.ctvovcp.lasty,0.0,0.0};
	CGRect labframe = [self.ctvovcp configLabel:@"Range:" 
								  frame:frame
									key:@"frLab" 
								  addsv:YES ];
	
	//frame = (CGRect) {-1.0f, frame.origin.y, 0.0f,labframe.size.height};
	//[self configActionBtn:frame key:@"frbBtn" label:@"Build" action:@selector(btnBuild:)]; 
	CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
	frame.origin.x = MARGIN;
	frame.origin.y += MARGIN + labframe.size.height;
    frame.size.width = screenSize.width - 2*MARGIN;  // seems always wrong on initial load // self.ctvovcp.view.frame.size.width - 2*MARGIN; // 300.0f;
	frame.size.height = self.ctvovcp.LFHeight;
	
    [self.ctvovcp configTextView:frame key:@"frangeTV" text:[self voRangeStr:FALSE]];
	
	frame.origin.y += frame.size.height + MARGIN;
	labframe = [self.ctvovcp configLabel:@"Definition:" 
						   frame:frame
							 key:@"fdLab" 
						   addsv:YES];
	
	frame = (CGRect) {-1.0f, frame.origin.y, 0.0f,labframe.size.height};
	//[self configActionBtn:frame key:@"fdbBtn" label:@"Build" action:@selector(btnBuild:)]; 
	
	frame.origin.x = MARGIN;
	frame.origin.y += MARGIN + frame.size.height;
	frame.size.width =  screenSize.width - 2*MARGIN;  // self.ctvovcp.view.frame.size.width - 2*MARGIN; // 300.0f;
	frame.size.height = 2* self.ctvovcp.LFHeight;
	
    CGFloat maxDim = [rTracker_resource getScreenMaxDim];
    if (maxDim > 480) {
        if (maxDim <= 568) {  // iphone 5
            frame.size.height = 3* self.ctvovcp.LFHeight;
        } else if (maxDim <= 736) { // iphone 6, 6+
            frame.size.height = 4* self.ctvovcp.LFHeight;
        } else {
            frame.size.height = 6* self.ctvovcp.LFHeight;
        }
    }

    [self.ctvovcp configTextView:frame key:@"fdefnTV" text:[self voFnDefnStr:FALSE]];
	
	frame.origin.y += frame.size.height + MARGIN;
	
	labframe = [self.ctvovcp configLabel:@"Display result decimal places:" frame:frame key:@"fnddpLab" addsv:YES];
	
	frame.origin.x += labframe.size.width + SPACE;
    CGFloat tfWidth = [@"999" sizeWithAttributes:@{NSFontAttributeName:PrefBodyFont}].width;
	frame.size.width = tfWidth;
	frame.size.height = self.ctvovcp.LFHeight; // self.labelField.frame.size.height; // lab.frame.size.height;
	
	[self.ctvovcp configTextField:frame 
						key:@"fnddpTF" 
					 target:nil 
					 action:nil
						num:YES 
					  place:[NSString stringWithFormat:@"%d",FDDPDFLT] 
					   text:(self.vo.optDict)[@"fnddp"]
					  addsv:YES ];
	
	
	frame.origin.x = MARGIN;
	frame.origin.y += MARGIN + labframe.size.height;
	
	frame = [self.ctvovcp yAutoscale:frame];
	
	//frame.origin.y += frame.size.height + MARGIN;
	//frame.origin.x = MARGIN;
	
    self.ctvovcp.lasty = frame.origin.y + frame.size.height + MARGIN;
}

#pragma mark -
#pragma mark configTVObjVC general support

//
// called for btnDone in configTVObjVC
//

- (BOOL) funcDone {
    if (FnErr) return NO;
	if (self.fnArray != nil && [self.fnArray count] != 0) {
		//DBGLog(@"funcDone 0: %@",[self.vo.optDict objectForKey:@"func"]);
		[self saveFnArray];
		DBGLog(@"funcDone 1: %@",[self.vo.optDict objectForKey:@"func"]);

		// frep0 and 1 not set if user did not click on range picker
		if ((self.vo.optDict)[@"frep0"] == nil) 
			(self.vo.optDict)[@"frep0"] = @FREPDFLT;
		if ((self.vo.optDict)[@"frep1"] == nil) 
			(self.vo.optDict)[@"frep1"] = @FREPDFLT;
		
		DBGLog(@"ep0= %@  ep1=%@",[self.vo.optDict objectForKey:@"frep0"],[self.vo.optDict objectForKey:@"frep1"]);
	}
    return YES;
}

- (void) btnHelp {
    switch (self.fnSegNdx) {
        case FNSEGNDX_OVERVIEW:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://rob-miller.github.io/rTracker/rTracker/iPhone/QandA/addFunction.html#overview"] options:@{} completionHandler:nil];
            break;
        case FNSEGNDX_RANGEBLD:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://rob-miller.github.io/rTracker/rTracker/iPhone/QandA/addFunction.html#range"] options:@{} completionHandler:nil ];
            break;
        case FNSEGNDX_FUNCTBLD:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://rob-miller.github.io/rTracker/rTracker/iPhone/QandA/addFunction.html#operators"] options:@{} completionHandler:nil ];
            break;
        default:
            dbgNSAssert(0,@"fnSegmentAction bad index!");
            break;
    }
    

}

//
// called for configTVObjVC  viewDidLoad
//
- (void) funcVDL:(configTVObjVC*)ctvovc donebutton:(UIBarButtonItem*)db {
		
	if ([((trackerObj*)self.vo.parentTracker).valObjTable count] > 0) {
		
		UIBarButtonItem *flexibleSpaceButtonItem = [[UIBarButtonItem alloc]
													initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
													target:nil action:nil];
		
		NSArray *segmentTextContent = @[@"Overview", @"Range", @"Definition"];
		
		UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentTextContent];
		//[segmentTextContent release];
		
		[segmentedControl addTarget:self action:@selector(fnSegmentAction:) forControlEvents:UIControlEventValueChanged];
		//segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
		segmentedControl.selectedSegmentIndex = self.fnSegNdx ; //= 0;
		UIBarButtonItem *scButtonItem = [[UIBarButtonItem alloc]
										 initWithCustomView:segmentedControl];
        UIBarButtonItem *fnHelpButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(btnHelp)];
		
		ctvovc.toolBar.items = @[db, flexibleSpaceButtonItem, scButtonItem, flexibleSpaceButtonItem, fnHelpButtonItem, flexibleSpaceButtonItem];
		
	} else {
        ctvovc.toolBar.items = @[db];
    }
    
}


- (void) drawSelectedPage {
    self.ctvovcp.lasty = 2; //frame.origin.y + frame.size.height + MARGIN;
	switch (self.fnSegNdx) {
		case FNSEGNDX_OVERVIEW: 
			[self drawFuncOptsOverview];
			[super voDrawOptions:self.ctvovcp];
            break;
		case FNSEGNDX_RANGEBLD:
			[self drawFuncOptsRange];
            break;
		case FNSEGNDX_FUNCTBLD:
			[self drawFuncOptsDefinition];
			break;
		default:
			dbgNSAssert(0,@"fnSegmentAction bad index!");
			break;
	}
}

- (void) fnSegmentAction:(id)sender
{
	self.fnSegNdx = [sender selectedSegmentIndex];
	//DBGLog(@"fnSegmentAction: selected segment = %d", self.fnSegNdx);
	
	//[UIView beginAnimations:nil context:NULL];
	//[UIView setAnimationBeginsFromCurrentState:YES];
	//[UIView setAnimationDuration:kAnimationDuration];
    [UIView animateWithDuration:0.2 animations:^{
        [self.ctvovcp removeSVFields];
        [self drawSelectedPage];
    }];
	//[UIView commitAnimations];
}

#pragma mark protocol: voDrawOptions page 

- (void) setOptDictDflts {
    if (nil == (self.vo.optDict)[@"frep0"]) 
        (self.vo.optDict)[@"frep0"] = [NSString stringWithFormat:@"%d", FREPDFLT];
    if (nil == (self.vo.optDict)[@"frep1"]) 
        (self.vo.optDict)[@"frep1"] = [NSString stringWithFormat:@"%d", FREPDFLT];
    if (nil == (self.vo.optDict)[@"fnddp"]) 
        (self.vo.optDict)[@"fnddp"] = [NSString stringWithFormat:@"%d", FDDPDFLT];
    if (nil == (self.vo.optDict)[@"func"]) 
        (self.vo.optDict)[@"func"] = @"";
    if (nil == (self.vo.optDict)[@"autoscale"])
        (self.vo.optDict)[@"autoscale"] = (AUTOSCALEDFLT ? @"1" : @"0");
    if (nil == (self.vo.optDict)[@"graphlast"])
        (self.vo.optDict)[@"graphlast"] = (GRAPHLASTDFLT ? @"1" : @"0");
    
    return [super setOptDictDflts];
}

- (BOOL) cleanOptDictDflts:(NSString*)key {
    
    NSString *val = (self.vo.optDict)[key];
    if (nil == val) 
        return YES;
    
    if (([key isEqualToString:@"frep0"] && ([val intValue] == FREPDFLT))
        ||
        ([key isEqualToString:@"frep1"] && ([val intValue] == FREPDFLT))
        ||
        ([key isEqualToString:@"fnddp"] && ([val intValue] == FDDPDFLT))
        ||
        ([key isEqualToString:@"func"] && ([val isEqualToString:@""]))
        ||
        ([key isEqualToString:@"autoscale"] && [val isEqualToString:(AUTOSCALEDFLT ? @"1" : @"0")])
        ||
        ([key isEqualToString:@"graphlast"] && [val isEqualToString:(GRAPHLASTDFLT ? @"1" : @"0")])
        ) {
        [self.vo.optDict removeObjectForKey:key];
        return YES;
    }
    
    return [super cleanOptDictDflts:key];
}

- (BOOL) checkVOs {
    for (valueObj *valo in MyTracker.valObjTable) {
        if (valo.vtype != VOT_FUNC) {
            return TRUE;
        }
    }
    return FALSE;
}

- (void) noVarsAlert {
    [rTracker_resource alert:@"No variables for function" msg:@"A function needs variables to work on.\n\nPlease add a value (like a number, or anything other than a function) to your tracker before trying to create a function." vc:nil];
}

#pragma mark -


- (void) voDrawOptions:(configTVObjVC *)ctvovc {
	self.ctvovcp = ctvovc;
    [self reloadEmptyFnArray];
	[self drawSelectedPage];
    
    if (! [self checkVOs]) [self noVarsAlert];
    
}
#pragma mark -


#pragma mark picker support

//
// build list of titles for symbols,operations available for current point in fn definition string
//

- (void) ftAddFnSet {
	int i;
	//for (i=FN1ARGFIRST;i>=FN1ARGLAST;i--) {
	//	[self.fnTitles addObject:[NSNumber numberWithInt:i]];   xxx // add nsnumber token, enumerated by fn class
	//}
    for (i=0; i<ARG1CNT; i++) {
        [self.fnTitles addObject:(self.fn1args)[i]];
    }
    [self.fnTitles addObject:@FNCONSTANT];
}

- (void) ftAddTimeSet {
	int i;
    for (i=0; i<TIMECNT; i++) {
        [self.fnTitles addObject:(self.fnTimeOps)[i]];
    }
	//for (i=FNTIMEFIRST;i>=FNTIMELAST;i--) {
	//	[self.fnTitles addObject:[NSNumber numberWithInt:i]];   xxx
	//}
}

- (void) ftAdd2OpSet {
	int i;
    for (i=0;i<ARG2CNT;i++) {
        [self.fnTitles addObject:(self.fn2args)[i]];
    }
	//for (i=FN2ARGFIRST;i>=FN2ARGLAST;i--) {
	//	[self.fnTitles addObject:[NSNumber numberWithInt:i]];  xxx
	//}
}

- (void) ftAddVOs {
	for (valueObj *valo in MyTracker.valObjTable) {
        if (valo != self.vo) {
            [self.fnTitles addObject:@(valo.vid)];
        }
	}
}

- (void) ftAddCloseParen {
	int pcount=0;
	for (NSNumber *ni in self.fnArray) {
		int i = [ni intValue];
		if (i == FNPARENOPEN) {
			pcount++;
		} else if (i == FNPARENCLOSE) {
			pcount--;
		}
	}
	if (pcount > 0) 
		[self.fnTitles addObject:@FNPARENCLOSE];
}

- (void) ftStartSet {
	[self ftAddFnSet];
    [self ftAddTimeSet];
	[self.fnTitles addObject:@FNPARENOPEN];
	[self ftAddVOs];
}

- (void) updateFnTitles {  // create array fnTitles of nsnumber tokens which should be presented in picker for current last of fn being built
	[self.fnTitles removeAllObjects];
    [self hideConstTF];
    DBGLog(@"fnArray= %@",self.fnArray);
	if ([self.fnArray count] == 0) {  // state = start
		[self ftStartSet];
	} else {
		int last = [[self.fnArray lastObject] intValue];
		if (last >= 0 || last <= -TMPUNIQSTART || isFnTimeOp(last) || FNCONSTANT == last) { // state = after valObj
			[self ftAdd2OpSet];
			[self ftAddCloseParen];
		} else if (isFn1Arg(last)) {  // state = after Fn1 = delta, avg, sum
			[self ftAddVOs];
		} else if (isFn2ArgOp(last)) { // state = after fn2op = +,-,*,/
			[self ftStartSet];
		} else if (last == FNPARENCLOSE) { // state = after close paren
			[self ftAdd2OpSet];
			[self ftAddCloseParen];
		} else if (last == FNPARENOPEN) { // state = after open paren
			[self ftStartSet];
		} else {
			dbgNSAssert(0,@"lost it at updateFnTitles");
		}
	}
}

- (NSString*) fnTokenToStr:(NSInteger)tok {  // convert token to str
	if (isFn(tok)) {
        return (self.fnStrDict)[@(tok)];
		//tok = (tok * -1) -1;
		//return [self.fnStrs objectAtIndex:tok];
	} else {	
		for (valueObj *valo in MyTracker.valObjTable) {
			if (valo.vid == tok)
				return valo.valueName;
		}
		dbgNSAssert(0,@"fnTokenToStr failed to find valObj");
		return @"unknown vid";
	}
}

- (NSString*) fndRowTitle:(NSInteger)row {
	return [self fnTokenToStr:[(self.fnTitles)[row] integerValue]];   // get nsnumber(tok) from fnTitles, convert to int, convert to str to be placed in specified picker rox
}

- (NSInteger) fnrRowCount:(NSInteger)component {
/*
	NSInteger other = (component ? 0 : 1);
	NSString *otherKey = [NSString stringWithFormat:@"frep%d",other];
	id otherObj = [self.vo.optDict objectForKey:otherKey];
	NSInteger otherVal = [otherObj integerValue];
	if (otherVal < -1) {
 */ // only allow time offset for previous side of range
	if (component == 1) {
        DBGLog(@" returning %lu",(unsigned long)([self.votWoSelf count]+1));
        return [self.votWoSelf count]+1;  // [MyTracker.valObjTable count]+1;  // count all +1 for 'current entry'
	} else {
        DBGLog(@" returning %lu",(unsigned long)([self.votWoSelf count]+MAXFREP));
		return [self.votWoSelf count] + MAXFREP; //[MyTracker.valObjTable count] + MAXFREP;
	}
}

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	if (self.fnSegNdx == FNSEGNDX_RANGEBLD)
		return 2;
	else 
		return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger) component {
	if (self.fnSegNdx == FNSEGNDX_RANGEBLD) 
		return [self fnrRowCount:component];
	else 
		return [self.fnTitles count];
}

- (NSString *) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row
			 forComponent:(NSInteger)component {
	if (self.fnSegNdx == FNSEGNDX_RANGEBLD) {
		return [self fnrRowTitle:row];
	} else {  // FNSEGNDX_FUNCTBLD
		return [self fndRowTitle:row];
	}
	//return [NSString stringWithFormat:@"row %d", row];
}

- (void) updateForPickerRowSelect:(NSInteger)row inComponent:(NSInteger)component {
	if (self.fnSegNdx == FNSEGNDX_RANGEBLD) {
		[((UIPickerView*) (self.ctvovcp.wDict)[@"frPkr"]) reloadComponent:(component ? 0 : 1)];
	} //else {
		//[((UIPickerView*) [self.wDict objectForKey:@"fnPkr"]) reloadComponent:0];
	//}
}

- (void) showConstTF {
    // display constant box
    UITextField *vtf= (self.ctvovcp.wDict)[CTFKEY];
    vtf.text = (self.vo.optDict)[LCKEY];
    [self.ctvovcp.scroll addSubview:(self.ctvovcp.wDict)[CLKEY]];
    [self.ctvovcp.scroll addSubview:vtf];
}

- (void) hideConstTF {
    // hide constant box
    [((UIView*) (self.ctvovcp.wDict)[CTFKEY]) removeFromSuperview];
    [((UIView*) (self.ctvovcp.wDict)[CLKEY]) removeFromSuperview];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component  
{	
	if (self.fnSegNdx == FNSEGNDX_RANGEBLD) {
		NSInteger votc = [self.votWoSelf count]; //[MyTracker.valObjTable count];
		
		NSString *key = [NSString stringWithFormat:@"frep%ld",(long)component];
		NSString *vtfkey = [NSString stringWithFormat:@"fr%ldTF",(long)component];
		NSString *pre_vkey = [NSString stringWithFormat:@"frpre%ldvLab",(long)component];
		NSString *post_vkey = [NSString stringWithFormat:@"frpost%ldvLab",(long)component];
        
		[((UIView*) (self.ctvovcp.wDict)[pre_vkey]) removeFromSuperview];
		[((UIView*) (self.ctvovcp.wDict)[vtfkey]) removeFromSuperview];
		[((UIView*) (self.ctvovcp.wDict)[post_vkey]) removeFromSuperview];
        [((UIView*) (self.ctvovcp.wDict)[@"graphLastBtn"]) removeFromSuperview];
        [((UIView*) (self.ctvovcp.wDict)[@"graphLastLabel"]) removeFromSuperview];
        
		if (row == 0) {
			(self.vo.optDict)[key] = @-1;
		} else if (row <= votc) {
			(self.vo.optDict)[key] = @(((valueObj*) (self.votWoSelf)[row-1]).vid);  
		} else { 
			(self.vo.optDict)[key] = @(((row - votc) +1) * -1);
			[self updateValTF:row component:component];
		}
		DBGLog(@"picker sel row %ld %@ now= %ld", (long)row, key, (long)[[self.vo.optDict objectForKey:key] integerValue] );
	} else if (self.fnSegNdx == FNSEGNDX_FUNCTBLD) {
        //DBGLog(@"fn build row %d= %@",row,[self fndRowTitle:row]);
        if ([FNCONSTANT_TITLE isEqualToString:[self fndRowTitle:row]]) {
            [self showConstTF];
        } else {
            [self hideConstTF];
        }
	}
	
	[self updateForPickerRowSelect:row inComponent:component];
	
}


#pragma mark -
#pragma mark fn value results for graphing

- (void) trimFnVals:(NSInteger)frep0 {
    DBGLog(@"ep= %ld",(long)frep0);
    NSString *sql;

    NSInteger ival = [(self.vo.optDict)[@"frv0"] integerValue] *  -1 ; // negative offset if ep0
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];

    switch (frep0) {
        case FREPCDAYS :
            ival += 1;   // for -1 calendar day, we want offset -0 day and normalize to previous midnight below
            [offsetComponents setDay:ival];
            //vt = @"days";
            break;
        case FREPCWEEKS :
            ival += 1;
            [offsetComponents setWeekOfYear:ival];
            //vt = @"weeks";
            break;
        case FREPCMONTHS :
            ival += 1;
            [offsetComponents setMonth:ival];
            //vt = @"months";
            break;
        case FREPCYEARS :
            ival += 1;
            //vt = @"years";
            [offsetComponents setYear:ival];
            break;
        default:
            dbgNSAssert1(0,@"trimFnVals: failed to identify ep %ld",(long)frep0);
            break;
    }
    
    NSInteger epDate=-1;
   
    sql = [NSString stringWithFormat:@"select date from voData where id = %ld order by date desc",(long)self.vo.vid];
    NSMutableArray *dates = [[NSMutableArray alloc] init];
    [MyTracker toQry2AryI:dates sql:sql];
    for (NSNumber *d in dates) {
        NSDate *targ = [gregorian dateByAddingComponents:offsetComponents
                                                  toDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[d intValue]]
                                                 options:0];
        
        unsigned unitFlags = 0;
        
		switch (frep0) {
                // if calendar week, we need to get to beginning of week as per calendar
			case FREPCWEEKS :
            {
                NSDate *beginOfWeek=nil;
                //BOOL rslt = [gregorian rangeOfUnit:NSWeekCalendarUnit startDate:&beginOfWeek interval:NULL forDate: targ];
                BOOL rslt = [gregorian rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&beginOfWeek interval:NULL forDate: targ];
                if (rslt) {
                    targ = beginOfWeek;
                }
            }
                // if any of week, day, month, year we need to wipe hour, minute, second components
			case FREPCDAYS :
                unitFlags |= NSCalendarUnitDay;
			case FREPCMONTHS :
                unitFlags |= NSCalendarUnitMonth;
			case FREPCYEARS :
                unitFlags |= NSCalendarUnitYear;
                NSDateComponents *components = [gregorian components:unitFlags fromDate:targ];
                targ = [gregorian dateFromComponents:components];
                break;
                
        }
        
        NSInteger currD = [targ timeIntervalSince1970];
        if (epDate == currD) {
           sql = [NSString stringWithFormat:@"delete from voData where id = %ld and date = %d",(long)self.vo.vid,[d intValue]];  // safe because this is just cached fn rslt
            [MyTracker toExecSql:sql];
        } else {
            epDate = currD;
        }
        
    }


}


-(void) setFnVals:(int)tDate { // called from trackerObj.m
    NSString *sql;
    if ([self.vo.value isEqualToString:@""]) {   //TODO: null/init value is 0.00 so what does this delete line do?
       sql = [NSString stringWithFormat:@"delete from voData where id = %ld and date = %d;",(long)self.vo.vid, tDate];
        //DBGLog(@"sql delete= %@",sql);
    } else {
       sql = [NSString stringWithFormat:@"insert or replace into voData (id, date, val) values (%ld, %d,'%@');",
                         (long)self.vo.vid, tDate, [rTracker_resource toSqlStr:self.vo.value]];
    }
    [MyTracker toExecSql:sql];
}

-(void) doTrimFnVals {
    NSInteger frep0 = [(self.vo.optDict)[@"frep0"] integerValue];
    if (ISCALFREP(frep0)
        &&
        (![(self.vo.optDict)[@"graphlast"] isEqualToString:@"0"])
        &&
        MyTracker.goRecalculate
        ) {
        [self trimFnVals:frep0];
    }
}

/*
// change to move loop on date to tracker level so just do once, not for every fn vo
 
 // TODO: rtm here -- optionally eliminate fn results for calendar unit endpoints
// based on vo opt @"graphlast"
- (void) setFnVals {
    int currDate = (int) [MyTracker.trackerDate timeIntervalSince1970];
    int nextDate = [MyTracker firstDate];
    
    if (0 == nextDate) {  // no data yet for this tracker so do not generate a 0 value in database
        return;
    }
    
    float ndx=1.0;
    float all = [self.vo.parentTracker getDateCount];
    
    do {
        [MyTracker loadData:nextDate];
        //DBGLog(@"sfv: %@ => %@",MyTracker.trackerDate, self.vo.value);
        if ([self.vo.value isEqualToString:@""]) {   //TODO: null/init value is 0.00 so what does this delete line do? 
           sql = [NSString stringWithFormat:@"delete from voData where id = %d and date = %d;",self.vo.vid, nextDate];
        } else {
           sql = [NSString stringWithFormat:@"insert or replace into voData (id, date, val) values (%d, %d,'%@');",
                        self.vo.vid, nextDate, [rTracker_resource toSqlStr:self.vo.value]];
        }
        [MyTracker toExecSql:sql];
        
        [rTracker_resource setProgressVal:(ndx/all)];
        ndx += 1.0;
        
    } while (MyTracker.goRecalculate && (nextDate = [MyTracker postDate]));    // iterate through dates
    
    NSInteger frep0 = [[self.vo.optDict objectForKey:@"frep0"] integerValue];
    if (ISCALFREP(frep0)
        &&
        (![[self.vo.optDict objectForKey:@"graphlast"] isEqualToString:@"0"])
        &&
        MyTracker.goRecalculate
        ) {
        [self trimFnVals:frep0];
    }
        
    // restore current date
	[MyTracker loadData:currDate];
    
}

- (void) recalculate {
    [self setFnVals];
}
*/

/*
- (void) transformVO:(NSMutableArray *)xdat ydat:(NSMutableArray *)ydat dscale:(double)dscale height:(CGFloat)height border:(float)border firstDate:(int)firstDate {

    // set val for all dates if dirty
    //[self setFnVals];
    
    [self transformVO_num:xdat ydat:ydat dscale:dscale height:height border:border firstDate:firstDate];
    
}
*/

- (id) newVOGD {
    return [[vogd alloc] initAsNum:self.vo];
}


@end
