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
@property (nonatomic, strong) NSURLRequest *connectionURLRequest;
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation AZxhrTransport
@synthesize secureConnections;
@synthesize delegate;
@synthesize connected;
- (void)connect
{
    [NSURLConnection sendAsynchronousRequest:self.connectionURLRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            [self.delegate didFailWithError:connectionError];
            if ([self.delegate respondsToSelector:@selector(didClose)]) {
                [self.delegate didClose];
            }
        }
        self.connected = YES;
        if ([self.delegate respondsToSelector:@selector(didOpen)]) {
            [self.delegate didOpen];
        }
        NSString *responseString = [self stringFromData:data];
        NSArray *messages = [responseString componentsSeparatedByString:@"\ufffd"];
        if ([messages count] > 0) {
            for (NSString *message in messages) {
                [self.delegate didReceiveMessage:message];
            }
        } else {
            [self.delegate didReceiveMessage:responseString];
        }
        
        if (self.connected) {
            [self connect];
        }
    }];
}

- (void)disconnect
{
    [self.session invalidateAndCancel];
    NSURL *disconnectURL = [self.connectionURLRequest.URL URLByAppendingPathComponent:@"?disconnect"];
    NSURLRequest *disconnectRequest = [NSURLRequest requestWithURL:disconnectURL];
    [NSURLConnection sendAsynchronousRequest:disconnectRequest queue:[NSOperationQueue mainQueue] completionHandler:NULL];
    self.connected = NO;
    if ([self.delegate respondsToSelector:@selector(didClose)]) {
        [self.delegate didClose];
    }
}

- (void)send:(NSString*)msg
{
    NSMutableURLRequest *request = [self.connectionURLRequest mutableCopy];
    request.HTTPMethod = @"POST";
    [request setHTTPBody:[msg dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"text/plain; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [self.delegate didFailWithError:error];
        }
        if ([self.delegate respondsToSelector:@selector(didSendMessage)]) {
            [self.delegate didSendMessage];
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
        
        self.connectionURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
    }
    return self;
}
- (NSString *)stringFromData:(NSData *)data
{
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
@end
