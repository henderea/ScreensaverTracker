# -*- coding: utf-8 -*-
$:.unshift('/Library/RubyMotion/lib')
require 'motion/project/template/osx'

begin
  require 'bundler'
  Bundler.require
rescue
  system('bundle install')
  exit 1
end

SKIP_CODESIGN_TIMESTAMP = false

module Motion::Project
  class Builder
    def codesign(config, platform)
      app_bundle   = config.app_bundle_raw('MacOSX')
      entitlements = File.join(config.versionized_build_dir(platform), 'Entitlements.plist')
      if File.mtime(config.project_file) > File.mtime(app_bundle) or !system("/usr/bin/codesign --verify \"#{app_bundle}\" >& /dev/null")
        App.info 'Codesign', app_bundle
        File.open(entitlements, 'w') { |io| io.write(config.entitlements_data) }
        sh "/usr/bin/codesign --deep --force --sign \"#{config.codesign_certificate}\"#{SKIP_CODESIGN_TIMESTAMP ? ' --timestamp=none' : ''} --entitlements \"#{entitlements}\" \"#{app_bundle}\""
      end
    end
  end
end

Motion::Project::App.setup do |app|
  app.icon                                  = 'Icon.icns'
  app.name                                  = 'ScreensaverTracker'
  app.version                               = '1.1.1'
  app.short_version                         = '1.1.1'
  app.identifier                            = 'us.myepg.ScreensaverTracker'
  app.info_plist['NSUIElement']             = true
  app.info_plist['SUFeedURL']               = 'https://rink.hockeyapp.net/api/2/apps/928a3dd77d804c99a4fad264738999fc'
  app.info_plist['SUEnableSystemProfiling'] = true
  app.info_plist['NSAppleScriptEnabled']    = true
  app.deployment_target                     = '10.9'
  app.codesign_certificate                  = 'Developer ID Application: Eric Henderson (SKWXXEM822)'
  # app.embedded_frameworks << 'vendor/Growl.framework'
  app.frameworks << 'ServiceManagement'

  app.pods do
    pod 'CocoaLumberjack'
    pod 'HockeySDK-Mac'
    pod 'Sparkle'
  end
end

class Motion::Project::App
  class << self
    #
    # The original `build' method can be found here:
    # https://github.com/HipByte/RubyMotion/blob/master/lib/motion/project/app.rb#L75-L77
    #
    alias_method :build_before_copy_helper, :build

    def build(platform, options = {})

      helper_name = 'STLaunchHelper'

      # First let the normal `build' method perform its work.
      build_before_copy_helper(platform, options)
      # Now the app is built, but not codesigned yet.

      destination = File.join(config.app_bundle(platform), 'Library/LoginItems')
      info 'Create', destination
      FileUtils.mkdir_p destination

      helper_path = File.join("./#{helper_name}", config.versionized_build_dir(platform)[1..-1], "#{helper_name}.app")
      info 'Copy', helper_path
      FileUtils.cp_r helper_path, destination
    end
  end
end