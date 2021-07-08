//
//  NSDate+CXIMExtensions.m
//  Pods
//
//  Created by wshaolin on 2019/3/25.
//

#import "NSDate+CXIMExtensions.h"
#import <CXFoundation/CXFoundation.h>

@implementation NSDate (CXIMExtensions)

+ (NSString *)im_formattingDateToString:(NSDate *)date{
    if(!date){
        return nil;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if([date cx_isToday]){
        dateFormatter.dateFormat = @"HH:mm";
    }else if([date cx_isYesterday]){
        dateFormatter.dateFormat = @"昨天 HH:mm";
    }else if([date cx_isThisWeek]){
        dateFormatter.dateFormat = @"EEE HH:mm";
    }else if([date cx_isThisYear]){
        dateFormatter.dateFormat = @"MM月dd日 HH:mm";
    }else{
        dateFormatter.dateFormat = @"yyyy年MM月dd日";
    }
    
    return [dateFormatter stringFromDate:date];
}

@end
