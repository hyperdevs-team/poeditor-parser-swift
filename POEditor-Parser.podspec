Pod::Spec.new do |s|

  s.name         = "POEditor-Parser"
  s.version      = "1.0.0"
  s.summary      = "`POEditor-Parser` generates a swift file with an input strings file from POEditor"

  s.description  = <<-DESC
                      `POEditor-Parser` generates a swift file with an input strings file from POEditor.
                   DESC

  s.homepage         = 'https://github.com/bq/poeditor-parser-swift'

  s.license          = { :type => 'APACHE', :file => 'LICENSE' }
  s.author           = { 'bq' => 'info@bq.com' }
  s.source           = { :git => 'https://github.com/bq/poeditor-parser-swift.git', :tag => "v#{s.version.to_s}" }

  s.social_media_url = 'https://twitter.com/bqreaders'

  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.10"
  
  s.source_files  = "Sources/"
  s.public_header_files = "Sources/POEditorParser.h"
  s.preserve_paths = [ "bin/poe" ]
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.2' }
  s.swift_version = '4.2'
  s.static_framework = true
end
