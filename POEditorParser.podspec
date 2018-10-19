Pod::Spec.new do |s|

  s.name         = "POEditorParser"
  s.version      = "0.1.1"
  s.summary      = "`POEditorParser` generates a swift file with an input strings file from POEditor."

  s.description  = <<-DESC
                      `POEditorParser` generates a swift file with an input strings file from POEditor.
                   DESC

  s.homepage     = "https://stash.bq.com/projects/IDA/repos/poeditorparser-swift"

  s.license      = "BQ"
  s.author             = { "jorge.revuelta" => "jorge.revuelta@bq.com" }
  s.social_media_url   = "https://twitter.com/minuscorp"

  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.10"
  
  s.source       = { :git => "https://stash.bq.com/scm/ida/poeditorparser-swift.git", :tag => s.version }

  s.source_files  = "Sources/"
  s.public_header_files = "Sources/POEditorParser.h"
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.2' }
  s.swift_version = '4.2'
  s.static_framework = true
end
