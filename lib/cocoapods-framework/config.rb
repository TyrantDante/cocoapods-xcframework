module Pod
  class Config
    attr_accessor :xcframework_enable
    alias_method :xcframework_enable?, :xcframework_enable
  end
end