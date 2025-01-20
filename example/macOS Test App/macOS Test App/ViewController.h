//
//  ViewController.h
//  macOS Test App
//
//  Created by Jason Cox on 1/19/25.
//

#import <Cocoa/Cocoa.h>
#import <curl/curl.h>
#import <openssl/ssl.h>

@interface ViewController : NSViewController
{
    IBOutlet NSTextField *_urlText;         // user field for URL address
    IBOutlet NSTextView *_resultText;      // user field for resulting cURL data
    IBOutlet NSButton *_getButton;          // user button to start GET
    IBOutlet NSTextField *_appTitle;        // application title to update for version
    
    // CURL global data
    CURL *_curl;                            // curl handle
    NSData *_dataToSend;
    size_t _dataToSendBookmark;
    NSMutableData *_dataReceived;
    NSString *cacertPath;                   // path to cacert.pem file
}

@property (retain, nonatomic) NSTextField *_urlText;
@property (retain, nonatomic) NSTextView *_resultText;
@property (retain, nonatomic) NSButton *_getButton;
@property (retain, nonatomic) NSTextField *_appTitle;

- (IBAction)Get: (id)sender;                // action method to run GET

@end

