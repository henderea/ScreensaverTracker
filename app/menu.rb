class MainMenu
  extend EverydayMenu::MenuBuilder

  menuItem :hide_others, 'Hide Others', preset: :hide_others
  menuItem :show_all, 'Show All', preset: :show_all
  menuItem :close, 'Close', preset: :close
  menuItem :quit, 'Quit', preset: :quit

  menuItem :services_item, 'Services', preset: :services

  menuItem :status_last, '0m 0s'
  # menuItem :status_today, 'Today: 0m 0s'
  menuItem :status_pushover, 'Configure Pushover'
  menuItem :status_login, 'Launch on login', state: NSOffState
  menuItem :status_update, 'Check for Updates'
  menuItem :status_version, 'Current Version: 0.0'
  menuItem :status_quit, 'Quit', preset: :quit

  (1..5).each { |i|
    menuItem :"status_recent_#{i}", '-', dynamicTitle: -> { Info.away_records[-i] || '-' }
  }

  mainMenu(:app, 'ScreensaverTracker') {
    hide_others
    show_all
    ___
    services_item
    ___
    close
    ___
    quit
  }

  menu(:status_recent_menu, 'Recent records') {
    (1..5).each { |i|
      self << :"status_recent_#{i}"
    }
  }

  menuItem :status_recent, 'Recent records', submenu: :status_recent_menu

  statusbarMenu(:statusbar, '', status_item_icon: NSImage.imageNamed('Status')) {
    status_last
    # status_today
    ___
    status_pushover
    ___
    status_recent
    ___
    status_login
    ___
    status_update
    status_version
    ___
    status_quit
  }

  def self.update_recents
    (1..5).each { |i|
      MainMenu[:status_recent_menu].items[:"status_recent_#{i}"].updateDynamicTitle
    }
  end
end