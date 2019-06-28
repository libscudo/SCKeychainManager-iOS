#
# Be sure to run `pod lib lint SCKeychainManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SCKeychainManager'
  s.version          = '0.1.0'
  s.summary          = 'A wrapper for storing, removing and retrieving items from the Keychain.'

  s.description      = <<-DESC
                        A wrapper for storing, removing and retrieving passwords, certificates, keys, JSON Web Tokens, or any other type of data in a secure way.
                       DESC

  s.homepage         = 'https://github.com/eaceto/SCKeychainManager'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'eaceto' => 'ezequiel.aceto@gmail.com' }
  s.source           = { :git => 'https://github.com/eaceto/SCKeychainManager.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/eaceto_public'

  s.ios.deployment_target = '10.0'

  s.source_files = 'SCKeychainManager/Classes/**/*'

end
