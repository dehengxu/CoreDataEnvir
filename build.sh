
xcodebuild -scheme CoreDataEnvir -configuration Release -sdk iphonesimulator -arch i386 -arch x86_64 clean  build CONFIGURATION_BUILD_DIR=./build/iphonesimulator
xcodebuild -scheme CoreDataEnvir -configuration Release -sdk iphoneos clean  build CONFIGURATION_BUILD_DIR=./build/iphoneos

cp -rf ./build/iphonesimulator/CoreDataEnvir.framework ./build/CoreDataEnvir.framework

lipo -create ./build/iphoneos/CoreDataEnvir.framework/CoreDataEnvir ./build/CoreDataEnvir.framework/CoreDataEnvir -o ./build/CoreDataEnvir.framework/CoreDataEnvir