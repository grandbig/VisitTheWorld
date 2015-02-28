//
//  ReportViewController.m
//  VisitTheWorld
//
//  Created by 加藤 雄大 on 2015/02/22.
//  Copyright (c) 2015年 grandbig.github.io. All rights reserved.
//

#import "ReportViewController.h"
#import <MapKit/MapKit.h>
#import <LFHeatMap.h>
#import "FMDatabase.h"
#import "SqliteMethod.h"

static NSString *dbName = @"visit.db";
static NSString *placeTable = @"place";
static NSString *motionTable = @"motion";

@interface ReportViewController()

/// Mapオブジェクト
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
/// Sliderオブジェクト
@property (weak, nonatomic) IBOutlet UISlider *slider;
/// 位置情報格納オブジェクト
@property (strong, nonatomic) NSArray *locations, *weights;
/// UIImageViewオブジェクト
@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation ReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 端末のplaceテーブルから情報を取得
    self.locations = [self selectPlaceData];
    NSInteger cnt = [self.locations count];
    self.weights = [self createWeightData:cnt];
    
    MKCoordinateSpan span = MKCoordinateSpanMake(10.0, 13.0);
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(35.662795405456, 139.7613909697);
    self.mapView.region = MKCoordinateRegionMake(center, span);
    
    // MapにUIImageViewを追加
    self.imageView = [[UIImageView alloc] initWithFrame:self.mapView.frame];
    self.imageView.contentMode = UIViewContentModeCenter;
    [self.view addSubview:self.imageView];
    
    // ヒートマップの初期化
    [self sliderChanged:self.slider];
}

- (void)viewWillAppear:(BOOL)animated {
    self.mapView.showsUserLocation = YES;
    //[self.mapView setUserTrackingMode:MKUserTrackingModeFollow];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 端末内部のplaceテーブルから取得した位置情報を格納した配列を返却する処理
 @return 位置情報を格納した配列
 */
- (NSArray *)selectPlaceData
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    SqliteMethod *sm = [[SqliteMethod alloc] init];
    FMDatabase *db = [sm dbConnect:dbName];
    
    NSString *sql = [[NSString alloc] initWithFormat:@"select lat, lng from %@", placeTable];
    
    [db open];
    FMResultSet *rs = [db executeQuery:sql];
    while([rs next]) {
        CLLocationDegrees lat = [[rs stringForColumnIndex: 1] doubleValue];
        CLLocationDegrees lng = [[rs stringForColumnIndex: 2] doubleValue];
        CLLocation *location = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
        [array addObject:location];
    }
    
    return array;
}

- (NSArray *)createWeightData:(NSInteger)cnt
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for(NSInteger i=0; i < cnt; i++) {
        NSNumber *magnitude = [[NSNumber alloc] initWithInteger:10];
        [array addObject:magnitude];
    }
    
    return array;
}

/**
 UISliderの値を変更した場合に呼び出される処理
 @param slider UISliderオブジェクト
 @return アクション
 */
- (IBAction)sliderChanged:(UISlider *)slider {
    // Sliderのvalue
    float boost = slider.value;
    // ヒートマップ画像の設定
    UIImage *heatmap = [LFHeatMap heatMapForMapView:self.mapView boost:boost locations:self.locations weights:self.weights];
    // ヒートマップ画像をUIImageViewに格納
    self.imageView.image = heatmap;
}

@end
