require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'BakaiCapacitorEdna'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = package['repository']['url']
  s.author = package['author']
  s.source = { :git => package['repository']['url'], :tag => s.version.to_s }
  s.source_files = 'ios/Sources/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.resource_bundles = { 'BakaiEdnaResources' => ['ios/Sources/BakaiEdnaPlugin/Resources/*.{png,webp,html}', 'ios/Sources/BakaiEdnaPlugin/Resources/*.lproj/*.strings'] }
  s.vendored_frameworks = 'ios/Frameworks/ChatCenterUI.xcframework'
  s.ios.deployment_target = '15.0'
  s.dependency 'Capacitor', '~> 8.0'
  s.swift_version = '5.9'
end
