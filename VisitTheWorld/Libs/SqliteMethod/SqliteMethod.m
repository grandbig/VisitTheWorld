//
//  SqliteMethod.m
//  LocationPractice
//
//  Created by 加藤 雄大 on 2013/10/06.
//  Copyright (c) 2013年 grandbig.github.io. All rights reserved.
//

#import "SqliteMethod.h"
#import "FMDatabase.h"

@implementation SqliteMethod

// DBに接続
- (id)dbConnect:(NSString *)dbName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString *dir = [paths objectAtIndex:0];
    FMDatabase *db = [FMDatabase databaseWithPath:[dir stringByAppendingPathComponent:dbName]];
    
    return db;
}

// レコード数を取得
- (NSInteger) countDB:(NSString *)dbName
            tableName:(NSString *)tableName
{
    FMDatabase*db = [self dbConnect:dbName];
    [db open];
    // 登録レコード数を取得
    NSString *cntQuery = [[NSString alloc] initWithFormat:@"select count(*) as count from %@", tableName];
    FMResultSet *rs = [db executeQuery:cntQuery];
    NSInteger count = 0;
    if([rs next]) {
        count = [rs intForColumn:@"count"];
        NSLog(@"count:%ld",(long)count);
    }
    [db close];
    
    return count;
}

// 指定したカラムの最大値を取得(※Integer型のみ)
- (NSInteger) getColumnMax:(NSString*)columnName
                    dbName:(NSString *)dbName
{
    FMDatabase*db = [self dbConnect:dbName];
    [db open];
    NSString *max = [[NSString alloc]initWithFormat:@"select max(%@) as max from %@", columnName, dbName];
    FMResultSet *rs = [db executeQuery:max];
    NSInteger maxNum = 0;
    if([rs next]) {
        maxNum = [rs intForColumn:@"max"];
        NSLog(@"max:%ld", (long)maxNum);
    }
    [db close];
    
    return maxNum;
};

@end
