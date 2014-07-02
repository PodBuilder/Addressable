Pod::Spec.new do |s|
  s.name             = "Addressable"
  s.version          = "0.1.0"
  s.summary          = "Addressable is a URL library that conforms to the relevant RFCS."
  s.description      = <<-DESC
                       This library also provides support for
                       IRIs and URI templates.

                       This library is a port of the `addressable` Ruby gem
                       DESC
  s.homepage         = "https://github.com/PodBuilder/Addressable"
  s.license          = 'Apache'
  s.author           = { "William Kent" => "https://github.com/wjk" }
  s.source           = { :git => "https://github.com/PodBuilder/Addressable.git", :tag => s.version.to_s }

  s.source_files = 'Pod/Classes'
  s.resources = 'Pod/Assets/*.png'
  s.requires_arc = true
end
