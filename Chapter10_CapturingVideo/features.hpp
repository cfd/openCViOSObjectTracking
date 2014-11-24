//
//  features.hpp
//  Chapter10_CapturingVideo
//
//  Created by Chris on 13/10/2014.
//  Copyright (c) 2014 Alexander Shishkov & Kirill Kornyakov. All rights reserved.
//

#ifndef Chapter10_CapturingVideo_features_hpp
#define Chapter10_CapturingVideo_features_hpp

bool setup(NSString* filename);
cv::vector<cv::Point2f> detect(cv::Mat img_scene);


#endif
