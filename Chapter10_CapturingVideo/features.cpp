#include <stdio.h>
#include <iostream>
#include "opencv2/core/core.hpp"
#include "opencv2/features2d/features2d.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/calib3d/calib3d.hpp"
#include "opencv2/nonfree/nonfree.hpp"

using namespace cv;

void readme();

Mat img_object;
Mat img_scene;
int minHessian = 400;
SurfFeatureDetector detector(minHessian);
std::vector<KeyPoint> keypoints_object, keypoints_scene;
SurfDescriptorExtractor extractor;
Mat descriptors_object, descriptors_scene;




bool setup(NSString* filename)
{
    printf("setup called");
    NSArray* parts = [filename componentsSeparatedByString:@"."];
    NSString* path = [[NSBundle mainBundle] pathForResource:[parts objectAtIndex:0] ofType:[parts objectAtIndex:1]];
        img_object = imread([path UTF8String], CV_LOAD_IMAGE_GRAYSCALE);

    if( !img_object.data) {
        std::cout<< " --(!) Error reading images " << std::endl;
        return false;
    }

    
    //-- Step 1: Detect the keypoints using SURF Detector
    detector.detect( img_object, keypoints_object );
    
    //-- Step 2: Calculate descriptors (feature vectors)
    extractor.compute( img_object, keypoints_object, descriptors_object );

    return true;
    
}





vector<Point2f> detect(Mat img_scene)
{

    if( !img_object.data || !img_scene.data )
        { std::cout<< " --(!) Error reading images " << std::endl;
            std::vector<Point2f> failed(4);
            return failed;
        }
    detector.detect( img_scene, keypoints_scene );
    extractor.compute( img_scene, keypoints_scene, descriptors_scene );
    
    
    
    
    //-- Step 3: Matching descriptor vectors using FLANN matcher
    FlannBasedMatcher matcher;
    std::vector< DMatch > matches;
    try {
        matcher.match( descriptors_object, descriptors_scene, matches );
    } catch (cv::Exception) {
        std::vector<Point2f> failed(4);
        return failed;
    }
    
    
    double max_dist = 0; double min_dist = 100;
    
    //-- Quick calculation of max and min distances between keypoints
    for( int i = 0; i < descriptors_object.rows; i++ )
    { double dist = matches[i].distance;
        if( dist < min_dist ) min_dist = dist;
        if( dist > max_dist ) max_dist = dist;
    }
    
    printf("-- Max dist : %f \n", max_dist );
    printf("-- Min dist : %f \n", min_dist );
    
    //-- Draw only "good" matches (i.e. whose distance is less than 3*min_dist )
    std::vector< DMatch > good_matches;
    
    for( int i = 0; i < descriptors_object.rows; i++ )
    { if( matches[i].distance < 3*min_dist )
    { good_matches.push_back( matches[i]); }
    }
    
    Mat img_matches;
    drawMatches( img_object, keypoints_object, img_scene, keypoints_scene,
                good_matches, img_matches, Scalar::all(-1), Scalar::all(-1),
                vector<char>(), DrawMatchesFlags::NOT_DRAW_SINGLE_POINTS );
    
    //-- Localize the object
    std::vector<Point2f> object;
    std::vector<Point2f> scene;
    
    for( int i = 0; i < good_matches.size(); i++ )
    {
        //-- Get the keypoints from the good matches
        object.push_back( keypoints_object[ good_matches[i].queryIdx ].pt );
        scene.push_back( keypoints_scene[ good_matches[i].trainIdx ].pt );
    }

    printf("Number of interst points: %lu", keypoints_object.size());
    
    try {
       Mat H = findHomography(object, scene, CV_RANSAC );
    
    
    //-- Get the corners from the image_1 ( the object to be "detected" )
    std::vector<Point2f> obj_corners(4);
    obj_corners[0] = cvPoint(0,0);
    obj_corners[1] = cvPoint( img_object.cols, 0 );
    obj_corners[2] = cvPoint( img_object.cols, img_object.rows );
    obj_corners[3] = cvPoint( 0, img_object.rows );
    std::vector<Point2f> scene_corners(4);
    
    perspectiveTransform( obj_corners, scene_corners, H);
    
    printf("\ncorners:\n");
    printf("%f,%f\n", scene_corners[0].x, scene_corners[0].y);
    printf("%f,%f\n", scene_corners[1].x, scene_corners[1].y);
    printf("%f,%f\n", scene_corners[2].x, scene_corners[2].y);
    printf("%f,%f\n", scene_corners[3].x, scene_corners[3].y);

        
    return scene_corners;
        
    } catch (cv::Exception) {
        std::vector<Point2f> failed(4);
        return failed;
    }
}



/** @function readme */
void readme()
{ std::cout << " Usage: ./SURF_descriptor <img1> <img2>" << std::endl; }