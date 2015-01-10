//
//  SqliteMethod.h
//  LocationPractice
//
//  Created by 加藤 雄大 on 2013/10/06.
//  Copyright (c) 2013年 grandbig..github.io. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SqliteMethod : NSObject {
    
}

- (id) dbConnect:(NSString *)dbName;
- (NSInteger) countDB:(NSString *)dbName
            tableName:(NSString *)tableName;
- (NSInteger) getColumnMax:(NSString*)columnName
                    dbName:(NSString *)dbName;

@end
