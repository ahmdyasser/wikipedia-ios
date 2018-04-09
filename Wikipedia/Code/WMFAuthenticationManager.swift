
/**
 *  This class provides a simple interface for performing authentication tasks.
 */
class WMFAuthenticationManager: NSObject {    
    fileprivate var keychainCredentials:WMFKeychainCredentials
    
    /**
     *  The current logged in user. If nil, no user is logged in
     */
    @objc dynamic private(set) var loggedInUsername: String? = nil {
        didSet {
            SessionSingleton.sharedInstance().dataStore.readingListsController.isLoggedIn = loggedInUsername == nil ? false : true
        }
    }
    
    /**
     *  Returns YES if a user is logged in, NO otherwise
     */
    @objc public var isLoggedIn: Bool {
        return (loggedInUsername != nil)
    }

    @objc public var hasKeychainCredentials: Bool {
        guard
            let userName = keychainCredentials.userName,
            userName.count > 0,
            let password = keychainCredentials.password,
            password.count > 0
            else {
                return false
        }
        return true
    }
    
    fileprivate let loginInfoFetcher = WMFAuthLoginInfoFetcher()
    fileprivate let tokenFetcher = WMFAuthTokenFetcher()
    fileprivate let accountLogin = WMFAccountLogin()
    fileprivate let currentlyLoggedInUserFetcher = WMFCurrentlyLoggedInUserFetcher()
    
    /**
     *  Get the shared instance of this class
     *
     *  @return The shared Authentication Manager
     */
    @objc public static let sharedInstance = WMFAuthenticationManager()    

    override private init() {
        keychainCredentials = WMFKeychainCredentials()
    }
    
    var loginSiteURL: URL {
        var baseURL: URL?
        if let host = self.keychainCredentials.host {
            var components = URLComponents()
            components.host = host
            components.scheme = "https"
            baseURL = components.url
        }
        
        if baseURL == nil {
//            #if DEBUG
//                let loginHost = "readinglists.wmflabs.org"
//                let loginScheme = "https"
//                var components = URLComponents()
//                components.host = loginHost
//                components.scheme = loginScheme
//                baseURL = components.url
//            #else
                baseURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL()
//            #endif
        }
        
        return baseURL!
    }
    
    /**
     *  Login with the given username and password
     *
     *  @param username The username to authenticate
     *  @param password The password for the user
     *  @param retypePassword The password used for confirming password changes. Optional.
     *  @param oathToken Two factor password required if user's account has 2FA enabled. Optional.
     *  @param success  The handler for success - at this point the user is logged in
     *  @param failure     The handler for any errors
     */
    @objc public func login(username: String, password:String, retypePassword:String?, oathToken:String?, captchaID: String?, captchaWord: String?, success loginSuccess:@escaping WMFAccountLoginResultBlock, failure:@escaping WMFErrorHandler){
        let siteURL = loginSiteURL
        self.tokenFetcher.fetchToken(ofType: .login, siteURL: siteURL, success: { tokenBlock in
            self.accountLogin.login(username: username, password: password, retypePassword: retypePassword, loginToken: tokenBlock.token, oathToken: oathToken, captchaID: captchaID, captchaWord: captchaWord, siteURL: siteURL, success: {result in
                let normalizedUserName = result.username
                self.loggedInUsername = normalizedUserName
                self.keychainCredentials.userName = normalizedUserName
                self.keychainCredentials.password = password
                self.keychainCredentials.host = siteURL.host
                self.cloneSessionCookies()
                SessionSingleton.sharedInstance()?.dataStore.clearMemoryCache()
                loginSuccess(result)
            }, failure: failure)
        }, failure:failure)
    }
    
    /**
     *  Logs in a user using saved credentials in the keychain
     *
     *  @param success  The handler for success - at this point the user is logged in
     *  @param userWasAlreadyLoggedIn     The handler called if a user was found to already be logged in
     *  @param failure     The handler for any errors
     */
    @objc public func loginWithSavedCredentials(success:@escaping WMFAccountLoginResultBlock, userAlreadyLoggedInHandler:@escaping WMFCurrentlyLoggedInUserBlock, failure:@escaping WMFErrorHandler){
        
        guard hasKeychainCredentials,
            let userName = keychainCredentials.userName,
            let password = keychainCredentials.password
        else {
            failure(WMFCurrentlyLoggedInUserFetcherError.blankUsernameOrPassword)
            return
        }
        
        let siteURL = loginSiteURL
        currentlyLoggedInUserFetcher.fetch(siteURL: siteURL, success: { result in
            self.loggedInUsername = result.name
            userAlreadyLoggedInHandler(result)
        }, failure:{ error in
            self.loggedInUsername = nil
            
            self.login(username: userName, password: password, retypePassword: nil, oathToken: nil, captchaID: nil, captchaWord: nil, success: success, failure: { error in
                if let error = error as? URLError {
                    if error.code != .notConnectedToInternet {
                        self.logout()
                    }
                }
                failure(error)
            })
        })
    }
    
    fileprivate var logoutManager:AFHTTPSessionManager?
    
    fileprivate func resetLocalUserLoginSettings() {
        self.keychainCredentials.userName = nil
        self.keychainCredentials.password = nil
        self.loggedInUsername = nil
        // Cookie reminders:
        //  - "HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)" does NOT seem to work.
        HTTPCookieStorage.shared.cookies?.forEach { cookie in
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
        SessionSingleton.sharedInstance()?.dataStore.clearMemoryCache()
        
        SessionSingleton.sharedInstance().dataStore.readingListsController.setSyncEnabled(false, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
        
        // Reset so can show for next logged in user.
        UserDefaults.wmf_userDefaults().wmf_setDidShowEnableReadingListSyncPanel(false)
    }
    
    /**
     *  Logs out any authenticated user and clears out any associated cookies
     */
    @objc public func logout(completion: @escaping () -> Void = {}){
        self.resetLocalUserLoginSettings()
        completion()
    }
    
    @objc public func deleteLoginTokensAndBrowserCookies() {
        logoutManager = AFHTTPSessionManager(baseURL: loginSiteURL)
        _ = logoutManager?.wmf_apiPOSTWithParameters(["action": "logout", "format": "json"], success: { (_, response) in
            DDLogInfo("Successfully logged out, deleted login tokens and other browser cookies")
            self.loginWithSavedCredentials(success: { (success) in
                DDLogInfo("Successfully logged in with saved credentials for user \(success.username)")
            }, userAlreadyLoggedInHandler: { (loggedIn) in
                DDLogInfo("User \(loggedIn.name) is already logged in")
            }, failure: { (error) in
                DDLogInfo("loginWithSavedCredentials failed with error \(error)")
            })
        }, failure: { (_, error) in
            DDLogInfo("Failed to log out, deleted login tokens and other browser cookies: \(error)")
        })
    }
    
    fileprivate func cloneSessionCookies() {
        // Make the session cookies expire at same time user cookies. Just remember they still can't be
        // necessarily assumed to be valid as the server may expire them, but at least make them last as
        // long as we can to lessen number of server requests. Uses user tokens as templates for copying
        // session tokens. See "recreateCookie:usingCookieAsTemplate:" for details.
        guard let domain = MWKLanguageLinkController.sharedInstance().appLanguage?.languageCode else {
            return
        }
        let cookie1Name = "\(domain)wikiSession"
        let cookie2Name = "\(domain)wikiUserID"
        HTTPCookieStorage.shared.wmf_recreateCookie(cookie1Name, usingCookieAsTemplate: cookie2Name)
        HTTPCookieStorage.shared.wmf_recreateCookie("centralauth_Session", usingCookieAsTemplate: "centralauth_User")
    }
}
