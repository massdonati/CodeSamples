//
//  WFAPIClient.h
//  Interface to handle the RESTFull APIs
//

#import <AFHTTPClient.h>
#import "WFItem.h"

@interface WFAPIClient : AFHTTPClient

+(instancetype)sharedClient;

-(void)loginWithEmail:(NSString *)email andPassword:(NSString *) password withController:(id) controller;

-(void)signupWithParams:(NSDictionary *)params withController:(id) controller;

-(void)postNewItem:(NSDictionary *) item andController:(id) controller;
-(void)deleteItem:(WFItem *)item;

@end