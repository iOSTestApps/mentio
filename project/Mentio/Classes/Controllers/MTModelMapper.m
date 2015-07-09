//
//  MTModelMapper.m
//  Mentio
//
//  Created by Martin Hartl on 04/10/13.
//  Copyright (c) 2013 Martin Hartl. All rights reserved.
//

#import "MTModelMapper.h"
#import "KZPropertyMapper.h"
#import "MusicAlbum.h"
#import "MusicTrack.h"
#import "Movie.h"
#import "App.h"
#import "Book.h"
#import "TVSeason.h"
#import "MTSharedDateFormatter.h"
#import "TVEpisode.h"

NSString *const MTModelMapperMediaEntityAlbum = @"Album";
NSString *const MTModelMapperKindSong = @"song";
NSString *const MTModelMapperKindFeatureMovie = @"feature-movie";
NSString *const MTModelWrapperTypeSoftware = @"software";
NSString *const MTModelMapperKindBook = @"ebook";
NSString *const MTModelMapperMediaEntityTVSeason = @"TV Season";
NSString *const MTModelMapperKindTVEpisode = @"tv-episode";

@implementation MTModelMapper

+ (id)createModelWithDictionary:(NSDictionary *)dict {
    
    [KZPropertyMapper logIgnoredValues:NO];
    if ([[dict objectForKey:@"collectionType"] isEqualToString:MTModelMapperMediaEntityAlbum]) {
        return [self createMusicAlbumWithDictionary:dict];
    } else if ([[dict objectForKey:@"kind"] isEqualToString:MTModelMapperKindSong]) {
        return [self createMusicTrackWithDictionary:dict];
    } else if ([[dict objectForKey:@"kind"] isEqualToString:MTModelMapperKindFeatureMovie]) {
        return  [self createMovieWithDictionary:dict];
    } else if ([[dict objectForKey:@"wrapperType"] isEqualToString:MTModelWrapperTypeSoftware]) {
        return [self createAppWithDictionary:dict];
    } else if ([[dict objectForKey:@"kind"] isEqualToString:MTModelMapperKindBook]) {
        return [self createBookWithDictionary:dict];
    } else if ([[dict objectForKey:@"collectionType"] isEqualToString:MTModelMapperMediaEntityTVSeason]) {
        return [self createTVSeasonWithDictionary:dict];
    } else if ([[dict objectForKey:@"kind"] isEqualToString:MTModelMapperKindTVEpisode]) {
        return [self createTVEpisodeWithDictionary:dict];
    }
    
    return nil;
}

+ (id<MTModelProtocol>)modelForPrimaryKeyInDictionary:(NSDictionary *)dict {
    if ([[dict objectForKey:@"collectionType"] isEqualToString:MTModelMapperMediaEntityAlbum]) {
        return [MusicAlbum instanceWithPrimaryKey:[dict valueForKey:@"collectionId"]];
    } else if ([[dict objectForKey:@"kind"] isEqualToString:MTModelMapperKindSong]) {
        return nil;
    } else if ([[dict objectForKey:@"kind"] isEqualToString:MTModelMapperKindFeatureMovie]) {
        return [Movie instanceWithPrimaryKey:[dict valueForKey:@"trackId"]];
    } else if ([[dict objectForKey:@"wrapperType"] isEqualToString:MTModelWrapperTypeSoftware]) {
        return [App instanceWithPrimaryKey:[dict valueForKey:@"trackId"]];
    } else if ([[dict objectForKey:@"kind"] isEqualToString:MTModelMapperKindBook]) {
        return [Book instanceWithPrimaryKey:[dict valueForKey:@"trackId"]];
    } else if ([[dict objectForKey:@"collectionType"] isEqualToString:MTModelMapperMediaEntityTVSeason]) {
        return [TVSeason instanceWithPrimaryKey:[dict valueForKey:@"collectionId"]];
    } else if ([[dict objectForKey:@"kind"] isEqualToString:MTModelMapperKindTVEpisode]) {
        nil;
    }
    
    return nil;
}

+ (MusicAlbum *)createMusicAlbumWithDictionary:(NSDictionary *)dict {
    MusicAlbum *music = [MusicAlbum instanceWithPrimaryKey:[dict valueForKey:@"collectionId"]];
    [KZPropertyMapper mapValuesFrom:dict toInstance:music usingMapping:@{
        @"artistName": @"artistName",
        @"collectionName":@"collectionName",
        @"copyright":@"copyright",
        @"artistId":@"artistId",
        @"collectionCensoredName":@"collectionCensoredName",
        @"artworkUrl100":@"artworkUrl100",
        @"collectionPrice":@"collectionPrice",
        @"currency":@"currency",
        @"collectionViewUrl":@"collectionViewUrl"
    }];
    
    NSDate *date = [[MTSharedDateFormatter sharedInstace] configuredFormatDateFromString:[dict valueForKey:@"releaseDate"]];
    music.releaseDate = date;
    
    music.artworkUrl100 = [music.artworkUrl100 stringByReplacingOccurrencesOfString:@"100x100-75.jpg" withString:@"225x225-75.jpg"];
    
    return music;
}

+ (MusicTrack *)createMusicTrackWithDictionary:(NSDictionary *)dict {
    MusicTrack *track = [MusicTrack instanceWithPrimaryKey:[dict valueForKey:@"trackId"]];
    
    [KZPropertyMapper mapValuesFrom:dict toInstance:track usingMapping:@{
        @"artistName":@"artistName",
        @"trackName":@"trackName",
        @"trackNumber":@"trackNumber"
    }];
    
    return track;
}

+ (Movie *)createMovieWithDictionary:(NSDictionary *)dict {
    Movie *movie = [Movie instanceWithPrimaryKey:[dict valueForKey:@"trackId"]];
    [KZPropertyMapper mapValuesFrom:dict toInstance:movie usingMapping:@{
        @"artistName": @"artistName",
        @"trackName":@"title",
        @"copyright":@"copyright",
        @"artistId":@"artistId",
        @"trackCensoredName":@"collectionCensoredName",
        @"artworkUrl100":@"artworkUrl100",
        @"collectionPrice":@"collectionPrice",
        @"currency":@"currency",
        @"trackViewUrl":@"collectionViewUrl",
        @"longDescription":@"longDescription"
    }];
    
    NSDate *date = [[MTSharedDateFormatter sharedInstace] configuredFormatDateFromString:[dict valueForKey:@"releaseDate"]];
    
    if ([dict valueForKey:@"collectionHdPrice"]) {
        movie.collectionPrice = [dict objectForKey:@"collectionHdPrice"];
    }
    
    movie.releaseDate = date;
    movie.artworkUrl100 = [movie.artworkUrl100 stringByReplacingOccurrencesOfString:@"100x100-75.jpg" withString:@"200x200-75.jpg"];
    
    return movie;
}

+ (App *)createAppWithDictionary:(NSDictionary *)dict {
    App *app = [App instanceWithPrimaryKey:[dict valueForKey:@"trackId"]];
    [KZPropertyMapper mapValuesFrom:dict toInstance:app usingMapping:@{
        @"artistName": @"artistName",
        @"trackName":@"trackName",
        @"artworkUrl100":@"artworkUrl100",
        @"currency":@"currency",
        @"price":@"price",
        @"artistId":@"artistId",
        @"trackViewUrl":@"trackViewUrl",
        @"description":@"appDescription",
        @"version":@"appVersion",
        @"primaryGenreName":@"primaryGenreName"
      }];
    
    NSError *error;
    NSData *jsonData;
    NSArray *screenshotUrls = [dict objectForKey:@"screenshotUrls"];
    if (screenshotUrls.count == 0) {
        screenshotUrls = [dict objectForKey:@"ipadScreenshotUrls"];
    }
    
    jsonData = [NSJSONSerialization dataWithJSONObject:screenshotUrls options:0 error:&error];
    
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        app.screenshots = jsonString;
    }
    
    NSDate *date = [[MTSharedDateFormatter sharedInstace] configuredFormatDateFromString:[dict valueForKey:@"releaseDate"]];
    app.releaseDate = date;
    
    app.artworkUrl100 = [app.artworkUrl100 stringByReplacingOccurrencesOfString:@".png" withString:@".200x200-75.png"];
    
    return app;
}

+ (Book *)createBookWithDictionary:(NSDictionary *)dict {
    Book *book = [Book instanceWithPrimaryKey:[dict valueForKey:@"trackId"]];
    [KZPropertyMapper mapValuesFrom:dict toInstance:book usingMapping:@{
        @"artistName": @"artistName",
        @"trackName":@"title",
        @"copyright":@"copyright",
        @"artistId":@"artistId",
        @"trackCensoredName":@"titleCensoredName",
        @"artworkUrl100":@"artworkUrl100",
        @"price":@"price",
        @"currency":@"currency",
        @"trackViewUrl":@"trackViewUrl",
        @"description":@"bookDescription"
    }];
    
    NSDate *date = [[MTSharedDateFormatter sharedInstace] configuredFormatDateFromString:[dict valueForKey:@"releaseDate"]];
    
    book.releaseDate = date;
    
    book.artworkUrl100 = [book.artworkUrl100 stringByReplacingOccurrencesOfString:@"100x100-75.jpg" withString:@"225x225-75.jpg"];
    
    return book;
}

+ (TVSeason *)createTVSeasonWithDictionary:(NSDictionary *)dict {
    TVSeason *season = [TVSeason instanceWithPrimaryKey:[dict valueForKey:@"collectionId"]];
    [KZPropertyMapper mapValuesFrom:dict toInstance:season usingMapping:@{
        @"artistName": @"artistName",
        @"collectionName":@"collectionName",
        @"copyright":@"copyright",
        @"artistId":@"artistId",
        @"collectionCensoredName":@"collectionCensoredName",
        @"artworkUrl100":@"artworkUrl100",
        @"collectionPrice":@"collectionPrice",
        @"currency":@"currency",
        @"collectionViewUrl":@"collectionViewUrl",
        @"longDescription":@"seasonDescription"
    }];
    
    if ([dict valueForKey:@"collectionHdPrice"]) {
        season.collectionPrice = [dict objectForKey:@"collectionHdPrice"];
    }
    
    NSDate *date = [[MTSharedDateFormatter sharedInstace] configuredFormatDateFromString:[dict valueForKey:@"releaseDate"]];
    season.releaseDate = date;
    season.artworkUrl100 = [season.artworkUrl100 stringByReplacingOccurrencesOfString:@"100x100-75.jpg" withString:@"225x225-75.jpg"];
    
    return season;
}

+ (TVEpisode *)createTVEpisodeWithDictionary:(NSDictionary *)dict {
    TVEpisode *episode = [TVEpisode instanceWithPrimaryKey:[dict valueForKey:@"trackId"]];
    [KZPropertyMapper mapValuesFrom:dict toInstance:episode usingMapping:@{
         @"artistName":@"artistName",
         @"trackName":@"trackName",
         @"trackNumber":@"trackNumber",
         @"longDescription":@"episodeDescription",
         @"trackPrice":@"price",
         @"currency":@"currency",
         @"trackViewUrl":@"trackViewUrl"
    }];
    
    return episode;
}

@end
