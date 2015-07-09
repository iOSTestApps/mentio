//
//  MTDatabaseManager.m
//  Mentio
//
//  Created by Martin Hartl on 15/03/14.
//  Copyright (c) 2014 Martin Hartl. All rights reserved.
//

#import "MTDatabaseManager.h"
#import <FCModel/FCModel.h>
#import <FMDB/FMDatabaseAdditions.h>
#import "MTImageCacher.h"
#import "MTItunesClient.h"

@implementation MTDatabaseManager

+ (NSString *)databasePath {
    return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"db.mentio"];
}

+ (void)restoreFromMentioFileAtURL:(NSURL *)url success:(void (^)())successBlock rollback:(void(^)())rollbackBlock {
    NSError *error;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsURL = [paths lastObject];
    
    NSString *filePath = [[documentsURL URLByAppendingPathComponent:@"db.mentio"] path];
    
    if ([fileManager fileExistsAtPath:filePath]) {
        [self renameFileFrom:@"db.mentio" to:@"db.mentio.backup"];
        NSData *content = [NSData dataWithContentsOfURL:url];
        [content writeToFile:filePath atomically:YES];
        
    } else {
        [fileManager copyItemAtURL:url toURL:documentsURL error:&error];
        [self renameFileFrom:url.lastPathComponent to:@"db.mentio"];
    }
    
    
    BOOL success = [self setUpFCModel];
    
    if (!success) {
        [fileManager removeItemAtPath:filePath error:nil];
        [self renameFileFrom:@"db.mentio.backup" to:@"db.mentio"];
        [self setUpFCModel];
        if (rollbackBlock) {
            rollbackBlock();
        }
        return;
    }
    
    if (successBlock) {
        NSString *backupFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"db.mentio.backup"];
        [fileManager removeItemAtPath:backupFilePath error:nil];
        successBlock();
    }
    return;
    
    
    
}

+ (BOOL)setUpFCModel {
    
    [self renameFileFrom:@"db.sqlite3" to:@"db.mentio"];
    
    NSString *dbPath = [self databasePath];
    NSLog(@"DB path: %@", dbPath);
    
    // New DB on every launch for testing (comment out for persistence testing)
//    [NSFileManager.defaultManager removeItemAtPath:dbPath error:NULL];
    
    __block BOOL success;
    
    [FCModel openDatabaseAtPath:dbPath withSchemaBuilder:^(FMDatabase *db, int *schemaVersion) {
        [db setCrashOnErrors:NO];
        db.traceExecution = NO; // Log every query (useful to learn what FCModel is doing or analyze performance)
        [db beginTransaction];
        
        void (^failedAt)(int statement) = ^(int statement){
            int lastErrorCode = db.lastErrorCode;
            NSString *lastErrorMessage = db.lastErrorMessage;
            NSLog(@"Database commit failed with Code %d and message %@", lastErrorCode, lastErrorMessage);
            [db rollback];
        };
        
        
        if ([db tableExists:@"_FCModelMetadata"]) {
            int schema_version_old = 0;
            FMResultSet *rs = [db executeQuery:@"SELECT value FROM _FCModelMetadata;"];
            if ([rs next]) {
                schema_version_old = [rs intForColumnIndex:0];
                NSLog(@"schema_Version_old %d", schema_version_old);
                [rs close];
            }
            
            if (schema_version_old > *schemaVersion) {
                NSLog(@"update old schema to new");
                [db executeUpdate:[NSString stringWithFormat:@"PRAGMA user_version = %d", schema_version_old]];
                *schemaVersion = schema_version_old;
                [db executeUpdate:@"drop table _FCModelMetadata"];
            }
        }
        
        
        NSLog(@"schema version: %d", *schemaVersion);
        
        if (*schemaVersion < 1) {
            if (! [db executeUpdate:
                   @"CREATE TABLE MusicAlbum ("
                   @"                     id integer PRIMARY KEY AUTOINCREMENT NOT NULL,"
                   @"                     createdAt integer,"
                   @"                     updatedAt integer,"
                   @"                     archived boolean default 0,"
                   @"                     itemId integer,"
                   @"                     artistId integer,"
                   @"                     artistName text,"
                   @"                     collectionName text,"
                   @"                     collectionCensoredName text,"
                   @"                     artworkUrl100 text,"
                   @"                     artworkInternUrl text,"
                   @"                     copyright text,"
                   @"                     collectionPrice float,"
                   @"                     currency varchar,"
                   @"                     collectionId integer UNIQUE,"
                   @"                     collectionViewUrl text,"
                   @"                     releaseDate integer"
                   @"                     );"
                   ]) failedAt(1);
            
            
            if (! [db executeUpdate:
                   @"CREATE TABLE MusicTrack ("
                   @"                     id integer PRIMARY KEY AUTOINCREMENT NOT NULL,"
                   @"                     createdAt integer,"
                   @"                     updatedAt integer,"
                   @"                     collectionId integer NOT NULL,"
                   @"                     artistName text,"
                   @"                     trackName text,"
                   @"                     trackNumber integer"
                   @"                     );"
                   ])
                failedAt(2);
            
            if (! [db executeUpdate:
                   @"CREATE TABLE Movie ("
                   @"                     id integer PRIMARY KEY AUTOINCREMENT NOT NULL,"
                   @"                     createdAt integer,"
                   @"                     updatedAt integer,"
                   @"                     archived boolean default 0,"
                   @"                     itemId integer,"
                   @"                     artistId integer,"
                   @"                     artistName text,"
                   @"                     title text,"
                   @"                     collectionCensoredName text,"
                   @"                     artworkUrl100 text,"
                   @"                     artworkInternUrl text,"
                   @"                     copyright text,"
                   @"                     collectionPrice float,"
                   @"                     currency varchar,"
                   @"                     collectionId integer,"
                   @"                     collectionViewUrl text,"
                   @"                     longDescription text,"
                   @"                     releaseDate integer"
                   @"                     );"
                   ]) failedAt(3);
            
            if (! [db executeUpdate:@"CREATE INDEX index_tracks_album ON MusicTrack (collectionId);"]) failedAt(4);
            
            if (! [db executeUpdate:
                   @"CREATE TABLE App ("
                   @"                   id integer PRIMARY KEY AUTOINCREMENT NOT NULL,"
                   @"                   createdAt integer,"
                   @"                   updatedAt integer,"
                   @"                   archived boolean default 0,"
                   @"                   trackId integer UNIQUE,"
                   @"                   artistId integer,"
                   @"                   artistName text,"
                   @"                   trackName text,"
                   @"                   price float,"
                   @"                   artworkUrl100 text,"
                   @"                   currency varchar,"
                   @"                   screenshots text,"
                   @"                   trackViewUrl,"
                   @"                   appDescription text,"
                   @"                   releaseDate integer,"
                   @"                   appVersion text,"
                   @"                   primaryGenreName text"
                   @"                   );"
                   
                   ]) failedAt(5);
            *schemaVersion = 1;
        }
        
        // Create any other tables...
        
        // If you wanted to change the schema in a later app version, you'd add something like this here:
        
        if (*schemaVersion < 2) {
            
            if (! [db executeUpdate:
                   @"CREATE TABLE Book ("
                   @"                   id integer PRIMARY KEY AUTOINCREMENT NOT NULL,"
                   @"                   createdAt integer,"
                   @"                   updatedAt integer,"
                   @"                   archived boolean default 0,"
                   @"                   trackId integer UNIQUE,"
                   @"                   artistId integer,"
                   @"                   artistName text,"
                   @"                   titleCensoredName text,"
                   @"                   title text,"
                   @"                   price float,"
                   @"                   artworkUrl100 text,"
                   @"                   artworkInternUrl text,"
                   @"                   currency varchar,"
                   @"                   trackViewUrl text,"
                   @"                   bookDescription text,"
                   @"                   releaseDate integer"
                   @"                   );"
                   
                   ]) failedAt(6);
            
            if (! [db executeUpdate:
                   @"CREATE TABLE TVSeason ("
                   @"                   id integer PRIMARY KEY AUTOINCREMENT NOT NULL,"
                   @"                   createdAt integer,"
                   @"                   updatedAt integer,"
                   @"                   archived boolean default 0,"
                   @"                   collectionId integer UNIQUE,"
                   @"                   artistId integer,"
                   @"                   artistName text,"
                   @"                   collectionName text,"
                   @"                   collectionCensoredName text,"
                   @"                   collectionPrice float,"
                   @"                   artworkUrl100 text,"
                   @"                   artworkInternUrl text,"
                   @"                   currency varchar,"
                   @"                   copyright text,"
                   @"                   collectionViewUrl text,"
                   @"                   seasonDescription text,"
                   @"                   releaseDate integer"
                   @"                   );"
                   
                   ]) failedAt(7);
            
            if (! [db executeUpdate:
                   @"CREATE TABLE TVEpisode ("
                   @"                     id integer PRIMARY KEY AUTOINCREMENT NOT NULL,"
                   @"                     createdAt integer,"
                   @"                     updatedAt integer,"
                   @"                     collectionId integer NOT NULL,"
                   @"                     artistName text,"
                   @"                     trackName text,"
                   @"                     trackNumber integer,"
                   @"                     trackViewUrl text,"
                   @"                     price float,"
                   @"                     currency varchar,"
                   @"                     episodeDescription text"
                   @"                     );"
                   ]) failedAt(8);
            
            
            *schemaVersion = 2;
            
        }
        
        if (*schemaVersion < 3) {
            /* reset selected country code */
            NSLog(@"reset county code");
            [[MTItunesClient sharedClient] setSelectedCountryCode:nil];
            
            *schemaVersion = 3;
        }
        
        if (*schemaVersion < 4) {
            
            if (! [db executeUpdate:
                   @"ALTER TABLE MusicAlbum RENAME TO MusicAlbum_tmp;"
                   ]) failedAt(9);
            if (! [db executeUpdate:
                   @"CREATE TABLE MusicAlbum ("
                   @"                     createdAt integer,"
                   @"                     updatedAt integer,"
                   @"                     archived boolean DEFAULT(0) NOT NULL,"
                   @"                     ownMedia boolean DEFAULT(0) NOT NULL,"
                   @"                     artistId integer NOT NULL,"
                   @"                     artistName text,"
                   @"                     collectionName text,"
                   @"                     collectionCensoredName text,"
                   @"                     artworkUrl100 text,"
                   @"                     copyright text,"
                   @"                     collectionPrice float,"
                   @"                     currency varchar,"
                   @"                     collectionId text PRIMARY KEY UNIQUE,"
                   @"                     collectionViewUrl text,"
                   @"                     releaseDate integer,"
                   @"                     notes text,"                   
                   @"                     orderValue integer NOT NULL"
                   @");"]) {
                failedAt(10);
            }
            
            if (! [db executeUpdate:
                   @"INSERT INTO MusicAlbum(createdAt, updatedAt, archived, artistId, artistName, collectionName, collectionCensoredName, artworkUrl100, copyright, collectionPrice, currency, collectionId, collectionViewUrl, releaseDate, orderValue)"
                   @" "
                   @"SELECT createdAt, updatedAt, archived, artistId, artistName, collectionName, collectionCensoredName, artworkUrl100, copyright, collectionPrice, currency, collectionId, collectionViewUrl, releaseDate, id"
                   @" "
                   @"FROM MusicAlbum_tmp;"]) {
                failedAt(11);
            }
            
            if (! [db executeUpdate:
                   @"DROP TABLE MusicAlbum_tmp;"]) {
                failedAt(12);
            }
            
            if (! [db executeUpdate:
                   @"ALTER TABLE Book RENAME TO Book_tmp;"
                   ]) failedAt(13);
            if (! [db executeUpdate:
                   @"CREATE TABLE Book ("
                   @"  					createdAt integer,"
                   @"  					updatedAt integer,"
                   @"  					archived boolean DEFAULT(0) NOT NULL,"
                   @"                   ownMedia boolean DEFAULT(0) NOT NULL,"
                   @"  					trackId text PRIMARY KEY UNIQUE,"
                   @"  					artistId integer NOT NULL,"
                   @"  					artistName text,"
                   @"  					titleCensoredName text,"
                   @"  					title text,"
                   @"  					price float,"
                   @"  					artworkUrl100 text,"
                   @"  					currency varchar,"
                   @"  					trackViewUrl text,"
                   @"  					bookDescription text,"
                   @"                   notes text,"
                   @"  					releaseDate integer,"
                   @"                   orderValue integer NOT NULL"
                   @");"]) {
                failedAt(14);
            }
            
            if (! [db executeUpdate:
                   @"INSERT INTO Book(createdAt, updatedAt, archived, trackId, artistId, artistName, titleCensoredName, title, price, artworkUrl100, currency, trackViewUrl, bookDescription, releaseDate, orderValue)"
                   @" "
                   @"SELECT createdAt, updatedAt, archived, trackId, artistId, artistName, titleCensoredName, title, price, artworkUrl100, currency, trackViewUrl, bookDescription, releaseDate, id"
                   @" "
                   @"FROM Book_tmp;"]) {
                failedAt(15);
            }
            
            if (! [db executeUpdate:
                   @"DROP TABLE Book_tmp;"]) {
                failedAt(16);
            }
            
            if (! [db executeUpdate:
                   @"ALTER TABLE Movie RENAME TO Movie_tmp;"
                   ]) failedAt(17);
            
            if (! [db executeUpdate:
                   @"CREATE TABLE Movie ("
                   @"  createdAt integer,"
                   @"  updatedAt integer,"
                   @"  archived boolean DEFAULT(0) NOT NULL,"
                   @"  ownMedia boolean DEFAULT(0) NOT NULL,"
                   @"  artistId integer NOT NULL,"
                   @"  artistName text,"
                   @"  title text,"
                   @"  collectionCensoredName text,"
                   @"  artworkUrl100 text,"
                   @"  copyright text,"
                   @"  collectionPrice float,"
                   @"  currency varchar,"
                   @"  collectionId text PRIMARY KEY UNIQUE,"
                   @"  collectionViewUrl text,"
                   @"  longDescription text,"
                   @"  releaseDate integer,"
                   @"  notes text,"
                   @"  orderValue integer NOT NULL"
                   @");"]) {
                failedAt(18);
            }
            
            if (! [db executeUpdate:
                   @"INSERT INTO Movie(createdAt, updatedAt, archived, artistId, artistName, title, collectionCensoredName, artworkUrl100, copyright, collectionPrice, currency, collectionId, collectionViewUrl, longDescription, releaseDate, orderValue)"
                   @" "
                   @"SELECT createdAt, updatedAt, archived, artistId, artistName, title, collectionCensoredName, artworkUrl100, copyright, collectionPrice, currency, collectionId, collectionViewUrl, longDescription, releaseDate, id"
                   @" "
                   @"FROM Movie_tmp;"]) {
                failedAt(19);
            }
            
            if (! [db executeUpdate:
                   @"DROP TABLE Movie_tmp;"]) {
                failedAt(20);
            }
            
            if (! [db executeUpdate:
                   @"ALTER TABLE App RENAME TO App_tmp;"
                   ]) failedAt(21);
            
            if (! [db executeUpdate:
                   @"CREATE TABLE App ("
                   @"  createdAt integer,"
                   @"  updatedAt integer,"
                   @"  archived boolean DEFAULT(0) NOT NULL,"
                   @"  ownMedia boolean DEFAULT(0) NOT NULL,"
                   @"  trackId text PRIMARY KEY UNIQUE,"
                   @"  artistId integer NOT NULL,"
                   @"  artistName text,"
                   @"  trackName text,"
                   @"  price float,"
                   @"  artworkUrl100 text,"
                   @"  currency varchar,"
                   @"  screenshots text,"
                   @"  trackViewUrl text,"
                   @"  appDescription text,"
                   @"  releaseDate integer,"
                   @"  appVersion text,"
                   @"  primaryGenreName text,"
                   @"  notes text,"
                   @"  orderValue integer NOT NULL"
                   @");"]) {
                failedAt(22);
            }
            
            if (! [db executeUpdate:
                   @"INSERT INTO App(createdAt, updatedAt, archived, trackId, artistId, artistName, trackName, price, artworkUrl100, currency, screenshots, trackViewUrl, appDescription, releaseDate, appVersion, primaryGenreName, orderValue)"
                   @" "
                   @"SELECT createdAt, updatedAt, archived, trackId, artistId, artistName, trackName, price, artworkUrl100, currency, screenshots, trackViewUrl, appDescription, releaseDate, appVersion, primaryGenreName, id"
                   @" "
                   @"FROM App_tmp;"]) {
                failedAt(23);
            }
            
            if (! [db executeUpdate:
                   @"DROP TABLE App_tmp;"]) {
                failedAt(24);
            }
            
            if (! [db executeUpdate:
                   @"ALTER TABLE TVSeason RENAME TO TVSeason_tmp;"
                   @""
                   ]) failedAt(25);
            
            if (! [db executeUpdate:                   @
                   "CREATE TABLE TVSeason ("
                   @"  createdAt integer,"
                   @"  updatedAt integer,"
                   @"  archived boolean DEFAULT(0) NOT NULL,"
                   @"  ownMedia boolean DEFAULT(0) NOT NULL,"
                   @"  collectionId text PRIMARY KEY UNIQUE,"
                   @"  artistId integer NOT NULL,"
                   @"  artistName text,"
                   @"  collectionName text,"
                   @"  collectionCensoredName text,"
                   @"  collectionPrice float,"
                   @"  artworkUrl100 text,"
                   @"  currency varchar,"
                   @"  copyright text,"
                   @"  collectionViewUrl text,"
                   @"  seasonDescription text,"
                   @"  releaseDate integer,"
                   @"  notes text,"
                   @"  orderValue integer NOT NULL"
                   @");"]) {
                failedAt(26);
            }
            
            if (! [db executeUpdate:
                   @"INSERT INTO TVSeason(createdAt, updatedAt, archived, collectionId, artistId, artistName, collectionName, collectionCensoredName, collectionPrice, artworkUrl100, currency, copyright, collectionViewUrl, seasonDescription, releaseDate, orderValue)"
                   @" "
                   @"SELECT createdAt, updatedAt, archived, collectionId, artistId, artistName, collectionName, collectionCensoredName, collectionPrice, artworkUrl100, currency, copyright, collectionViewUrl, seasonDescription, releaseDate, id"
                   @" "
                   @"FROM TVSeason_tmp;"]) {
                failedAt(27);
            }
            
            if (! [db executeUpdate:
                   @"DROP TABLE TVSeason_tmp;"]) {
                failedAt(28);
            }
            
            if (! [db executeUpdate:
                   @"DROP TABLE MusicTrack;"
                   ]) failedAt(29);
            
            if (! [db executeUpdate:
                   @"CREATE TABLE MusicTrack ("
                   @"  createdAt integer,"
                   @"  updatedAt integer,"
                   @"  collectionId integer NOT NULL,"
                   @"  artistName text,"
                   @"  trackName text,"
                   @"  trackNumber integer NOT NULL,"
                   @"  trackId text PRIMARY KEY UNIQUE"
                   @");"]) {
                failedAt(30);
            }
            
            if (! [db executeUpdate:
                   @"CREATE INDEX index_tracks_album ON MusicTrack (collectionId);"]) {
                failedAt(31);
            }
            
            if (! [db executeUpdate:
                   @"DROP TABLE TVEpisode;"]) {
                failedAt(32);
            }
            
            if (! [db executeUpdate:
                   @"CREATE TABLE TVEpisode ("
                   @"  createdAt integer,"
                   @"  updatedAt integer,"
                   @"  collectionId integer NOT NULL,"
                   @"  artistName text,"
                   @"  trackName text,"
                   @"  trackNumber integer NOT NULL,"
                   @"  trackViewUrl text,"
                   @"  price float,"
                   @"  currency varchar,"
                   @"  episodeDescription text,"
                   @"  trackId text PRIMARY KEY UNIQUE"
                   @");"]) {
                failedAt(33);
            }
            
            [[MTImageCacher sharedInstance] clearImageFolder];
            [[MTImageCacher sharedInstance] createImageFolder];
            
            *schemaVersion = 4;
            
        }
        
        
        success = [db commit];
    }];
    
    return success;
}

+ (BOOL)renameFileFrom:(NSString*)oldName to:(NSString *)newName
{
    NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                 NSUserDomainMask, YES) objectAtIndex:0];
    NSString *oldPath = [documentDir stringByAppendingPathComponent:oldName];
    NSString *newPath = [documentDir stringByAppendingPathComponent:newName];
    
    NSFileManager *fileMan = [NSFileManager defaultManager];
    NSError *error = nil;
    if (![fileMan moveItemAtPath:oldPath toPath:newPath error:&error])
    {
        return NO;
    }
    return YES;
}


@end
