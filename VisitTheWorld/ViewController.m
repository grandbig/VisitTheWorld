//
//  ViewController.m
//  VisitTheWorld
//
//  Created by 加藤 雄大 on 2014/12/27.
//  Copyright (c) 2014年 grandbig.github.io. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import "FMDatabase.h"
#import "SqliteMethod.h"

static NSString *dbName = @"visit.db";
static NSString *placeTable = @"place";
static NSString *motionTable = @"motion";

@interface ViewController () <CLLocationManagerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) CLLocationManager *lm;
@property (strong, nonatomic) CMPedometer *pmp;
@property (strong, nonatomic) UIAlertView *alert;
@property (assign, nonatomic) BOOL measureFlag;
@property (weak, nonatomic) IBOutlet UIButton *measureBtn;
@property (weak, nonatomic) IBOutlet UILabel *stepLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.lm = [[CLLocationManager alloc] init];
    self.lm.delegate = self;
    
    // 位置情報の取得許可を求めるメソッド
    [self.lm requestAlwaysAuthorization];
    
    // テーブルの作成
    [self createTable:placeTable];
    [self createTable:motionTable];
    
    self.alert.delegate = self;
    
    // 計測フラグの初期設定
    self.measureFlag = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CLLocationManager Protocol

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusNotDetermined) {
        // ユーザが位置情報の使用を許可していない
    } else if(status == kCLAuthorizationStatusAuthorizedAlways) {
        // ユーザが位置情報の使用を常に許可している場合
        // 滞在時間の取得開始
        [self.lm startMonitoringVisits];
        // 位置情報の取得開始
        [self.lm startUpdatingLocation];
    } else if(status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        // ユーザが位置情報の使用を使用中のみ許可している場合
    }
    NSLog(@"status: %d", status);
}

- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit
{
    // 値の取得
    float lat = visit.coordinate.latitude;                              // 緯度
    float lng = visit.coordinate.longitude;                             // 経度
    float hacc = visit.horizontalAccuracy;                              // 水平精度
    NSDate *arrivalDate = visit.arrivalDate;                            // 到着日時(NSDate型)
    NSDate *departureDate = visit.departureDate;                        // 出発日時(NSDate型)
    double arrivalUnixTime = [arrivalDate timeIntervalSince1970];       // 到着日時(timestamp)
    double departureUnixTime = [departureDate timeIntervalSince1970];   // 出発日時(timestamp)
    
    // NSDate型の日時をNSString型に変換
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString* arrivalDateString = [outputFormatter stringFromDate:arrivalDate];
    NSString* departureDateString = [outputFormatter stringFromDate:departureDate];
    
    // データの挿入
    [self insertPlaceData:lat longitude:lng horizontalAccuracy:hacc arrivalDate:arrivalDateString departureDate:departureDateString arrivalDateUT:arrivalUnixTime departureDateUT:departureUnixTime];
    // ローカルプッシュ
    NSString *message = [[NSString alloc] initWithFormat:@"lat: %f, lng: %f, hacc: %f, 到着日時: %@, 出発日時: %@", lat, lng, hacc, arrivalDateString, departureDateString];
    [self sendLocalNotificationForMessage:message soundFlag:NO];
}

#pragma mark - private method

/**
 テーブルの作成処理
 @param tableName テーブル名
 */
- (void)createTable:(NSString *)tableName
{
    SqliteMethod *sm = [[SqliteMethod alloc] init];
    FMDatabase *db = [sm dbConnect:dbName];
    NSString *sql;
    if([tableName isEqualToString:placeTable]) {
        // tableの作成
        sql = [[NSString alloc] initWithFormat:@"create table if not exists %@ (id INTEGER PRIMARY KEY, lat REAL, lng REAL, hacc REAL, aDate TEXT, dDate TEXT, aTimeStamp REAL, dTimeStamp REAL)", placeTable];
    } else if([tableName isEqualToString:motionTable]) {
        sql = [[NSString alloc] initWithFormat:@"create table if not exists %@ (id INTEGER PRIMARY KEY, step REAL, distance REAL, sDate TEXT, eDate TEXT, sTimeStamp REAL, eTimeStamp REAL, floorsAscended REAL, floorsDescended REAL)", motionTable];
    }
    
    [db open];
    [db executeUpdate:sql];
    [db close];
}

/**
 滞在データの挿入処理
 @param latitude 緯度
 @param longitude 経度
 @param horizontalAccuracy 水平精度
 @param arrivalDate 到着日時
 @param departureDate 出発日時
 @param arrivalDateUT 到着日時(timestamp)
 @param departureDateUT 出発日時(timestamp)
 */
- (void)insertPlaceData:(float)latitude
              longitude:(float)longitude
     horizontalAccuracy:(float)horizontalAccuracy
            arrivalDate:(NSString *)arrivalDate
          departureDate:(NSString *)departureDate
          arrivalDateUT:(double)arrivalDateUT
        departureDateUT:(double)departureDateUT
{
    SqliteMethod *sm = [[SqliteMethod alloc] init];
    FMDatabase *db = [sm dbConnect:dbName];
    
    // insert文
    NSString *sql = [[NSString alloc] initWithFormat:@"insert into %@ (lat, lng, hacc, aDate, dDate, aTimeStamp, dTimeStamp) values(%f, %f, %f, '%@', '%@', %f, %f)", placeTable, latitude, longitude, horizontalAccuracy, arrivalDate, departureDate, arrivalDateUT, departureDateUT];
    
    [db open];
    [db executeUpdate:sql];
    [db close];
}

/**
 歩行データの挿入処理
 @param step 歩数
 @param distance 距離
 @param startDate 開始日時
 @param endDate 終了日時
 @param startDateUT 開始日時(timestamp)
 @param endDateUT 終了日時(timestamp)
 @param floorsAscended 上がった回数
 @param floorsDescended 下がった回数
 */
- (void)insertMotionData:(NSInteger)step
                distance:(NSInteger)distance
               startDate:(NSString *)startDate
                 endDate:(NSString *)endDate
             startDateUT:(double)startDateUT
               endDateUT:(double)endDateUT
          floorsAscended:(NSInteger)floorsAscended
         floorsDescended:(NSInteger)floorsDescended
{
    SqliteMethod *sm = [[SqliteMethod alloc] init];
    FMDatabase *db = [sm dbConnect:dbName];
    
    // insert文
    NSString *sql = [[NSString alloc] initWithFormat:@"insert into %@ (step, distance, sDate, eDate, sTimeStamp, eTimeStamp, floorsAscended, floorsDescended) values(%ld, %ld, '%@', '%@', %f, %f, %ld, %ld)", motionTable, (long)step, (long)distance, startDate, endDate, startDateUT, endDateUT, (long)floorsAscended, (long)floorsDescended];
    
    [db open];
    [db executeUpdate:sql];
    [db close];
}

/**
 ローカルプッシュ通知処理
 @param message メッセージ
 @param sound 通知ONの設定
 */
- (void)sendLocalNotificationForMessage:(NSString *)message
                              soundFlag:(BOOL)soundFlag
{
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.alertBody = message;
    localNotification.fireDate = [NSDate date];
    if(soundFlag) {
        localNotification.soundName = UILocalNotificationDefaultSoundName;
    }
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

/**
 歩数の計測が可能か確認する処理
 return 歩数の計測の可否(YES: 可能, NO: 不可能)
 */
- (BOOL)confirmCMPedometer
{
    if([CMPedometer isStepCountingAvailable] && [CMPedometer isDistanceAvailable] && [CMPedometer isFloorCountingAvailable]) {
        return YES;
    } else {
        return NO;
    }
}

/**
 歩数の計測開始処理
 */
- (void)startPedometer
{
    self.pmp = [[CMPedometer alloc] init];
    [self.pmp startPedometerUpdatesFromDate:[NSDate date]
                                withHandler:^(CMPedometerData *pedometerData, NSError *error) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        // step数の取得
                                        NSNumber *step = pedometerData.numberOfSteps;
                                        NSInteger stepInt = [step integerValue];
                                        self.stepLabel.text = [[NSString alloc] initWithFormat:@"%ld", (long)stepInt];
                                        
                                        // 距離
                                        NSNumber *distance = pedometerData.distance;
                                        NSInteger distanceInt = [distance integerValue];
                                        
                                        // 開始日時, 終了日時のUnixTimeを取得
                                        double startDateUnixTime = [pedometerData.startDate timeIntervalSince1970];
                                        double endDateUnixTime = [pedometerData.endDate timeIntervalSince1970];
                                        
                                        // 日時取得のためにFormatを設定
                                        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
                                        [outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                                        // 開始日時, 終了日時のNSString型を取得
                                        NSString* startDateString = [outputFormatter stringFromDate:pedometerData.startDate];
                                        NSString *endDateString = [outputFormatter stringFromDate:pedometerData.endDate];
                                        
                                        // 階段の昇降
                                        NSNumber *floorsAscended = pedometerData.floorsAscended;
                                        NSNumber *floorsDescended = pedometerData.floorsDescended;
                                        NSInteger floorsAscendedInt = [floorsAscended integerValue];
                                        NSInteger floorsDescendedInt = [floorsDescended integerValue];
                                        
                                        // データの挿入
                                        [self insertMotionData:stepInt distance:distanceInt startDate:startDateString endDate:endDateString startDateUT:startDateUnixTime endDateUT:endDateUnixTime floorsAscended:floorsAscendedInt floorsDescended:floorsDescendedInt];
                                        
                                        // ローカルプッシュ通知
                                        NSString *message = [[NSString alloc] initWithFormat:@"Step Count Result\n\n歩数: %@\n距離: %@[m]\n開始時間: %@\n終了時間: %@\n上った回数: %@\n下りた回数: %@", step, distance, startDateString, endDateString, floorsAscended, floorsDescended];
                                        [self sendLocalNotificationForMessage:message soundFlag:NO];
                                    });
                                }];
}

/**
 歩数の計測停止処理
 */
- (void)stopPedometer
{
    [self.pmp stopPedometerUpdates];
}

/**
 STARTボタンをタップした時の処理
 */
- (IBAction)actionStartBtn:(id)sender {
    
    if(self.measureFlag) {
        // 計測中の場合
        self.alert = [[UIAlertView alloc] initWithTitle:@"確認"
                                                message:@"歩行の計測を停止しますか？"
                                               delegate:self
                                      cancelButtonTitle:@"キャンセル"
                                      otherButtonTitles:@"OK", nil];
        // タグの付与
        self.alert.tag = 2;
        // アラートの表示
        [self.alert show];
    } else {
        // 計測していない場合
        self.alert = [[UIAlertView alloc] initWithTitle:@"確認"
                                                message:@"歩行の計測を開始しますか？"
                                               delegate:self
                                      cancelButtonTitle:@"キャンセル"
                                      otherButtonTitles:@"OK", nil];
        
        // タグの付与
        self.alert.tag = 1;
        // アラートの表示
        [self.alert show];
    }
}

#pragma mark - UIAlertViewDelegate
// アラートのボタンを選択したときの挙動
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch(buttonIndex) {
        case 0:
        {
            NSLog(@"1つ目のボタンを選択しました。");
            if(alertView.tag == 1) {
                NSLog(@"キャンセルボタンをタップ");
            } else if(alertView.tag == 2) {
                NSLog(@"キャンセルボタンをタップ");
            }
            break;
        }
        case 1:
        {
            NSLog(@"2つ目のボタンを選択しました。");
            if(alertView.tag == 1) {
                NSLog(@"OKボタンをタップ");
                // モーション計測の可否を確認
                BOOL check = [self confirmCMPedometer];
                if(check) {
                    // モーション計測の開始
                    [self startPedometer];
                }
                // ボタン画像の変更
                UIImage *img = [UIImage imageNamed:@"stop.png"];
                [self.measureBtn setBackgroundImage:img forState:UIControlStateNormal];
                self.measureFlag = YES;
            } else if(alertView.tag == 2) {
                NSLog(@"OKボタンをタップ");
                // モーション計測の停止
                [self stopPedometer];
                // ボタン画像の変更
                UIImage *img = [UIImage imageNamed:@"start.png"];
                [self.measureBtn setBackgroundImage:img forState:UIControlStateNormal];
                self.measureFlag = NO;
                // ラベルの変更
                self.stepLabel.text = @"Let's Walking";
            }
            break;
        }
        default:
            break;
    }
}

@end
