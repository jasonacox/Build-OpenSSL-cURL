//
//  ViewController.h
//  iOS Test App
//
//  Created by Jason A. Cox on 11/19/16.
//
//  COPYRIGHT AND PERMISSION NOTICE
//
//  Copyright (c) 2014-2020 Jason A. Cox, jasonacox@me.com, and many contributors,
//  see the THANKS file.
//
//  All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//


#import <UIKit/UIKit.h>
#import <curl/curl.h>
#import <openssl/ssl.h>

@interface ViewController : UIViewController
{
    IBOutlet UITextField *_urlText;         // user field for URL address
    IBOutlet UITextView *_resultText;       // user field for resulting cURL data
    IBOutlet UIButton *_getButton;          // user button to start GET
    IBOutlet UILabel *_appTitle;            // application title to update for version
    
    // CURL global data
    CURL *_curl;                            // curl handle
    NSData *_dataToSend;
    size_t _dataToSendBookmark;
    NSMutableData *_dataReceived;
}

@property (retain, nonatomic) UITextField *_urlText;
@property (retain, nonatomic) UITextView *_resultText;
@property (retain, nonatomic) UIButton *_getButton;
@property (retain, nonatomic) UILabel *_appTitle;

- (IBAction)Get: (id)sender;                // action method to run GET 

@end

