/*****************************************************************************
 *   ViewController.m
 ******************************************************************************
 *   by Kirill Kornyakov and Alexander Shishkov, 13th May 2013
 ******************************************************************************
 *   Chapter 10 of the "OpenCV for iOS" book
 *
 *   Capturing Video from Camera shows how to capture video
 *   stream from camera.
 *
 *   Copyright Packt Publishing 2013.
 *   http://bit.ly/OpenCV_for_iOS_book
 *****************************************************************************/

#import "ViewController.h"
#import "features.hpp"

@interface ViewController ()

@end

@implementation ViewController

@synthesize imageView;
@synthesize startCaptureButton;
@synthesize toolbar;
@synthesize videoCamera;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//gets corners right, just that the displayed image on phone is different dimensions, causing the correct coordinates appearing wrong.
    
    //imageView.image = [UIImage imageNamed:@"coverscene.jpg"];
    

    self.videoCamera = [[CvVideoCamera alloc]
                        initWithParentView:imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition =
                                AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset =
                                AVCaptureSessionPreset640x480;
    self.videoCamera.defaultAVCaptureVideoOrientation =
                                AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    
    self.videoCamera.grayscaleMode = NO;
    
    isCapturing = NO;
    
    //find all interest points for training image (CD cover)
    //will need to have separate methods in the .cpp file. as it includes windows and whatnot that the phone doesn't open.
    
    //thinking should use surf.cpp or main.cpp as these two examples came from video detection, the features.cpp takes two images at a time, which isn't what we want.
    
    //process image method is called --- every frame?? i guess
    
    //UIImage* obj = [UIImage imageNamed:@"object.png"];
    //UIImage* sce = [UIImage imageNamed:@"scene.png"];
    
    //detector();
}

- (NSInteger)supportedInterfaceOrientations
{
    // Only portrait orientation
    return UIInterfaceOrientationMaskPortrait;
}

-(IBAction)startCaptureButtonPressed:(id)sender
{
    [videoCamera start];
    isCapturing = YES;
    
}

-(IBAction)stopCaptureButtonPressed:(id)sender
{
    [videoCamera stop];
    isCapturing = NO;
    
    //show captured frame
    //imageView.image = capturedFrame;
    
}

- (void)processImage:(cv::Mat&)image
{
    
    //cv::Mat inputFrame = image;
    //NSLog(@"%d", image.size);
    
   // capturedFrame = [self UIImageFromCVMat:inputFrame];
   // NSLog(@"Frame");
    
    //cv::Mat finalFrame;
    
   // NSString* string = [NSString stringWithFormat:@"%s", "hello world"];
   // cv::putText(image, [string UTF8String], cv::Point(30, 100), cv::FONT_HERSHEY_COMPLEX_SMALL, 2, CV_RGB(255,255,0), 1, 8);
    
    cv::vector<cv::Point2f> corners = detector(image);
    
    
    //imageView.image = [UIImage imageNamed:@"scene.png"];
    
//    cv::Point tl(50,50);
//    cv::Point br(150,150);
    cv::Scalar box = cv::Scalar(0, 0, 0);
    cv::rectangle(image, corners[0], corners[2], box, 4, 8, 0);
    //finalFrame.copyTo(image);
    
    
    
    //send inputFrame to the other code or something :/ stuff.
    
    
    // Do some OpenCV processing with the image
    //Capute each frame and use it as the "scene" image :)
    
    //Psuedocode
    /*
     
     Load training image (CD Cover)
     Detect interest points of training image
     Extract interest point descriptors
     Initialize match object
     Initialize and open camera feed.
     While(feed active)
        capture frame
        detect interest points
        extract descriptors
        match query points with training points
        if(matching points > threshold
            Compute homography transform box
            draw box on object and display
        else continue
     
     */
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (isCapturing)
    {
        [videoCamera stop];
    }
}

- (void)dealloc
{
    videoCamera.delegate = nil;
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
 
    
    return cvMat;
}

- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
