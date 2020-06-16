//
//  OpencvController.m
//  Autofarmer
//
//  Created by vuquangnam on 6/5/20.
//  Copyright © 2020 vuquangnam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/imgproc.hpp>
#import <opencv2/highgui.hpp>
#import <opencv2/shape.hpp>
#import <iostream>

using namespace std;
using namespace cv;

vector<Point> simpleContour(const Mat& currentQuery, int n = 300)
{
    vector<vector<Point> > _contoursQuery;
    vector <Point> contoursQuery;
    findContours(currentQuery, _contoursQuery, RETR_LIST, CHAIN_APPROX_NONE);
    for (size_t border = 0; border < _contoursQuery.size(); border++)
    {
        for (size_t p = 0; p < _contoursQuery[border].size(); p++)
        {
            contoursQuery.push_back(_contoursQuery[border][p]);
        }
    }

    // In case actual number of points is less than n
    int dummy = 0;
    for (int add = (int)contoursQuery.size() - 1; add < n; add++)
    {
        contoursQuery.push_back(contoursQuery[dummy++]); //adding dummy values
    }

    // Uniformly sampling
    cv::randShuffle(contoursQuery);
    vector<Point> cont;
    for (int i = 0; i < n; i++)
    {
        cont.push_back(contoursQuery[i]);
    }
    return cont;
}

vector<Point> getContourShape(cv::Mat src_bin) {
    vector<Point> cont = simpleContour(src_bin);

    return cont;
}

cv::Mat binaryPattern(cv::Mat src) {
    cv::Mat src_gray;
    cv::cvtColor(src, src_gray, CV_BGR2GRAY);

    cv::Mat src_bin;
    cv::adaptiveThreshold(src_gray, src_bin, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY_INV, 7, 9);

    return src_bin;
}

vector<Point> getContourPattern(cv::Mat src_bin) {
    vector<vector<Point> > contours;
    vector<Vec4i> hierarchy;
    findContours(src_bin, contours, hierarchy, RETR_LIST, CV_CHAIN_APPROX_NONE, Point(0, 0));

    vector<Rect> boundRect(contours.size());
    for (size_t i = 0; i < contours.size(); i++)
    {
        boundRect[i] = boundingRect(contours[i]);
    }

    double max_area = 0.0;
    cv::Rect rect;
    vector<Point> cont;
    for (size_t i = 0; i < contours.size(); i++)
    {
        if (boundRect[i].area() > max_area) {
            max_area = boundRect[i].area();
            rect = boundRect[i];
            cont = contours.at(i);
        }
    }

    return cont;
}

cv::Point getCenter(cv::Rect box) {
    cv::Point center = cv::Point(box.x + box.width * 0.5, box.y + box.height * 0.5);

    return center;
}

int main(int argc, char* argv[])
{
    std::string file_path = "C:/Users/THANH DAT/source/repos/opencv/opencv/ButtonDetection/facebooklike/facebooklike13.jpg";
    //std::cin >> file_path;

    cv::Ptr <cv::ShapeContextDistanceExtractor> mysc = cv::createShapeContextDistanceExtractor();

    cv::Mat like_icon = cv::imread("C:/Users/THANH DAT/source/repos/opencv/opencv/pattern/like-icon.jpg");
    cv::Mat like_bin = binaryPattern(like_icon);

    cv::Mat share_icon = cv::imread("C:/Users/THANH DAT/source/repos/opencv/opencv/pattern/share-icon.jpg");
    cv::Mat share_bin = binaryPattern(share_icon);

    cv::Mat src = cv::imread(file_path.c_str());
    double dis_min_define = 2.3;

    vector<Point> like_cont = getContourPattern(like_bin);
    vector<Point> like_cont_shape = getContourShape(like_bin);
    vector<Point> share_cont = getContourPattern(share_bin);
    float dis = mysc->computeDistance(like_cont_shape, like_cont_shape);

    double t1 = cv::getTickCount();

    cv::Mat src_gray;
    cv::cvtColor(src, src_gray, CV_BGR2GRAY);

    cv::Mat src_bin;
    cv::adaptiveThreshold(src_gray, src_bin, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY_INV, 11, 12);

    vector<vector<Point> > contours;
    vector<Vec4i> hierarchy;
    findContours(src_bin, contours, hierarchy, RETR_CCOMP, CV_CHAIN_APPROX_NONE, Point(0, 0));

    vector<Rect> boundRect(contours.size());
    for (size_t i = 0; i < contours.size(); i++)
    {
        boundRect[i] = boundingRect(contours[i]);
    }

    for (int i = (int)boundRect.size() - 1; i >= 0; i--)
    {
        cv::Rect rect = boundRect.at(i);
        if (rect.x < 5 ||
            rect.y < 5 ||
            (rect.x + rect.width) >(src.cols - 5) ||
            (rect.y + rect.height) >(src.rows - 5) ||
            rect.height > 70 ||
            rect.width > 70 ||
            rect.width < 5 ||
            rect.height < 10)
        {
            boundRect.erase(boundRect.begin() + i);
            contours.erase(contours.begin() + i);
            continue;
        }
    }

    vector<vector<Point> > conts;
    std::vector<cv::Rect> rects;
    for (int i = 0; i < (int)boundRect.size(); i++) {
        cv::Rect a = boundRect.at(i);
        int count = 0;
        int count2 = 0;
        for (int j = 0; j < (int)boundRect.size(); j++) {
            if (i == j) {
                continue;
            }

            cv::Rect b = boundRect.at(j);
            if ((a & b) == b) {
                count += 1;
                if (b.area() <= 0.7 * a.area()) {
                    count2 += 1;
                }
            }
        }

        if (count == 2 && count2 == 2) {
            rects.push_back(a);
            conts.push_back(contours.at(i));
        }
    }

    // find like button
    std::vector<double> lsdis;
    double dis_min = 10000;
    int idx = 0;
    for (size_t i = 0; i < conts.size(); i++)
    {
        double ans = matchShapes(like_cont, conts.at(i), CV_CONTOURS_MATCH_I1, 0);
        if (ans <= dis_min) {
            dis_min = ans;
            idx = i;
        }
        lsdis.push_back(ans);
    }

    // sort box by diss
    for (int i = 0; i < (int)lsdis.size(); i++) {
        for (int j = (i + 1); j < (int)lsdis.size(); j++) {
            if (lsdis.at(i) > lsdis.at(j)) {
                double tmp = lsdis.at(i);
                lsdis.at(i) = lsdis.at(j);
                lsdis.at(j) = tmp;

                cv::Rect rtmp = rects.at(i);
                rects.at(i) = rects.at(j);
                rects.at(j) = rtmp;

                std::vector<cv::Point> rPts = conts.at(i);
                conts.at(i) = conts.at(j);
                conts.at(j) = rPts;
            }
        }
    }

    bool chk = false;
    for (int i = 0; i < (int)lsdis.size(); i++) {
        if (lsdis.at(i) >= 0.03) {
            break;
        }

        cv::Rect rect = rects.at(i);
        rect.x -= 4;
        rect.y -= 4;
        rect.width += 8;
        rect.height += 8;
        cv::Mat cropI = src_bin(rect);
        cv::resize(cropI, cropI, cv::Size(like_icon.cols, like_icon.rows));
        vector<Point> cont_shape = getContourShape(cropI);

        dis = mysc->computeDistance(like_cont_shape, cont_shape);
        if (dis < dis_min_define) {
            chk = true;
            std::cout << dis << std::endl;
            dis_min = lsdis.at(i);
            break;
        }
    }

    std::vector<cv::Rect> like_boxs;
    if (chk) {
        for (int i = 0; i < lsdis.size(); i++)
        {
            if (abs(lsdis.at(i) - dis_min) < 0.0001) {
                like_boxs.push_back(rects.at(i));
            }
        }
    }

    if (like_boxs.size() <= 0) {
        double t2 = cv::getTickCount();
        double takaze = 1000.0 * (t2 - t1) / cv::getTickFrequency();
        std::cout << "Time (ms):      \t" << takaze << endl;
        getchar();

        return 0;
    }

    // find share button
    std::vector<cv::Rect> share_boxs;
    for (size_t i = 0; i < like_boxs.size(); i++)
    {
        cv::Rect like_box = like_boxs.at(i);

        std::vector<cv::Rect> tmps;
        for (size_t j = 0; j < boundRect.size(); j++)
        {
            cv::Point center = getCenter(boundRect.at(j));

            // check like button
            if (like_box.contains(center)) {
                continue;
            }

            if (center.y > like_box.tl().y && center.y < like_box.br().y) {
                double tmp = matchShapes(share_cont, contours[j], CV_CONTOURS_MATCH_I1, 0);
                if (tmp < 0.09) {
                    share_boxs.push_back(boundRect.at(j));
                }
            }
        }
    }

    // find comment box button
    std::vector<cv::Rect> cmt_boxs;
    for (size_t i = 0; i < like_boxs.size(); i++)
    {
        cv::Rect like_box = like_boxs.at(i);
        cv::Point center_like = getCenter(like_box);

        std::vector<cv::Rect> tmps;
        for (size_t j = 0; j < boundRect.size(); j++)
        {
            cv::Rect rect = boundRect.at(j);
            cv::Point center = getCenter(rect);

            double res = cv::norm(center - center_like);//Euclidian distance
            if (res > 350) {
                continue;
            }

            // check like button
            if (like_box.contains(center)) {
                continue;
            }

            // check share button
            bool chk = false;
            for (int k = 0; k < (int)share_boxs.size(); k++) {
                cv::Rect share_box = share_boxs.at(k);
                if (share_box.contains(center)) {
                    chk = true;
                    break;
                }
            }

            if (chk) {
                continue;
            }

            if (center.y > like_box.tl().y && center.y < like_box.br().y) {
                tmps.push_back(rect);
            }
        }

        if (tmps.size() > 0) {
            cv::Rect rect;
            int height_max = 0;
            for (int j = 0; j < (int)tmps.size(); j++) {
                if (tmps.at(j).height >= height_max) {
                    height_max = tmps.at(j).height;
                    rect = tmps.at(j);
                }
            }
            cmt_boxs.push_back(rect);
        }
    }

    double t2 = cv::getTickCount();
    double takaze = 1000.0 * (t2 - t1) / cv::getTickFrequency();
    std::cout << "Time (ms):      \t" << takaze << endl;

    //for (int i = 0; i < (int)boundRect.size(); i++) {
    //    putText(src, std::to_string(i), boundRect.at(i).tl(), FONT_HERSHEY_PLAIN, 2, Scalar(0, 0, 255, 255));
    //}

    for (int i = 0; i < (int)like_boxs.size(); i++) {
        rectangle(src, like_boxs.at(i).tl(), like_boxs.at(i).br(), cv::Scalar(255, 0, 0), 1);
    }

    for (int i = 0; i < (int)cmt_boxs.size(); i++) {
        rectangle(src, cmt_boxs.at(i).tl(), cmt_boxs.at(i).br(), cv::Scalar(0, 255, 0), 1);
    }

    for (int i = 0; i < (int)share_boxs.size(); i++) {
        rectangle(src, share_boxs.at(i).tl(), share_boxs.at(i).br(), cv::Scalar(0, 0, 255), 1);
    }

    cv::resize(src, src, cv::Size(), 0.4, 0.4);
    cv::imwrite("src.jpg", src);
    //cv::imshow("src_bin", src_bin);
    cv::imshow("src", src);
    cv::waitKey(0);

    return 0;
}



