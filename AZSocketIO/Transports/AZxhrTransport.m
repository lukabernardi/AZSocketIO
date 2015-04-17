//
//  AZxhrTransport.m
//  AZSocketIO
//
//  Created by Patrick Shields on 5/15/12.
//  Copyright 2012 Patrick Shields
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "AZxhrTransport.h"
#import "AZSocketIOTransportDelegate.h"

@interface AZxhrTransport ()
@property(nonatomic, weak)id<AZSocketIOTransportDelegate> delegate;
@property(nonatomic, readwrite, assign)BOOL connected;

@property (nonatomic, strong) NSString *baseURL;
@property (nonatomic, strong) NSURLSession *session;

@end

@implementation AZxhrTransport

@synthesize secureConnections;
@synthesize delegate;
@synthesize connected;

- (void)connect
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.baseURL]];
    request.HTTPMethod = @"GET";
    
    __weak id this = self;
    NSURLSessionTask *task = [self.session dataTaskWithRequest:request
                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                 
                                                 __strong typeof(self) strongThis = this;
                                                 if (data && !error) {
                                                     
                                                     strongThis.connected = YES;
                                                     if ([strongThis.delegate respondsToSelector:@selector(didOpen)]) {
                                                         [strongThis.delegate didOpen];
                                                     }
                                                     NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                     NSArray *messages = [responseString componentsSeparatedByString:@"\ufffd"];
                                                     if ([messages count] > 0) {
                                                         for (NSString *message in messages) {
                                                             [strongThis.delegate didReceiveMessage:message];
                                                         }
                                                     } else {
                                                         [strongThis.delegate didReceiveMessage:responseString];
                                                     }
                                                     
                                                     if (strongThis.connected) {
                                                         [strongThis connect];
                                                     }
                                                 }
                                                 else {
                                                     
                                                     [strongThis.delegate didFailWithError:error];
                                                     if ([strongThis.delegate respondsToSelector:@selector(didClose)]) {
                                                         [strongThis.delegate didClose];
                                                     }
                                                 }
                                             }];
    [task resume];

}
- (void)disconnect
{
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        [dataTasks enumerateObjectsUsingBlock:^(NSURLSessionTask *obj, NSUInteger idx, BOOL *stop) {
            [obj cancel];
        }];
        
        [uploadTasks enumerateObjectsUsingBlock:^(NSURLSessionTask *obj, NSUInteger idx, BOOL *stop) {
            [obj cancel];
        }];
        
        [downloadTasks enumerateObjectsUsingBlock:^(NSURLSessionTask *obj, NSUInteger idx, BOOL *stop) {
            [obj cancel];
        }];
    }];
    
    NSString *url = [NSString stringWithFormat:@"%@?disconnect", self.baseURL];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"GET";
    NSURLSessionTask *task = [self.session dataTaskWithRequest:request
                                             completionHandler:^(__unused NSData *data, __unused NSURLResponse *response, __unused NSError *error) {
                                                 
#ifdef DEBUG
                                                 if (error) {
                                                     NSLog(@"Error while disconnecting: %@", error);
                                                 }
#endif
                                             }];
    [task resume];
    
    self.connected = NO;
    if ([self.delegate respondsToSelector:@selector(didClose)]) {
        [self.delegate didClose];
    }
}
- (void)send:(NSString*)msg
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.baseURL]];
    request.HTTPMethod = @"POST";
    [request setHTTPBody:[msg dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"text/plain; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    
    __weak id this = self;
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                     
                                                     __strong typeof(self) strongThis = this;
                                                     if (data && !error) {
                                                         if ([strongThis.delegate respondsToSelector:@selector(didSendMessage)]) {
                                                             [strongThis.delegate didSendMessage];
                                                         }
                                                     }
                                                     else {
                                                         [strongThis.delegate didFailWithError:error];
                                                     }
                                                 }];
    [task resume];
}
- (id)initWithDelegate:(id<AZSocketIOTransportDelegate>)_delegate secureConnections:(BOOL)_secureConnections
{
    self = [super init];
    if (self) {
        self.connected = NO;
        self.delegate = _delegate;
        self.secureConnections = _secureConnections;
        
        NSString *protocolString = self.secureConnections ? @"https://" : @"http://";
        NSString *urlString = [NSString stringWithFormat:@"%@%@:%@/socket.io/1/xhr-polling/%@", 
                               protocolString, [self.delegate host], [self.delegate port], 
                               [self.delegate sessionId]];
        
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        
        self.baseURL = urlString;
    }
    return self;
}

@end
