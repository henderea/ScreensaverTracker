module LoggerClassMethods
  FLAGS = {
      :error   => (1<<0), # 0...00001
      :warn    => (1<<1), # 0...00010
      :info    => (1<<2), # 0...00100
      :debug   => (1<<3), # 0...01000
      :verbose => (1<<4) # 0...10000
  }

  LEVELS = {
      :off     => 0,
      :error   => FLAGS[:error],
      :warn    => FLAGS[:error] | FLAGS[:warn],
      :info    => FLAGS[:error] | FLAGS[:warn] | FLAGS[:info],
      :debug   => FLAGS[:error] | FLAGS[:warn] | FLAGS[:info] | FLAGS[:debug],
      :verbose => FLAGS[:error] | FLAGS[:warn] | FLAGS[:info] | FLAGS[:debug] | FLAGS[:verbose]
  }

  def level=(level)
    @level = level
  end

  def level
    @level
  end

  def async=(async)
    @async = async
  end

  def async
    @async
  end

  def error(message)
    __log(:error, message)
  end

  def warn(message)
    __log(:warn, message)
  end

  def info(message)
    __log(:info, message)
  end

  def debug(message)
    __log(:verbose, message)
  end

  alias_method :verbose, :debug

  def logging?(flag)
    (LEVELS[level] & FLAGS[flag]) > 0
  end

  protected
  def __log(flag, message)
    return unless logging?(flag)
    raise ArgumentError, "flag must be one of #{FLAGS.keys}" unless FLAGS.keys.include?(flag)
    async_enabled = self.async || (self.level == :error)
    message       = message.gsub('%', '%%')

    log(async_enabled,
        level:    LEVELS[level],
        flag:     FLAGS[flag],
        context:  0,
        file:     __FILE__,
        function: __method__,
        line:     __LINE__,
        tag:      0,
        format:   message)
  end
end

module Motion
  class Log < ::DDLog
    class << self
      alias_method :flush, :flushLog
    end

    extend LoggerClassMethods

    @async = true
    @level = :info
  end
end

module Util
  module_function

  def log
    Motion::Log
  end

  def file_logger
    @file_logger
  end

  def setup_logging
    @file_logger                                        = DDFileLogger.new
    @file_logger.rollingFrequency                       = 60 * 60 * 24
    @file_logger.logFileManager.maximumNumberOfLogFiles = 7
    Util.log.addLogger @file_logger, withLogLevel: LoggerClassMethods::LEVELS[:verbose]

    tty_logger = DDTTYLogger.sharedInstance
    Util.log.addLogger tty_logger, withLogLevel: LoggerClassMethods::LEVELS[:verbose]

    asl_logger = DDASLLogger.sharedInstance
    Util.log.addLogger asl_logger, withLogLevel: LoggerClassMethods::LEVELS[:debug]

    Util.log.level = :verbose
  end

  def notify(msg)
    notification                 = NSUserNotification.alloc.init
    notification.title           = 'ScreensaverTracker'
    notification.informativeText = msg.to_s
    notification.soundName       = nil
    NSUserNotificationCenter.defaultUserNotificationCenter.scheduleNotification(notification)
  end

  def open_link(link)
    NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString(link));
  end

  def constrain_value_range(range, value, default)
    value ? (value < range.min && range.min) || (value > range.max && range.max) : default
  end

  def constrain_value_list(list, old_value, new_value, default)
    (list.include?(new_value)) ? new_value : (list.include?(old_value) ? old_value : default)
  end

  def constrain_value_list_enable_map(map, old_value, new_value, new_default, default)
    map[new_value || new_default] ? (new_value || new_default) : ((map[old_value] && old_value) || default)
  end

  def constrain_value_boolean(value, default, enable = true, enable_is_true = true)
    ((value.nil? ? default : value_to_bool(value)) ? (enable || !enable_is_true) : (!enable && !enable_is_true)) ? NSOnState : NSOffState
  end

  def value_to_bool(value)
    value && value != 0 && value != NSOffState
  end
end