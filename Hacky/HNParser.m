//
//  HNParser.m
//  Hacky
//
//  Created by Elias Klughammer on 06.02.13.
//  Copyright (c) 2013 Elias Klughammer. All rights reserved.
//

#import "HNParser.h"
#import "TFHpple.h"

@implementation HNParser

- (NSMutableArray*)parseStories:(NSString*)response
{
  NSMutableArray *stories = [[NSMutableArray alloc] init];
  
  NSData* data = [response dataUsingEncoding:NSUTF8StringEncoding];
  TFHpple* doc = [[TFHpple alloc] initWithHTMLData:data];
  
  NSArray* tables = [doc searchWithXPathQuery:@"//table[not(@width)]"];
  
  TFHppleElement* mainTable = tables[0];
  
  NSArray* trs_ = [mainTable childrenWithTagName:@"tr"];
  NSMutableArray* trs = [NSMutableArray arrayWithArray:trs_];
  
  // --- Remove the "more" button
  [trs removeLastObject];
  [trs removeLastObject];
  
  NSMutableDictionary* story = [[NSMutableDictionary alloc] init];
  
  for (int i = 0; i < [trs count]; i++) {
    TFHppleElement* tr = trs[i];
    
    // --- First row of story (title)
    if (i % 3 == 0) {
      // --- Get title and URL
      NSArray *titleTds = [tr childrenWithClassName:@"title"];
      TFHppleElement *titleTd = [titleTds objectAtIndex:1];
      TFHppleElement *titleA = [titleTd firstChildWithTagName:@"a"];
      [story setValue:[titleA text] forKey:@"title"];
    
      // Check if URL is relative
      NSString *href = [titleA objectForKey:@"href"];
      NSURL *url = [NSURL URLWithString:[href lowercaseString] relativeToURL:[NSURL     URLWithString:@"http://news.ycombinator.com"]];
      [story setValue:[url absoluteString] forKey:@"url"];

      // --- Get id
      NSArray* tds = [tr childrenWithTagName:@"td"];
      TFHppleElement* upvoteTd = [tds objectAtIndex:1];
      TFHppleElement* upvoteCenter = [upvoteTd firstChildWithTagName:@"center"];
      TFHppleElement* upvoteA = [upvoteCenter firstChildWithTagName:@"a"];
      NSString* upvoteId = [upvoteA objectForKey:@"id"];
      NSString* storyId = [[upvoteId componentsSeparatedByString:@"_"] objectAtIndex:1];
      [story setValue:storyId forKey:@"id"];
    }
    // --- Second row of story (comment count, timestamp, etc)
    else if (i % 3 == 1) {
      NSArray* metaTds = [tr childrenWithClassName:@"subtext"];
      TFHppleElement* metaTd = [metaTds objectAtIndex:0];
      
      NSArray* metaAs = [metaTd childrenWithTagName:@"a"];
      
      // --- Ignore sponsored stories
      if (![metaAs count])
        continue;
      
      // --- Get score
      TFHppleElement* scoreSpan = [metaTd firstChildWithTagName:@"span"];
      NSString* scoreText = [scoreSpan text];
      NSString* score = [NSString stringWithFormat:@"%li", [self numberFromString:scoreText]];
      [story setValue:score forKey:@"score"];
      
      // --- Get username
      TFHppleElement* userA = [metaAs objectAtIndex:0];
      [story setValue:[userA text] forKey:@"user"];
      
      // --- Get comments count
      TFHppleElement* commentsA = [metaAs lastObject];
      NSString* commentsText = [commentsA text];
      NSString* comments = [NSString stringWithFormat:@"%li", [self numberFromString:commentsText]];
      [story setValue:comments forKey:@"comments"];
      
      TFHppleElement* createdElement = [[metaTd children] objectAtIndex:3];
      NSString* createdTextRaw = [createdElement content];
      NSString* createdTextNoDivider = [createdTextRaw stringByReplacingOccurrencesOfString:@"|" withString:@""];
      NSString* createdTextNoWhitespace = [self removeLeadingAndTrailingWhitespace:createdTextNoDivider];
      [story setValue:createdTextNoWhitespace forKey:@"created_at"];
      
      // -- Add a copy of the story to the array
      NSMutableDictionary* story_ = [NSMutableDictionary dictionaryWithDictionary:story];
      [stories addObject:story_];
      //      j++;
    }
  }
  
  return stories;
}

- (NSInteger)numberFromString:(NSString*)string
{
  // Input
  NSString *originalString = string;
  
  // Intermediate
  NSString *numberString;
  
  NSScanner *scanner = [NSScanner scannerWithString:originalString];
  NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
  
  // Throw away characters before the first number.
  [scanner scanUpToCharactersFromSet:numbers intoString:NULL];
  
  // Collect numbers.
  [scanner scanCharactersFromSet:numbers intoString:&numberString];
  
  // Result.
  long number = [numberString integerValue];
  
  return number;
}

-(NSString*)removeLeadingAndTrailingWhitespace:(NSString*)string {
  NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
  NSPredicate *noEmptyStrings = [NSPredicate predicateWithFormat:@"SELF != ''"];
  
  NSArray *parts = [string componentsSeparatedByCharactersInSet:whitespaces];
  NSArray *filteredArray = [parts filteredArrayUsingPredicate:noEmptyStrings];
  
  return [filteredArray componentsJoinedByString:@" "];
}

@end
