//
//  NodeThingsViewController.m
//  YodiwoNode
//
//  Created by r00tb00t on 7/31/15.
//  Copyright (c) 2015 yodiwo. All rights reserved.
//

#import "NodeThingsViewController.h"
#import "NodeController.h"
#import "NodeThingsRegistry.h"

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>


@interface NodeThingsViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *thingInVirtualSwitch;
@property (weak, nonatomic) IBOutlet UILabel *virtualTextLabel;

@property (weak, nonatomic) IBOutlet UILabel *userActivityLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceMotionLabel;
@property (weak, nonatomic) IBOutlet MKMapView *gpsLocationMapView;
@property (weak, nonatomic) IBOutlet UILabel *iBeacon1ProximityLevelLabel;
@property (weak, nonatomic) IBOutlet UILabel *iBeacon2ProximityLevelLabel;
@property (weak, nonatomic) IBOutlet UITextField *thingInVirtualTextInput;
@property (weak, nonatomic) IBOutlet UISlider *thingInVirtualSlider;
@property (weak, nonatomic) IBOutlet UIButton *thingOutVirtualLight1;
@property (weak, nonatomic) IBOutlet UIButton *thingOutVirtualLight2;
@end


@implementation NodeThingsViewController

///***** UI actions

- (IBAction)thingInVirtualSwitchValueChanged:(UISwitch *)sender
                                    forEvent:(UIEvent *)event {

    NSArray *array = [NSArray arrayWithObjects:(sender.on) ?
                      @"true" : @"false", nil];

    [[NodeController sharedNodeController] sendPortEventMsgFromThing:ThingNameVirtualSwitch
                                                            withData:array];
}

- (IBAction)thingInVirtualTextInputEditingDidEnd:(UITextField *)sender {

    NSArray *array = [NSArray arrayWithObjects:sender.text, nil];

    [[NodeController sharedNodeController] sendPortEventMsgFromThing:ThingNameVirtualTextInput
                                                            withData:array];


}

- (IBAction)thingInVirtualSliderValueChanged:(UISlider *)sender {

    NSArray *array = [NSArray arrayWithObjects:
                      [[NSNumber numberWithFloat:sender.value] stringValue], nil];

    [[NodeController sharedNodeController] sendPortEventMsgFromThing:ThingNameVirtualSlider
                                                            withData:array];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.thingInVirtualTextInput endEditing:YES];
}

//******************************************************************************





///***** Override synthesized getters, lazy instantiate


//******************************************************************************





///***** View related

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NodeController sharedNodeController] populateNodeThingsRegistry];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yodiwoConnectedToCloudServiceNotification:)
                                                 name:@"yodiwoConnectedToCloudServiceNotification"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yodiwoThingUpdateNotification:)
                                                 name:@"yodiwoThingUpdateNotification"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yodiwoUIUpdateNotification:)
                                                 name:@"yodiwoUIUpdateNotification"
                                               object:nil];

    // Initialize UI stuff
    self.gpsLocationMapView.mapType = MKMapTypeStandard;
    self.gpsLocationMapView.zoomEnabled = NO;
    self.gpsLocationMapView.scrollEnabled = NO;

    [[NodeController sharedNodeController] connectToCloudService];
}

// For UIEvent motion monitoring
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [self becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated {

}

- (void)viewWillAppear:(BOOL)animated {

}

- (void)viewWillDisappear:(BOOL)animated {

}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

}

// Shake detection
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake)
    {
        // Notify cloud service
        NSArray *data = [NSArray arrayWithObjects:@"true", nil];
        [[NodeController sharedNodeController]
         sendPortEventMsgFromThing:ThingNameShakeDetector withData:data];

        // Notify interested UIViewController
        NSDictionary *notParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                   ThingNameShakeDetector, @"thingName",
                                   [NSNumber numberWithBool:YES], @"hasShaken",
                                   nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"yodiwoUIUpdateNotification"
                                                            object:self
                                                          userInfo:notParams];
    }
}

//******************************************************************************





///***** Memory

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//******************************************************************************





///***** Observers

- (void)yodiwoConnectedToCloudServiceNotification:(NSNotification *)notification {

    // Start location manager module
    [[NodeController sharedNodeController] startLocationManagerModule];

    // Start motion manager module
    [[NodeController sharedNodeController] startMotionManagerModule];

    // Shoulder-tap cloud service and introduce this node
    [[NodeController sharedNodeController] sendNodeThingsMsg];
}

- (void)yodiwoThingUpdateNotification:(NSNotification *)notification {

    // Get notification parameters
    NSDictionary *notParams = [notification userInfo];

    NSString *thingName = [notParams objectForKey:@"thingName"];
    NSNumber *portIndex = [notParams objectForKey:@"portIndex"];
    NSString *newState = [notParams objectForKey:@"newState"];

    if ([thingName isEqualToString:ThingNameVirtualText]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.virtualTextLabel.text = newState;
        });
    }
    else if ([thingName isEqualToString:ThingNameVirtualLight1]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([newState boolValue]) {
                self.thingOutVirtualLight1.backgroundColor = [UIColor whiteColor];
                [self.thingOutVirtualLight1 setTitle:@"On" forState:UIControlStateNormal];
            }
            else {
                self.thingOutVirtualLight1.backgroundColor = [UIColor blackColor];
                [self.thingOutVirtualLight1 setTitle:@"Off" forState:UIControlStateNormal];
            }
        });
    }
    else if ([thingName isEqualToString:ThingNameVirtualLight2]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([newState boolValue]) {
                self.thingOutVirtualLight2.backgroundColor = [UIColor whiteColor];
                [self.thingOutVirtualLight2 setTitle:@"On" forState:UIControlStateNormal];
            }
            else {
                self.thingOutVirtualLight2.backgroundColor = [UIColor blackColor];
                [self.thingOutVirtualLight2 setTitle:@"Off" forState:UIControlStateNormal];
            }
        });
    }
    else {
        NSLog(@"****** Received yodiwoThingUpdateNotification for unknown thing *******");
    }
}

- (void)yodiwoUIUpdateNotification:(NSNotification *)notification {

    // Get notification parameters
    NSDictionary *notParams = [notification userInfo];
    NSString *thingName = [notParams objectForKey:@"thingName"];

    if ([thingName isEqualToString:ThingNameLocationGPS]) {
        // Region
        float spanX = 0.005;
        float spanY = 0.005;
        MKCoordinateRegion region;
        region.center.latitude = self.gpsLocationMapView.userLocation.coordinate.latitude;
        region.center.longitude = self.gpsLocationMapView.userLocation.coordinate.longitude;
        region.span.latitudeDelta = spanX;
        region.span.longitudeDelta = spanY;

        // Annotation
        MKPointAnnotation *ant = [[MKPointAnnotation alloc] init];
        ant.coordinate = [[notParams objectForKey:@"location"] coordinate];
        ant.title = @"Node location";
        ant.subtitle = [notParams objectForKey:@"locationFriendly"];

        dispatch_async(dispatch_get_main_queue(), ^{
            ant.title = @"Node location";
            [self.gpsLocationMapView setRegion:region animated:YES];
            [self.gpsLocationMapView setCenterCoordinate:ant.coordinate animated:YES];
            [self.gpsLocationMapView addAnnotation:ant];
        });
    }
    else if ([thingName isEqualToString:ThingNameLocationBeacon]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.iBeacon1ProximityLevelLabel.text = [notParams objectForKey:@"proximity"];
        });
    }
    else if ([thingName isEqualToString:ThingNameShakeDetector]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.deviceMotionLabel.text =
                [[notParams objectForKey:@"hasShaken"] boolValue] ? @"Device has shaken" : @"";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
                           dispatch_get_main_queue(), ^{
                self.deviceMotionLabel.text = @"";
                           });
        });
    }
    else if ([thingName isEqualToString:ThingNameActivityTracker]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.userActivityLabel.text = [notParams objectForKey:@"activity"];
        });
    }
    else {
        NSLog(@"****** Received yodiwoUIUpdateNotification for unknown thing *******");
    }
}

//******************************************************************************

@end
