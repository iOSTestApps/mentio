//
//  MTItunesClient.m
//  Mentio
//
//  Created by Martin Hartl on 04/10/13.
//  Copyright (c) 2013 Martin Hartl. All rights reserved.
//

#import "MTItunesClient.h"
#import "MTModelMapper.h"
#import "MusicAlbum.h"
#import "Movie.h"
#import "App.h"
#import "TVSeason.h"
#import "Book.h"

NSString *const MTItunesMediaTypeAll = @"all";
NSString *const MTItunesMediaTypeMusic = @"music";
NSString *const MTItunesMediaTypeMovie = @"movie";
NSString *const MTItunesMediaTypeMusicVideo = @"musicVideo";
NSString *const MTItunesMediaTypeTVShow = @"tvShow";
NSString *const MTItunesMediaTypeAudiobook = @"audiobook";
NSString *const MTItunesMediaTypeEBook = @"ebook";
NSString *const MTItunesMediaTypePodcast = @"podcast";
NSString *const MTItunesMediaTypeShortFilm = @"shortFilm";
NSString *const MTItunesMediaTypeSoftware = @"software,iPadSoftware";
NSString *const MTItunesMediaTypeBook = @"ebook";

NSString *const MTItunesMediaEntityAlbum = @"album";
NSString *const MTItunesMediaEntityMovie = @"movie";
NSString *const MTItunesMediaEntitySong = @"song";
NSString *const MTItunesMediaEntityApp = @"software,iPadSoftware";
NSString *const MTItunesMediaEntityBook = @"ebook";
NSString *const MTItunesMediaEntityTVShow = @"tvShow";
NSString *const MTItunesMediaEntityTVSeason = @"tvSeason";
NSString *const MTItunesMediaEntityTVEpisode = @"tvEpisode";

NSString *const MTItunesSelectedCountryCode = @"MTItunesSelectedCountryCode";

@implementation MTItunesClient

+ (MTItunesClient *)sharedClient {
    static MTItunesClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[super alloc] initWithBaseURL:[NSURL URLWithString:@"http://itunes.apple.com/"]];
    });
    
    return _sharedClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        self.responseSerializer = [AFJSONResponseSerializer serializer];
    }
    
    return self;
}

- (id)searchMediaWithType:(NSString *)type entity:(NSString *)entity keyword:(NSString *)keywords limit:(NSUInteger)limit completion:(MHItunesCompletionBlock)completion {
    if (!type) {
        type = MTItunesMediaTypeAll;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:keywords forKey:@"term"];
    [params setObject:type forKey:@"media"];

    [params setObject:self.selectedCountryCode forKey:@"country"];
    
    [params setObject:@(limit) forKey:@"limit"];
    
    if (entity) {
        [params setObject:entity forKey:@"entity"];
    }
    
    return [self GET:@"search" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSArray *results = responseObject[@"results"];
        NSMutableArray *objects = [NSMutableArray arrayWithCapacity:results.count];
        
        for (NSDictionary *subDict in results) {
            id newObject = [MTModelMapper createModelWithDictionary:subDict];
            if (newObject) {
                [objects addObject:newObject];
            }
        }
        
        if (completion) {
            completion(objects,nil);
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        if (completion) {
            completion(nil, error);
        }
    }];
}

- (id)lookupMediaWithType:(NSString *)type entitiy:(NSString *)entitiy byId:(int64_t)mediaId completion:(MHItunesCompletionBlock)completion {
    if (!type) {
        type = MTItunesMediaTypeAll;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:[NSNumber numberWithLongLong:mediaId] forKey:@"id"];
    [params setObject:type forKey:@"media"];
    [params setObject:self.selectedCountryCode forKey:@"country"];
    if (entitiy) {
        [params setObject:entitiy forKey:@"entity"];
    }
    
    return [self GET:@"lookup" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        //success
        NSArray *results = responseObject[@"results"];
        
        NSMutableArray *objects = [NSMutableArray arrayWithCapacity:results.count];
        
        for (NSDictionary *subDict in results) {
            id newObject = [MTModelMapper createModelWithDictionary:subDict];
            
            if (![subDict objectForKey:@"collectionType"]) {
                if (newObject) {
                    [objects addObject:newObject];
                }
            }
        }
        
        if (completion) {
            completion(objects,nil);
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        if (completion) {
            completion(nil, error);
        }
    }];
}

- (id)updateMedia:(NSArray *)mediaArray completion:(MHItunesCompletionBlock)completion {
    
    NSMutableArray  *itemIds = [NSMutableArray array];
    for (id<MTModelProtocol> media in mediaArray) {
        [itemIds addObject:@(media.protItemId)];
    }
    
    NSDictionary *params = @{
                             @"id" : [itemIds componentsJoinedByString:@","],
                             @"country" : self.selectedCountryCode
                             };
    
    return [self GET:@"lookup" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSArray *results = responseObject[@"results"];
        NSMutableArray *objects = [NSMutableArray arrayWithCapacity:results.count];
        
        for (NSDictionary *subDict in results) {
            FCModel<MTModelProtocol> *oldModel = [MTModelMapper modelForPrimaryKeyInDictionary:subDict];
            float oldPrice = [oldModel.protPrice floatValue];
            FCModel *newObject = [MTModelMapper createModelWithDictionary:subDict];
            FCModel<MTModelProtocol> *protModel = (FCModel<MTModelProtocol> *) newObject;
            [newObject save];
            
            if ([protModel.protPrice floatValue] < oldPrice && !protModel.archived) {
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                localNotification.fireDate = [NSDate date];
                localNotification.alertBody = [NSString stringWithFormat:@"%@ %@ - %@: %.2f %@", NSLocalizedString(@"mtnotification.newpricefor", nil), protModel.protArtistName, protModel.protTitle, [protModel.protPrice floatValue], protModel.protCurrency];
                localNotification.timeZone = [NSTimeZone defaultTimeZone];
                
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
            }
        }
        
        if (completion) {
            completion(objects, nil);
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

- (void)refreshAllMedia:(MHItunesCompletionBlock)completion {
    NSArray *music = [MusicAlbum allInstances];
    NSArray *movies = [Movie allInstances];
    NSArray *apps = [App allInstances];
    NSArray *books = [Book allInstances];
    NSArray *tvSeries = [TVSeason allInstances];
    
    NSMutableArray *allModels = [NSMutableArray array];
    [allModels addObjectsFromArray:music];
    [allModels addObjectsFromArray:movies];
    [allModels addObjectsFromArray:apps];
    [allModels addObjectsFromArray:books];
    [allModels addObjectsFromArray:tvSeries];
    
    [[MTItunesClient sharedClient] updateMedia:allModels completion:^(NSArray *results, NSError *error) {
        
        if (completion) {
            completion(results, error);
        }
    }];
}


#pragma mark - CountryCode

- (void)setSelectedCountryCode:(NSString *)selectedCountryCode {
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setObject:selectedCountryCode forKey:MTItunesSelectedCountryCode];
    [def synchronize];
}

- (NSString *)selectedCountryCode {
    NSString *countyCode = [[NSUserDefaults standardUserDefaults] objectForKey:MTItunesSelectedCountryCode];
    
    if (!countyCode) {
        countyCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        if (!countyCode) {
            countyCode = @"US";
        }
    }
    
    return countyCode;
}


@end
