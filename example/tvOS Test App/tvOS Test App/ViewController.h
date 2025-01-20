//
//  ViewController.h
//  tvOS Test App
//
//  Created by Jason Cox on 1/19/25.
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
    NSString *cacertPath;                   // path to cacert.pem file
}

@property (retain, nonatomic) UITextField *_urlText;
@property (retain, nonatomic) UITextView *_resultText;
@property (retain, nonatomic) UIButton *_getButton;
@property (retain, nonatomic) UILabel *_appTitle;

- (IBAction)Get: (id)sender;                // action method to run GET

@end


