module Info
  module_function

  class Version
    def initialize(version)
      @version = version || '0.0'
    end

    def <=>(other)
      other = Version.new(other && other.to_s)
      p     = parts
      op    = other.parts
      p <=> op
    end

    def <(other)
      (self <=> other) < 0
    end

    def <=(other)
      (self <=> other) <= 0
    end

    def ==(other)
      (self <=> other) == 0
    end

    def >(other)
      (self <=> other) > 0
    end

    def >=(other)
      (self <=> other) >= 0
    end

    def parts
      @version.gsub(/^(\d+)([^.]*)$/, '\1.0.0\3').gsub(/^(\d+)\.(\d+)([^.]*)$/, '\1.\2.0\3').gsub(/\.(\d+)b(\d+)$/, '.-1.\1.\2').split(/\./).map(&:to_i)
    end

    def to_s
      @version
    end
  end

  def version
    @version ||= Version.new(NSBundle.mainBundle.infoDictionary['CFBundleShortVersionString'])
  end

  def last_version
    @last_version ||= Version.new(self.version.to_s)
  end

  def last_version=(last_version)
    @last_version = Version.new(last_version || self.version.to_s)
  end

  def start_time
    @start_time
  end

  def start_time=(start_time)
    @start_time = start_time
  end

  def locked?
    @locked
  end

  def locked=(locked)
    @locked = locked
  end

  def computer_name
    NSHost.currentHost.localizedName
  end

  def away_records
    @away_records ||= []
  end

  def away_record_display_count
    10
  end
end