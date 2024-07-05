# Clone secp256k1 0.5.0 code into ./build/secp256k1
`
mkdir build
git clone https://github.com/bitcoin-core/secp256k1 build/secp256k1
cd build/secp256k1
git checkout e3a885d42a7800c1ccebad94ad1e2b82c4df5c65
`

Pod::Spec.new do |s|
  s.name             = 'coinlib_flutter'
  s.module_name      = 'secp256k1'
  s.version          = '0.5.0'
  s.summary          = 'Cryptographic primitives from the secp256k1 library'
  s.description      = <<-DESC
The secp256k1 library bundled into the flutter plugin via cocoapods.
                       DESC
  s.homepage         = 'http://peercoin.net'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Peercoin Developers'

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/*.c'
  s.compiler_flags = '-Wno-unused-function', '-Wno-shorten-64-to-32'

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.14'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

end
