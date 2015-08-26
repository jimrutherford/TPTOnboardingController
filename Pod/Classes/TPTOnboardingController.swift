//
//  TPTFirstTime.swift
//  WorkRestRepeat
//
//  Created by Jim Rutherford on 2015-04-15.
//  Copyright (c) 2015 Taptonics. All rights reserved.
//

private let _ClassSharedInstance = TPTOnboardingController()

public class TPTOnboardingController:NSObject {
    
    let onboardingGroup = "onboardingGroup"
    
    var onboardingDictionary:NSMutableDictionary? = NSMutableDictionary()
    
    public class var sharedInstance: TPTOnboardingController {
        return _ClassSharedInstance
    }
    
    override init()
    {
        super.init()
        onboardingDictionary = loadDictionaryFromUserDefaults()
    }
    
    
    // MARK: Public Methods
    
    /*!
    *  @brief  Execute a closure only once.
    *  @param  closure  The closure to be executed.
    *  @param  forKey   The unique name of the closure.
    */
    public func executeOnce(closure:(()-> ())?, forKey key:String)
    {       
        executeOnce(closure, executeOtherTimes:nil, forKey:key, perVersion:false, everyXDays:0)
    }
    
    
    /*!
    *  @brief  Execute a closure only once.
    *  @param  closure              The closure to be executed only once.
    *  @param  closuerOtherTimes    The closure to be executed always.
    *  @param  forKey               The unique name of the closure.
    */
    public func executeOnce (closure:(()-> ())?, executeOtherTimes closureOtherTimes:(()-> ())?, forKey key:String)
    {
        executeOnce(closure, executeOtherTimes:closureOtherTimes, forKey:key, perVersion:false, everyXDays:0)
    }
    

    /*!
    *  @brief  Execute a closure only once per version.
    *  @param  closure            The closure to be executed only once.
    *  @param  forKey             The unique name of the closure.
    */
    public func executeOncePerVersion(closure:(()-> ())?, forKey key:String)
    {
        executeOnce(closure, executeOtherTimes:nil, forKey:key, perVersion:true, everyXDays:0)
    }
    
    /*!
    *  @brief  Execute a closure only once per version.
    *  @param  closure            The closure to be executed only once.
    *  @param  closureOtherTimes  The closure to be executed always.
    *  @param  forKey             The unique name of the closure.
    */
    public func executeOncePerVersion(closure:(()-> ())?, executeOtherTimes closureOtherTimes:(()-> ())?, forKey key:String)
    {
        executeOnce(closure, executeOtherTimes:closureOtherTimes, forKey:key, perVersion:true, everyXDays:0)
    }
    
    /*!
    *  @brief  Execute a block only once.
    *  @param  closure            The closure to be executed only once.
    *  @param  forKey             The unique name of the closure.
    *  @param  days                 The number of days that the code should be executed again.
    */
    public func executeOncePerInterval(closure:(()-> ())?, forKey key:String, withDaysInterval days:CGFloat)
    {
        executeOnce(closure, executeOtherTimes:nil, forKey:key, perVersion:false, everyXDays:days)
    }
    
    
    /*!
    *  @brief  Execute a closure only once.
    *  @param  closure            The closure to be executed only once.
    *  @param  closureOtherTimes  The closure to be executed always.
    *  @param  forKey             The unique name of the closure.
    *  @param  perVersion       Execute this closure every new version.
    */
    public func executeOnce(closure:(()-> ())?, executeOtherTimes closureOtherTimes:(()-> ())?, forKey key:String, perVersion:Bool, everyXDays days:CGFloat)
    {
        /// Check if the closure was executed already.
        if closureAlreadyExecutedForKey(key, perVersion:perVersion, everyXDays:days) {
            
            /// Execute the closureOtherTimes from the second time on.
            if let unwrappedClosureOtherTimes = closureOtherTimes {
                unwrappedClosureOtherTimes()
            }
            
        } else {
            
            /// If there is a valid closure.
            if let unwrappedClosure = closure {
                
                /// Execute closure.
                unwrappedClosure()
                
                /// Save execution information.
                saveExecutionInformationForKey(key)
            }
        }
    }

    /*!
    *  @brief  Check if a closure was executed already.
    *  @param key     The unique name of the closure.
    *  @param perVersion If the closure should be executed every new version or not.
    *  @return a boolean if the closure was executed or not.
    */
    func closureAlreadyExecutedForKey(key:String, perVersion:Bool, everyXDays days:CGFloat) -> Bool
    {
        /// Boolean for executed closures.
        var executed = false
        
        /// Get the key dictionary.
        let closureInfo = getInfoForClosure(key)
        if closureInfo != nil
        {
            /// Boolean for executed closures.
            executed = true
        }
        
        /// Version.
        if perVersion && closureInfo != nil
        {
            let currentVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
            executed = executed && currentVersion == closureInfo!.lastVersion
        }
        
        /// Every X days.
        if (days > 0 && closureInfo != nil) {
            let interval:NSTimeInterval = NSDate().timeIntervalSinceDate(closureInfo!.lastTime)
            
            let differenceInDays = interval / 84600.0
            executed = executed && (CGFloat(differenceInDays) < days)
        }
        
        return executed
    }
    
    
    /*!
    *  @brief  Saves the execution of a closure. It saves on the disk to post check.
    *  @param  key The unique name of the closure.
    */
    func saveExecutionInformationForKey(key:String)
    {
        var closureInfo = getInfoForClosure(key)
        
        if closureInfo == nil
        {
            closureInfo = TPTOnboardingVO()
        }
        
        /// Set the version.
        closureInfo!.lastVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        
        /// Set last time execute date.
        closureInfo!.lastTime = NSDate()
        
        /// Set to the main dictionary.
        setInfoForClosure(closureInfo!, forKey:key)
    }
    
    /*!
    *  @brief  Get the info for a certain closure key and group.
    *  @param  key     The unique name of the closure.
    *  @return the TPTOnboardingVO with the closure execution information.
    */
    func getInfoForClosure(key:String) -> TPTOnboardingVO?
    {
        if let closureDict = getOnboardingDict()
        {
            if let closureInfo = closureDict.objectForKey(key) as? TPTOnboardingVO
            {
                return closureInfo
            }
        }
        return nil
    }
    
    /*!
    *  @brief  Get the NSMutableDictionary for a certain closure.
    *  @return The NSMutableDictionary for the group.
    */
    func getOnboardingDict() -> NSMutableDictionary?
    {
        return onboardingDictionary!.objectForKey(onboardingGroup) as? NSMutableDictionary
    }
    
    /*!
    *  @brief  Set the info for a certain closure key and group.
    *  @param  closureInfo   The closure information to be saved.
    *  @param  forKey        The unique name of the closure.

    */
    func setInfoForClosure(closureInfo:TPTOnboardingVO, forKey key:String)
    {
        /// Get the right group dictionary (specific or general).
        var groupDictionary = getOnboardingDict()
        if (groupDictionary == nil) {
            groupDictionary = NSMutableDictionary()
        }
        
        /// Set the closure info for the dictionary.
        groupDictionary!.setObject(closureInfo, forKey:key)
        
        if (onboardingDictionary == nil) {
            onboardingDictionary = NSMutableDictionary()
        }
        
        onboardingDictionary!.setObject(groupDictionary!, forKey:onboardingGroup)
        
        /// Sync with the disk.
        saveDictionaryToUserDefaults()
    }
    
    /*!
    *  @brief  Resets/Erases all the previous executions.
    */
    func reset()
    {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        /// Delete the values for the sharedKey.
        userDefaults.removeObjectForKey(onboardingGroup)
        
        /// Loads again from userDefaults.
        onboardingDictionary = NSMutableDictionary()
    }
    
    /*!
    *  @brief  Loads the dictionary from User Defaults.
    *  @return the saved dictionary.
    */
    func loadDictionaryFromUserDefaults() -> NSMutableDictionary
    {
        /// Load the encoded dictionary from User Defaults and decode it.
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let encodedDictionary =  userDefaults.objectForKey(NSStringFromClass(TPTOnboardingController.self)) as? NSData
        {
            return NSKeyedUnarchiver.unarchiveObjectWithData(encodedDictionary) as! NSMutableDictionary
        } else {
            return NSMutableDictionary()
        }
    }

    /*!
    *  @brief  Encodes and saves the current dictionary to the User Defaults.
    */
    func saveDictionaryToUserDefaults()
    {
        /// Encodes and Saves the decoded running dictionary to User Defaults.
        let decodedDictionary = NSKeyedArchiver.archivedDataWithRootObject(onboardingDictionary!)
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        userDefaults.setObject(decodedDictionary, forKey: NSStringFromClass(TPTOnboardingController.self))
        userDefaults.synchronize()
    }
    
}

class TPTOnboardingVO: NSObject, NSCoding {
    
    var lastTime = NSDate()
    var lastVersion = String()
    
    func encodeWithCoder(aCoder: NSCoder){
        aCoder.encodeObject(lastTime, forKey: "lastTime")
        aCoder.encodeObject(lastVersion, forKey: "lastVersion")
    }
    
    override init() {
        self.lastVersion = ""
        self.lastTime = NSDate()
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder){
        self.lastTime = aDecoder.decodeObjectForKey("lastTime") as! NSDate
        self.lastVersion = aDecoder.decodeObjectForKey("lastVersion") as! String
        super.init()
    }
}
