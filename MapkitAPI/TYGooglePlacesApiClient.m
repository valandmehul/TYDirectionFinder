//
//  TYGooglePlacesApiClient.m
//  MapkitAPI
//
//  Created by Thabresh on 8/9/16.
//  Copyright © 2016 VividInfotech. All rights reserved.
//

#import "TYGooglePlacesApiClient.h"
#import "TYGoogleAutoCompleteResult.h"
NSString *const apiKey = @"AIzaSyDchKp5BlxpFd_NOZVI7HgjvzHHm_vkhH0";
@interface TYGooglePlacesApiClient ()

@property (nonatomic, strong) NSCache *searchResultsCache;

@end
@implementation TYGooglePlacesApiClient
+(instancetype)sharedInstance{
    static TYGooglePlacesApiClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^(void){
        _sharedClient = [[TYGooglePlacesApiClient alloc] init];
    });
    
    return _sharedClient;
}


#pragma mark - Network Methods

-(void)retrieveGooglePlaceInformation:(NSString *)searchWord withCompletion:(void (^)(BOOL isSuccess, NSError *error))completion {
    
    if (!searchWord) {
        return;
    }
    
    searchWord = searchWord.lowercaseString;
    
    self.searchResults = [NSMutableArray array];
    
    if ([self.searchResultsCache objectForKey:searchWord]) {
        NSArray * pastResults = [self.searchResultsCache objectForKey:searchWord];
        self.searchResults = [NSMutableArray arrayWithArray:pastResults];
        completion(YES, nil);
        
    } else {
        
        NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/autocomplete/json?input=%@&types=establishment|geocode&radius=500&language=en&key=%@",searchWord,apiKey];
        
        NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSDictionary *jSONresult = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];;
            
            if (error || [jSONresult[@"status"] isEqualToString:@"NOT_FOUND"] || [jSONresult[@"status"] isEqualToString:@"REQUEST_DENIED"]){
                if (!error){
                    NSDictionary *userInfo = @{@"error":jSONresult[@"status"]};
                    NSError *newError = [NSError errorWithDomain:@"API Error" code:666 userInfo:userInfo];
                    completion(NO, newError);
                    return;
                }
                completion(NO, error);
                return;
            } else {
                
                NSArray *results = [jSONresult valueForKey:@"predictions"];
                
                for (NSDictionary *jsonDictionary in results) {
                    TYGoogleAutoCompleteResult *location = [[TYGoogleAutoCompleteResult alloc] initWithJSONData:jsonDictionary];
                    [self.searchResults addObject:location];
                }
                
                [self.searchResultsCache setObject:self.searchResults forKey:searchWord];
                
                completion(YES, nil);
                
            }
        }];
        
        [task resume];
    }
}

-(void)retrieveJSONDetailsAbout:(NSString *)place withCompletion:(void (^)(NSDictionary *placeInformation, NSError *error))completion {
    
    
    NSString *urlString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/details/json?placeid=%@&key=%@",place,apiKey];
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        
        if (error || [result[@"status"] isEqualToString:@"NOT_FOUND"] || [result[@"status"] isEqualToString:@"REQUEST_DENIED"]){
            if (!error){
                NSDictionary *userInfo = @{@"error":result[@"status"]};
                NSError *newError = [NSError errorWithDomain:@"API Error" code:666 userInfo:userInfo];
                completion(nil, newError);
                return;
            }
            
            
            
            completion(nil, error);
            return;
        }else{
            
            NSDictionary *placeDictionary = [result valueForKey:@"result"];
            completion(placeDictionary, nil);
        }
    }];
    
    [task resume];
    
}


#pragma mark - Properties

-(NSMutableArray *)searchResults {
    if (!_searchResults) {
        _searchResults = [NSMutableArray array];
    }
    return _searchResults;
}


-(NSCache *)searchResultsCache {
    if (!_searchResultsCache) {
        _searchResultsCache = [[NSCache alloc] init];
    }
    return _searchResultsCache;
}

@end
