module Pod
  class Config
    attr_accessor :xcframework_enable
    alias_method :xcframework_enable?, :xcframework_enable
    attr_accessor :static_library_enable
    alias_method :static_library_enable?, :static_library_enable
  end
end