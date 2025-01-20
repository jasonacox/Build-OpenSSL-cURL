//
//  ViewController.m
//  macOS Test App
//
//  Created by Jason Cox on 1/19/25.
//

#import "ViewController.h"

// Create private interface
@interface ViewController (Private)
- (size_t)copyUpToThisManyBytes:(size_t)bytes intoThisPointer:(void *)pointer;
- (void)displayText:(NSString *)text;
- (void)receivedData:(NSData *)data;
@end

// Function called by libcurl to deliver info/debug and payload data
int macOSCurlDebugCallback(CURL *curl, curl_infotype infotype, char *info, size_t infoLen, void *contextInfo) {
    ViewController *vc = (__bridge ViewController *)contextInfo;
    NSData *infoData = [NSData dataWithBytes:info length:infoLen];
    NSString *infoStr = [[NSString alloc] initWithData:infoData encoding:NSUTF8StringEncoding];
    if (infoStr) {
        infoStr = [infoStr stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];    // convert CR/LF to LF
        infoStr = [infoStr stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];    // convert CR to LF
        switch (infotype) {
            case CURLINFO_DATA_IN:
                [vc displayText:infoStr];
                break;
            case CURLINFO_DATA_OUT:
                [vc displayText:[infoStr stringByAppendingString:@"\n"]];
                break;
            case CURLINFO_HEADER_IN:
                [vc displayText:[@"" stringByAppendingString:infoStr]];
                break;
            case CURLINFO_HEADER_OUT:
                infoStr = [infoStr stringByReplacingOccurrencesOfString:@"\n" withString:@"\n>> "];
                [vc displayText:[NSString stringWithFormat:@">> %@\n", infoStr]];
                break;
            case CURLINFO_TEXT:
                [vc displayText:[@"-- " stringByAppendingString:infoStr]];
                break;
            default:    // ignore the other CURLINFOs
                break;
        }
    }
    return 0;
}

// Function called by libcurl to get data for uploads to web server
size_t macOSCurlReadCallback(void *ptr, size_t size, size_t nmemb, void *userdata) {
    const size_t sizeInBytes = size*nmemb;
    ViewController *vc = (__bridge ViewController *)userdata;
    
    return [vc copyUpToThisManyBytes:sizeInBytes intoThisPointer:ptr];
}

// Function called by libcurl to deliver packets from web response
size_t macOSCurlWriteCallback(char *ptr, size_t size, size_t nmemb, void *userdata) {
    const size_t sizeInBytes = size*nmemb;
    ViewController *vc = (__bridge ViewController *)userdata;
    NSData *data = [[NSData alloc] initWithBytes:ptr length:sizeInBytes];
    
    [vc receivedData:data];  // send to viewcontroller
    return sizeInBytes;
}

// Function called by libcurl to update progress
int macOSCurlProgressCallback(void *clientp, double dltotal, double dlnow, double ultotal, double ulnow) {
    // Placeholder - add progress bar?
    // NSLog(@"macOSCurlProgressCallback %f of %f", dlnow, dltotal);
    return 0;
}

//
// Private methods to display data
//

@implementation ViewController (Private)

- (size_t)copyUpToThisManyBytes:(size_t)bytes intoThisPointer:(void *)pointer
{
    size_t bytesToGo = _dataToSend.length-_dataToSendBookmark;
    size_t bytesToGet = MIN(bytes, bytesToGo);
    
    if (bytesToGo) {
        [_dataToSend getBytes:pointer range:NSMakeRange(_dataToSendBookmark, bytesToGet)];
        _dataToSendBookmark += bytesToGet;
        return bytesToGet;
    }
    return 0U;
}

// Transfer data from libcurl to view controller text box
- (void)displayText:(NSString *)text
{
    @autoreleasepool
    {
        _resultText.string = [_resultText.string stringByAppendingString:text];
        // allow run loop to run and do rendering while curl_easy_perform() hasn't returned yet
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}

- (void)receivedData:(NSData *)data
{
    [_dataReceived appendData:data];
}

@end

@implementation ViewController

@synthesize _resultText;
@synthesize _urlText;
@synthesize _appTitle;
@synthesize _getButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // CURL Setup
    if (self) {
        // _dataReceived = [[NSMutableData alloc] init];
        _curl = curl_easy_init();
    }
    
    // Display version and library info in view
    _resultText.string = [@"" stringByAppendingFormat:@"macOS cURL Test App v%@\n@jasonacox/Build-OpenSSL-cURL\n\nUsing: %s\n\n\n\n",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], curl_version()];
    
    // Set up display to allow user to scroll contents
    _resultText.selectable = YES;
    
}

// GET URL - display results interactively via textview
- (IBAction)Get:(id)sender
{
    _resultText.string = @""; // clear viewer

    // Give some render time to show response before we hit the network
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    // Verify URL
    if (!_urlText.stringValue || [_urlText.stringValue isEqualToString:@""]) {
        _urlText.stringValue = @"http://www.apple.com";  // no address provided, fill in default
    }
    
    if (_urlText.stringValue && ![_urlText.stringValue isEqualToString:@""]) {
        CURLcode theResult;
        NSURL *url = [NSURL URLWithString:_urlText.stringValue];
         [_dataReceived setLength:0U];
        _dataToSendBookmark = 0U;
        
        // Set CURL callback functions
        curl_easy_setopt(_curl, CURLOPT_DEBUGFUNCTION, macOSCurlDebugCallback);  // function to get debug data to view
        curl_easy_setopt(_curl, CURLOPT_DEBUGDATA, self);
        curl_easy_setopt(_curl, CURLOPT_WRITEFUNCTION, macOSCurlWriteCallback);  // function to get write data to view
        curl_easy_setopt(_curl, CURLOPT_WRITEDATA, self);    // prevent libcurl from writing the data to stdout
        curl_easy_setopt(_curl, CURLOPT_NOPROGRESS, 0L);
        curl_easy_setopt(_curl, CURLOPT_XFERINFOFUNCTION, macOSCurlProgressCallback);
        curl_easy_setopt(_curl, CURLOPT_PROGRESSDATA, self);  // libcurl will pass back dl data progress
        
        // Set some CURL options
        curl_easy_setopt(_curl, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);    // user/pass may be in URL
        curl_easy_setopt(_curl, CURLOPT_USERAGENT, curl_version());    // set a default user agent
        curl_easy_setopt(_curl, CURLOPT_VERBOSE, 1L);    // turn on verbose
        curl_easy_setopt(_curl, CURLOPT_TIMEOUT, 60L); // seconds
        curl_easy_setopt(_curl, CURLOPT_MAXCONNECTS, 0L); // this should disallow connection sharing
        curl_easy_setopt(_curl, CURLOPT_FORBID_REUSE, 1L); // enforce connection to be closed
        curl_easy_setopt(_curl, CURLOPT_DNS_CACHE_TIMEOUT, 0L); // Disable DNS cache
        curl_easy_setopt(_curl, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_2_0); // enable HTTP2 Protocol
        curl_easy_setopt(_curl, CURLOPT_SSLVERSION, CURL_SSLVERSION_DEFAULT); // Force TLSv1 protocol - Default
        curl_easy_setopt(_curl, CURLOPT_SSL_CIPHER_LIST, [@"ALL" UTF8String]);
        curl_easy_setopt(_curl, CURLOPT_SSL_VERIFYHOST, 0L);   // 1L to verify, 0L to disable
        curl_easy_setopt(_curl, CURLOPT_UPLOAD, 0L);
        curl_easy_setopt(_curl, CURLOPT_HTTPHEADER, NULL); // no headers sent
        curl_easy_setopt(_curl, CURLOPT_CUSTOMREQUEST,nil);
        curl_easy_setopt(_curl, CURLOPT_HTTPGET, 1L); // use HTTP GET method
        // CA root certs - loaded into project from libcurl http://curl.haxx.se/ca/cacert.pem
        cacertPath = [[NSBundle mainBundle] pathForResource:@"cacert" ofType:@"pem"];
        curl_easy_setopt(_curl, CURLOPT_CAINFO, [cacertPath UTF8String]); // set root CA certs
        

        // set URL
        curl_easy_setopt(_curl, CURLOPT_URL, url.absoluteString.UTF8String);

        // PERFORM the Curl
        theResult = curl_easy_perform(_curl);
        if (theResult == CURLE_OK) {
            long http_code, http_ver;
            double total_time, total_size, total_speed, timing_ns, timing_tcp, timing_ssl, timing_fb;
            char *redirect_url2 = NULL;
            curl_easy_getinfo(_curl, CURLINFO_RESPONSE_CODE, &http_code);
            curl_easy_getinfo(_curl, CURLINFO_TOTAL_TIME, &total_time);
            curl_easy_getinfo(_curl, CURLINFO_SIZE_DOWNLOAD_T, &total_size);
            curl_easy_getinfo(_curl, CURLINFO_SPEED_DOWNLOAD_T, &total_speed); // total
            curl_easy_getinfo(_curl, CURLINFO_APPCONNECT_TIME, &timing_ssl); // ssl handshake time
            curl_easy_getinfo(_curl, CURLINFO_CONNECT_TIME, &timing_tcp); // tcp connect
            curl_easy_getinfo(_curl, CURLINFO_NAMELOOKUP_TIME, &timing_ns); // name server lookup
            curl_easy_getinfo(_curl, CURLINFO_STARTTRANSFER_TIME, &timing_fb); // firstbyte
            curl_easy_getinfo(_curl, CURLINFO_REDIRECT_URL, &redirect_url2); // redirect URL
            curl_easy_getinfo(_curl, CURLINFO_HTTP_VERSION, &http_ver); // HTTP protocol
            
            NSString *http_ver_s, *http_h=@"";
            if(http_ver == CURL_HTTP_VERSION_1_0) {
                http_ver_s = @"HTTP/1.0";
                http_h = @"HTTP/1.0";
            }
            if(http_ver == CURL_HTTP_VERSION_1_1) {
                http_ver_s = @"HTTP/1.1";
                http_h = @"HTTP/1.1";
            }
            if(http_ver == CURL_HTTP_VERSION_2_0) {
                http_ver_s = @"HTTP/2";
                http_h = @"HTTP/2";
            }
            
            // timings
            _resultText.string = [_resultText.string stringByAppendingFormat:@"\n** Timing Details **\n-- \tName Lookup:\t%0.2fs\n-- \tTCP Connect: \t%0.2fs\n-- \tSSL Handshake: \t%0.2fs\n-- \tFirst Byte: \t\t%0.2fs\n-- \tTotal Download: \t%0.2fs\n-- Size: %0.0f bytes\n-- Speed: %0.0f bytes/sec\n-- Using: %@\n** RESULT CODE: %ld**",
                                timing_ns,timing_tcp,timing_ssl,timing_fb,
                                total_time,total_size, total_speed, http_ver_s, http_code];
        
        }
        else {
            _resultText.string = [_resultText.string stringByAppendingFormat:@"\n** TRANSFER INTERRUPTED - ERROR [%d]\n", theResult];

            if (theResult == 6) {
                _resultText.string = [_resultText.string stringByAppendingString:@"\n** Host Not Found - Check URL or Network\n"];
                
            }
        }
        
    } else {
        NSLog(@"ERROR: Invalid _urlText passed.");
    }
}

@end
