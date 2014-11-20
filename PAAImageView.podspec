Pod::Spec.new do |s|
  s.name         = "PAAImageView"
  s.version      = "0.0.1"
  s.summary      = "Rounded async imageview downloader based on AFNetworking 2 and lightly cached."
  s.homepage     = "https://github.com/abiaad/PAAImageView"
  s.license      = { :type => 'MIT' }
  s.author       = { "Pierre Abi-aad" => "abiaad.pierre@me.com" }
  s.source       = { :git => "git@github.com:abiaad/PAAImageView.git", :tag => s.version.to_s }
  s.platform     = :ios, '6.0'
  s.source_files = 'PAAImageView.{h,m}'
  s.requires_arc = true
  s.dependency 'AFNetworking', '~> 2.2'
end
