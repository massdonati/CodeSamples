//
//  WFAPIClient.m
//  iOS-WannaFix
//
//  Created by massimo on 09/04/13.
//  Copyright (c) 2013 Massimo. All rights reserved.
//


#import "WFConstants.h"
#import "WFAPIClient.h"
#import "AFNetworking.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "WFUser.h"
#import "WFItem.h"

@interface WFAPIClient ()

@property (nonatomic, strong) AFHTTPRequestOperation *operation;

@end


@implementation WFAPIClient


+(instancetype)sharedClient{
  static WFAPIClient *__sharedClient;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    __sharedClient = [[WFAPIClient alloc] initWithBaseURL:
                      [NSURL URLWithString:WannaFixAPIBaseURL]];
  });
  
  return __sharedClient;
}

-(instancetype) initWithBaseURL:(NSURL *)url{
  self = [super initWithBaseURL:url];
  if (self) {
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
  }
  return self;
}

#pragma mark - Session


#pragma mark LogIn

-(void)loginWithEmail:(NSString *)email andPassword:(NSString *) password withController:(id) controller{
  NSDictionary *params = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             email, @"email",
                                                             password, @"password",
                                                             nil] forKey:@"user"];

  
  AFJSONRequestOperation *login = [AFJSONRequestOperation JSONRequestOperationWithRequest:
                                   [[WFAPIClient sharedClient] multipartFormRequestWithMethod:@"POST" path:@"users/sign_in.json"
                                                                                    parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                                                      ;
                                                                                    }] success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                      [SVProgressHUD dismiss];
                                                                                      NSLog(@"@@@@ response is: %@", JSON);
                                                                                      NSLog(@"@@@@ response is: %@", JSON);
                                                                                      [[WFUser sharedUser] setToken:[JSON objectForKey:@"authentication_token"]];
                                                                                      [[WFUser sharedUser] setAttributesFromDictionary:[JSON objectForKey:@"user"]];
                                                                                      NSLog(@"%@", [[WFUser sharedUser] description]);
                                                                                      [[NSUserDefaults standardUserDefaults] setObject:email forKey:@"userEmail"];
                                                                                      [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"userPassword"];
                                                                                      [[NSUserDefaults standardUserDefaults] synchronize];
                                                                                      
                                                                                      [controller performSegueWithIdentifier:@"LoginSucces" sender:nil];

                                                                                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                      NSLog(@"%@", [error localizedDescription]);
                                                                                      [SVProgressHUD dismiss];
                                                                                      [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
                                                                                    }];
  
[[WFAPIClient sharedClient] enqueueHTTPRequestOperation:login];
}

#pragma mark signUp

-(void) signupWithParams:(NSDictionary *)params withController:(id) controller{
  
  
  
  
  AFJSONRequestOperation *signUp = [AFJSONRequestOperation JSONRequestOperationWithRequest:
                                   [[WFAPIClient sharedClient] multipartFormRequestWithMethod:@"POST" path:@"users.json"
                                                                                    parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                                                      ;
                                                                                    }] success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                      [SVProgressHUD dismiss];
                                                                                      [[NSUserDefaults standardUserDefaults] setObject:[params objectForKey:@"email"]  forKey:@"userEmail"];
                                                                                      [[NSUserDefaults standardUserDefaults] setObject:[params objectForKey:@"password"] forKey:@"userPassword"];
                                                                                      [[NSUserDefaults standardUserDefaults] synchronize];
                                                                                      [[NSNotificationCenter defaultCenter] postNotificationName:@"registrationProcessSusccess" object:nil];
                                                                                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                      
                                                                                      [SVProgressHUD dismiss];
                                                                                      
                                                                                      NSString *errorJson = [[JSON objectForKey:@"errors"] objectForKey:@"email"][0];
                                                                                      if ( errorJson == nil) {
                                                                                        [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
                                                                                      }
                                                                                      [SVProgressHUD showErrorWithStatus:errorJson];
                                                                                      
                                                                                      [[NSNotificationCenter defaultCenter] postNotificationName:@"registrationProcessFailed" object:nil];
                                                                                    }];
  [[WFAPIClient sharedClient] enqueueHTTPRequestOperation:signUp];
  }

#pragma mark - Item



#pragma mark post

-(void)postNewItem:(NSDictionary *) item andController:(id) controller{
  
  NSString *path = [NSString stringWithFormat:@"items.json?auth_token=%@", [[WFUser sharedUser] token]];
  
  NSURLRequest *postItem = [[WFAPIClient sharedClient] requestWithMethod:@"POST" path:path parameters:item];
  
  AFJSONRequestOperation *postItemOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:postItem
                                                                                  success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                    [SVProgressHUD dismiss];
                                                                                    NSLog(@"line 110 @@@@ response is: %@", JSON);
                                                                                    WFItem *newItem = [[WFItem alloc] initWithDictionary:JSON];
                                                                                    NSMutableArray *results = [NSMutableArray arrayWithArray:[[WFUser sharedUser] items]];
                                                                                    [results addObject:newItem];
                                                                                    ((WFUser *)[WFUser sharedUser]).items = results;
                                                                                    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadItemsdata" object:nil];
                                                                                  } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                    [SVProgressHUD dismiss];
                                                                                    [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
                                                                                    
                                                                                  }];
  [[WFAPIClient sharedClient] enqueueHTTPRequestOperation:postItemOperation];
}

#pragma mark delete

-(void)deleteItem:(WFItem *)item{
  NSString *path = [NSString stringWithFormat:@"items/%@.json?auth_token=%@",item.itemId, [[WFUser sharedUser] token]];
  
  NSURLRequest *postItem = [[WFAPIClient sharedClient] requestWithMethod:@"DELETE" path:path parameters:nil];
  
  AFJSONRequestOperation *postItemOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:postItem
                                                                                              success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                                [SVProgressHUD dismiss];
                                                                                                NSMutableArray *results = [NSMutableArray arrayWithArray:[[WFUser sharedUser] items]];
                                                                                                [results removeObjectIdenticalTo:item];
                                                                                                ((WFUser *)[WFUser sharedUser]).items = results;
                                                                                                [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadItemsdata" object:nil];
                                                                                              } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                                [SVProgressHUD dismiss];
                                                                                                [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
                                                                                                
                                                                                              }];
  [[WFAPIClient sharedClient] enqueueHTTPRequestOperation:postItemOperation];
}

@end