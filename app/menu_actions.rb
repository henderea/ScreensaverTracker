module MenuActions
  module_function

  # def persisted_checkbox_item(item_label, persist_label)
  #   item_label                                     = item_label.to_sym
  #   MainMenu[:statusbar].items[item_label][:state] = Persist.store["#{persist_label}?"] ? NSOnState : NSOffState
  #   MainMenu[:statusbar].subscribe(item_label, item_label) { |_, _|
  #     Persist.store[persist_label]                   = MainMenu[:statusbar].items[item_label][:state] == NSOffState
  #     MainMenu[:statusbar].items[item_label][:state] = Persist.store["#{persist_label}?"] ? NSOnState : NSOffState
  #   }
  # end

  def setup
    MainMenu[:statusbar].subscribe(:status_update) { |_, sender| SUUpdater.sharedUpdater.checkForUpdates(sender) }
    MainMenu[:statusbar].subscribe(:status_pushover) { |_, _|
      path = File.expand_path('~/screensaver_tracker_pushover.txt')
      system("echo 'REPLACE THIS WITH PUSHOVER TOKEN' >'#{path}'") unless File.exist?(path)
      NSWorkspace.sharedWorkspace.openFile(path)
    }
    MainMenu[:statusbar].subscribe(:status_login) { |_, _|
      Util.login_item_set_enabled(MainMenu[:statusbar].items[:status_login][:state] == NSOffState)
      MainMenu[:statusbar].items[:status_login][:state] = Util.login_item_enabled? ? NSOnState : NSOffState
    }
  end
end