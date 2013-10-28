//
//  AZSocketIONamespaceTests.m
//  AZSocketIO
//
//  Created by Luca Bernardi on 22/04/13.
//  Copyright (c) 2013 Patrick Shields. All rights reserved.
//

#import "Kiwi.h"
#import "AZSocketIO.h"

NSString * const kNamespaceName = @"/test";

SPEC_BEGIN(NamespaceTest)

describe(@"The socket", ^{
    __block AZSocketIO *socket = nil;
    
    context(@"when created", ^{
        it(@"should be constructable", ^{
            socket = [[AZSocketIO alloc] initWithHost:@"localhost"
                                              andPort:@"9000"
                                               secure:NO
                                        withNamespace:kNamespaceName];
            [socket shouldNotBeNil];
        });
        it(@"should have the right namespace", ^{
            [[socket.endpoint should] equal:kNamespaceName];
        });
    });
    
    context(@"when connected", ^{
        __block NSString *name;
        __block NSNumber *connected;
        it(@"should connect", ^{
            [socket connectWithSuccess:^{
                connected = @(YES);
                socket.eventRecievedBlock = ^(NSString *_name, id _args) {
                    name = _name;
                };
            } andFailure:^(NSError *error) {
                connected = @(NO);
            }];
            
            [[expectFutureValue(connected) shouldEventually] equal:@(YES)];
            
        });
        it(@"recieves an initial event", ^{
            [[expectFutureValue(name) shouldEventually] equal:@"namespaced_event"];
        });
        it(@"should say it's connected", ^{
            [[theValue(socket.state) should] equal:@(AZSocketIOStateConnected)];
        });
    });
    
    context(@"after connecting", ^{
        it(@"can emit an event and recieve the return val", ^{
            __block NSString *name = @"test_event";
            __block NSArray *args = [NSArray arrayWithObject:@"bar"];
            __block NSString *recievedName;
            __block NSArray *recievedArgs;
            [socket addCallbackForEventName:name callback:^(NSString *eventName, id data) {
                recievedName = eventName;
                recievedArgs = data;
            }];
            [socket emit:name args:args error:nil];
            [[expectFutureValue(recievedName) shouldEventually] equal:name];
            [[expectFutureValue(recievedArgs) shouldEventually] equal:args];
        });
    });
    
    context(@"when disconnecting", ^{
        it(@"can disconnect", ^{
            __block BOOL disconnected = FALSE;
            [socket setDisconnectedBlock:^{
                disconnected = TRUE;
            }];
            [socket disconnect];
            [[expectFutureValue(theValue(disconnected)) shouldEventually] beTrue];
        });
    });
    
    context(@"after disconnecting", ^{
        it(@"should say it's not connected", ^{
            [[theValue(socket.state) should] equal:@(AZSocketIOStateDisconnected)];
        });
    });
});
SPEC_END