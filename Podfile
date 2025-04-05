# Uncomment the next line to define a global platform for your project
platform :ios, '16.0'

# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Rizzradar' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  inhibit_all_warnings!
  
  # Firebase
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Analytics'

  target 'RizzradarTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'RizzradarUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

# Fix for arm64 architecture
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      
      # Add these lines for arm64 simulator support
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
    end
  end
end
