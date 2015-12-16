# noinspection RubyUnusedLocalVariable
class AppDelegate
  def applicationDidFinishLaunching(notification)
    Util.setup_logging
    BITHockeyManager.sharedHockeyManager.configureWithIdentifier('928a3dd77d804c99a4fad264738999fc', delegate: self)
    BITHockeyManager.sharedHockeyManager.crashManager.setAutoSubmitCrashReport(true)
    BITHockeyManager.sharedHockeyManager.startManager
    SUUpdater.sharedUpdater.setDelegate(self)
    Persist.store.load_prefs
    MainMenu.build!
    MenuActions.setup
    MainMenu[:statusbar].items[:status_version][:title] = "Current Version: #{Info.version}"
    NSUserNotificationCenter.defaultUserNotificationCenter.setDelegate(self)
    distCenter = NSDistributedNotificationCenter.defaultCenter
    distCenter.addObserver(self, selector: 'onScreenSaverStarted', name: 'com.apple.screensaver.didstart', object: nil)
    distCenter.addObserver(self, selector: 'onScreenSaverStopped', name: 'com.apple.screensaver.didstop', object: nil)
    distCenter.addObserver(self, selector: 'onScreenLocked', name: 'com.apple.screenIsLocked', object: nil)
    distCenter.addObserver(self, selector: 'onScreenUnlocked', name: 'com.apple.screenIsUnlocked', object: nil)
  end

  def onScreenSaverStarted
    Util.log.debug 'Screen saver started'
    Info.start_time = NSDate.date unless Info.start_time
  end

  def onScreenLocked
    Util.log.debug 'Screen locked'
    Info.locked = true
    Info.start_time = NSDate.date unless Info.start_time
  end

  def onScreenSaverStopped
    Util.log.debug 'Screen saver stopped'
    self.displayDiff unless Info.locked?
  end

  def onScreenUnlocked
    Util.log.debug 'Screen unlocked'
    Info.locked = false
    self.displayDiff
  end

  def displayDiff
    if Info.start_time
      diff            = NSDate.date - Info.start_time
      Info.start_time = nil
      time_display    = get_time_display(diff)
      MainMenu[:statusbar].items[:status_last][:title] = time_display
      Util.notify "You were away for #{time_display}"
    end
  end

  def get_time_display(diff)
    "#{(diff/(3600.0)).floor}h #{((diff % (3600.0))/60.0).floor}m #{'%.3f' % (diff % 60)}s".to_weak
  end

  def feedParametersForUpdater(updater, sendingSystemProfile: sendingProfile)
    BITSystemProfile.sharedSystemProfile.systemUsageData
  end

  def getLatestLogFileContent
    description        = ''
    sortedLogFileInfos = Util.file_logger.logFileManager.sortedLogFileInfos
    sortedLogFileInfos.reverse_each { |logFileInfo|
      logData = NSFileManager.defaultManager.contentsAtPath logFileInfo.filePath
      if logData.length > 0
        description = NSString.alloc.initWithBytes(logData.bytes, length: logData.length, encoding: NSUTF8StringEncoding)
        break
      end
    }
    description
  end

  def applicationLogForCrashManager(crashManager)
    description = self.getLatestLogFileContent
    if description.nil? || description.length <= 0
      nil
    else
      description
    end
  end
end
