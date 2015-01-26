Pod::Spec.new do |s|


  s.name         = "remote-logging"
  s.version      = "0.0.2"
  s.summary      = "remote loggin for ios/osx"

  s.description  = <<-DESC
                   Please don't use this pod on your own, contact me if you are interested
                   DESC

  s.homepage     = "https://github.com/jakubknejzlik/remote-logging"

  s.license      = "MIT"

  #

  s.author             = { "Jakub Knejzlík" => "jakub.knejzlik@gmail.com" }

  # s.platform     = :ios
  # s.platform     = :ios, "5.0"

  #  When using multiple platforms
  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.8"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "https://github.com/jakubknejzlik/remote-logging.git", :tag => "0.0.2" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any h, m, mm, c & cpp files. For header
  #  files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.source_files  = "remote-logging/**/*.{h,m}"



  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # s.resource  = "icon.png"
  s.resources = "remote-logging/*.{xcdatamodel}"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  s.framework  = "CoreData"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  s.requires_arc = true

  s.dependency 'GNContextManager'
  s.dependency 'AFNetworking'
  s.dependency 'CWLSynthesizeSingleton'
end
