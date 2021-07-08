#
# Be sure to run `pod lib lint CXIMUI.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do | s |
    s.name             = 'CXIMUI'
    s.version          = '1.0'
    s.summary          = 'A short description of CXIMUI.'
    
    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!
    
    s.description      = 'CXIMUI'
    
    s.homepage         = 'https://github.com/ishaolin/CXIMUI'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'wshaolin' => 'ishaolin@163.com' }
    s.source           = { :git => 'https://github.com/ishaolin/CXIMUI.git', :tag => s.version.to_s }
    
    s.ios.deployment_target = '9.0'
    
    s.resource_bundles = { 'CXIMUI' => ['CXIMUI/Assets/*.png'] }
    
    s.public_header_files = 'CXIMUI/Classes/**/*.h'
    s.source_files = 'CXIMUI/Classes/**/*'
    
    s.dependency 'MJRefresh', '3.6.1'
    s.dependency 'CXIMSDK'
    s.dependency 'CXUIKit'
    s.dependency 'CXAssetsPicker'
end
