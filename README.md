# xcode-builtin-process-xcframework

#### 开发此工具的缘由
* 项目中使用的某个`XCFramework`同版本下，支持便于调试功能的和不支持调试功能是两个二进制
* 然后项目使用的多`Configuration`模式而非多`Targets`

#### 观察Xcode编译过程
* 当工程中使用了某个xcframework时, 会有一个 `Process xxx.xcframework`的处理过程
```bash
cd xx/XCFrameworkTest/XCFrameworkTest.xcodeproj
builtin-process-xcframework --xcframework xx/XCFrameworkTest/OpenSSL.Package.xcframework --platform ios --environment simulator --target-path xx/Library/Developer/Xcode/DerivedData/XCFrameworkTest-evkvyfheaurwspaqawtdbhqpvrqp/Build/Products/Debug-iphonesimulator
```
* 这个过程会根据`platform` `environment` 参数拷贝对应文件到`$BUILT_PRODUCTS_DIR`目录下
* 同时`Xcode`编译时会自动添加`-L$BUILT_PRODUCTS_DIR` `-I$BUILT_PRODUCTS_DIR/include` 也就是`LIBRARAY_SEARCH_PATHS` 和 `HEADER_SERACH_PATHS`
* 但 `builtin-process-xcframework` 是 `Xcode Build System` 内置动作, 没有实际的 command


#### 如何使用此工具
* 在目标`Target`的`Build Settings`中添加一个`Add User-Defined`
```bash
# USE_RUST_NET_ENV=debug or USE_RUST_NET_ENV=release
```

* 继续在目标`Target`的`Build Phases`中添加一个`New Run Script Phase`
```bash
TOOL_PATH=${PROJECT_DIR}/tools/xcode-builtin-process-xcframework

SOOURCE_LIB=${PROJECT_DIR}/${TARGET_NAME}/libs/${USE_RUST_NET_ENV}/xx.xcframework
TOOL_ARGS=("--xcframework" "${SOOURCE_LIB}" "--platform" "ios")
if [[ "${PLATFORM_NAME}" == "iphonesimulator" ]]; then
    TOOL_ARGS+=("--environment" "simulator")
fi

TOOL_ARGS+=("--target-path" "${BUILT_PRODUCTS_DIR}")
echo "args: ${TOOL_ARGS[@]}" 
$TOOL_PATH "${TOOL_ARGS[@]}"
echo "" > ${BUILT_PRODUCTS_DIR}/process_xx.xcframework.${USE_RUST_NET_ENV}.stamp
```

* 勾选`Based on dependency analysis`
* 配置`Input/Output files` 避免每次build执行
    * `Input Files: $(PROJECT_DIR)/$(TARGET_NAME)/libs/$(USE_RUST_NET_ENV)/xxx.xcframework`
    * `Output Files: $(BUILT_PRODUCTS_DIR)/process_xx.xcframework.$(USE_RUST_NET_ENV).stamp`

#### 后面发现也可以直接通过`xcconfig`配置实现
* 比如有如下`xcconfig`
```
xxx/Config/XCConfig
├── ADHOC.xcconfig
├── Common.xcconfig
├── Debug.xcconfig
├── Profile.xcconfig
├── Release.xcconfig
├── TEST.xcconfig
```
* 那么可以在`Common.xcconfig`中添加如下内容
```
USE_XX_LIB_ENV=debug
USE_XX_LIB_ROOT_DIR[sdk=iphoneos*]=$(PROJECT_DIR)/XXLIB/$(USE_XX_LIB_ENV)/XXLIB.xcframework/ios-arm64
USE_XX_LIB_ROOT_DIR[sdk=iphonesimulator*]=$(PROJECT_DIR)/XXLIB/$(USE_XX_LIB_ENV)/XXLIB.xcframework/ios-arm64_x86_64-simulator

FRAMEWORK_SEARCH_PATHS=$(inherited) $(USE_XX_LIB_ROOT_DIR)
LIBRARY_SEARCH_PATHS=$(inherited) $(USE_XX_LIB_ROOT_DIR)
HEADER_SEARCH_PATHS=$(inherited) $(USE_XX_LIB_ROOT_DIR)/include
```
* 然后在其他具体的`xcconfig`调整`USE_XX_LIB_ENV`为不同的值就可以了

#### 在Apple开源的[swift-build](https://github.com/swiftlang/swift-build)中的实现
* [Sources/SWBCore/Specs/Tools/ProcessXCFrameworkLibrary.swift](https://github.com/swiftlang/swift-build/blob/main/Sources/SWBCore/Specs/Tools/ProcessXCFrameworkLibrary.swift)
* [Sources/SWBTaskExecution/TaskActions/ProcessXCFrameworkTaskAction.swift](https://github.com/swiftlang/swift-build/blob/main/Sources/SWBTaskExecution/TaskActions/ProcessXCFrameworkTaskAction.swift)
