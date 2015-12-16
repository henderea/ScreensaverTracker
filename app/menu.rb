class MainMenu
  extend EverydayMenu::MenuBuilder

  menuItem :hide_others, 'Hide Others', preset: :hide_others
  menuItem :show_all, 'Show All', preset: :show_all
  menuItem :close, 'Close', preset: :close
  menuItem :quit, 'Quit', preset: :quit

  menuItem :services_item, 'Services', preset: :services

  menuItem :status_last, '0m 0s'
  # menuItem :status_today, 'Today: 0m 0s'
  menuItem :status_update, 'Check for Updates'
  menuItem :status_version, 'Current Version: 0.0'
  menuItem :status_quit, 'Quit', preset: :quit

  mainMenu(:app, 'DmgLocal') {
    hide_others
    show_all
    ___
    services_item
    ___
    close
    ___
    quit
  }

  statusbarMenu(:statusbar, '', status_item_icon: NSImage.imageNamed('Status')) {
    status_last
    # status_today
    ___
    status_update
    status_version
    ___
    status_quit
  }
end