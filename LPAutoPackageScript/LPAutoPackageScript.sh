# !/bin/bash
#自动打包ipa包，上传蒲公英或fir
#
# ################################################################################
#
# 联系方式 :
# Email : liupanlive@163.com
# QQ : 812939702
# GitHub: https://github.com/maksamster
#
# ################################################################################
#

# 使用方法:
# step0 : pod更新框架
# step1 : 将AutoPackageScript整个文件夹拖入到项目主目录,项目主目录,项目主目录~~~(重要的事情说3遍!😊😊😊)
# step2 : 打开LPAutoPackageScript.sh文件,修改 "项目自定义部分" 配置好项目参数
# step3 : 打开终端, cd到LPAutoPackageScript文件夹 (ps:在终端中先输入cd ,直接拖入LPAutoPackageScript文件夹,回车)
# step4 : 输入 sh LPAutoPackageScript.sh 命令,回车,开始执行此打包脚本

# ================项目自定义部分(自定义好下列参数后再执行该脚本)================== #

# 开始更新pod
pod install
# 计时
SECONDS=0
# 是否编译工作空间 (例:若是用Cocopods管理的.xcworkspace项目,赋值true;用Xcode默认创建的.xcodeproj,赋值false)
is_workspace="true"
# 指定项目的scheme名称
# (注意: 因为shell定义变量时,=号两边不能留空格,若scheme_name与info_plist_name有空格,脚本运行会失败,暂时还没有解决方法,知道的还请指教!)
# 返回上一级目录,进入项目工程目录
cd ..
# 获取scheme名称 == 项目名称
scheme_name=`find . -name *.xcodeproj | awk -F "[/.]" '{print $(NF-1)}'`
# 跳转自动打包文件
cd "./LPAutoPackageScript"
# 工程中Target对应的配置plist文件名称, Xcode默认的配置文件为Info.plist
info_plist_name="Info"
# 指定要打包编译的方式 : Release,Debug...
build_configuration="Release"


# ===============================自动打包部分(无特殊情况不用修改)============================= #

# 导出ipa所需要的plist文件路径 (默认为AdHocExportOptionsPlist.plist)
ExportOptionsPlistPath="./LPAutoPackageScript/AdHocExportOptionsPlist.plist"
# 返回上一级目录,进入项目工程目录
cd ..
# 获取项目名称
project_name=`find . -name *.xcodeproj | awk -F "[/.]" '{print $(NF-1)}'`
# 获取版本号,内部版本号,bundleID
info_plist_path="$project_name/$info_plist_name.plist"
bundle_version=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" $info_plist_path`
echo "$bundle_version"
bundle_build_version=`/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" $info_plist_path`
echo "$bundle_build_version"
bundle_identifier=`/usr/libexec/PlistBuddy -c "Print CFBundleVersion" $info_plist_path`
echo "$bundle_identifier"

# 删除旧.xcarchive文件
rm -rf ~/Desktop/$scheme_name-IPA/$scheme_name.xcarchive
# 指定输出ipa路径
export_path=~/Desktop/$scheme_name-IPA
# 指定输出归档文件地址
export_archive_path="$export_path/$scheme_name.xcarchive"
# 指定输出ipa地址
export_ipa_path="$export_path"
# 指定输出ipa名称 : scheme_name + bundle_version
ipa_name="$scheme_name-v$bundle_version"

# AdHoc,APPStore,Enterprise三种打包方式的区别: http://blog.csdn.net/lwjok2007/article/details/46379945
echo "\033[36;1m请选择打包方式(输入序号,按回车即可) \033[0m"
echo "\033[33;1m1. AdHoc       \033[0m"
echo "\033[33;1m2. APPStore    \033[0m"
echo "\033[33;1m3. Enterprise  \033[0m"
echo "\033[33;1m4. Development \033[0m"
# 读取用户输入并存到变量里
read parameter
sleep 0.5
method="$parameter"

# 判读用户是否有输入
if [ -n "$method" ]
then
    if [ "$method" = "1" ] ; then
    ExportOptionsPlistPath="./LPAutoPackageScript/AdHocExportOptionsPlist.plist"
    elif [ "$method" = "2" ] ; then
    ExportOptionsPlistPath="./LPAutoPackageScript/APPStoreExportOptionsPlist.plist"
    elif [ "$method" = "3" ] ; then
    ExportOptionsPlistPath="./LPAutoPackageScript/EnterpriseExportOptionsPlist.plist"
    elif [ "$method" = "4" ] ; then
    ExportOptionsPlistPath="./LPAutoPackageScript/DevelopmentExportOptionsPlist.plist"
    else
    echo "输入的参数无效!!!"
    exit 1
    fi
fi

echo "\033[32m*************************  开始构建项目  *************************  \033[0m"
# 指定输出文件目录不存在则创建
if [ -d "$export_path" ] ; then
echo $export_path
else
mkdir -pv $export_path
fi

# 判断编译的项目类型是workspace还是project
if $is_workspace ; then
# 编译前清理工程
xcodebuild clean -workspace ${project_name}.xcworkspace \
                 -scheme ${scheme_name} \
                 -configuration ${build_configuration}

xcodebuild archive -workspace ${project_name}.xcworkspace \
                   -scheme ${scheme_name} \
                   -configuration ${build_configuration} \
                   -archivePath ${export_archive_path}
else
# 编译前清理工程
xcodebuild clean -project ${project_name}.xcodeproj \
                 -scheme ${scheme_name} \
                 -configuration ${build_configuration}

xcodebuild archive -project ${project_name}.xcodeproj \
                   -scheme ${scheme_name} \
                   -configuration ${build_configuration} \
                   -archivePath ${export_archive_path}
fi

#  检查是否构建成功
#  xcarchive 实际是一个文件夹不是一个文件所以使用 -d 判断
if [ -d "$export_archive_path" ] ; then
echo "\033[32;1m项目构建成功 🚀 🚀 🚀  \033[0m"
else
echo "\033[31;1m项目构建失败 😢 😢 😢  \033[0m"
exit 1
fi

echo "\033[32m*************************  开始导出ipa文件  *************************  \033[0m"
xcodebuild  -exportArchive \
            -archivePath ${export_archive_path} \
            -exportPath ${export_ipa_path} \
            -exportOptionsPlist ${ExportOptionsPlistPath}
# 修改ipa文件名称
mv $export_ipa_path/$scheme_name.ipa $export_ipa_path/$ipa_name.ipa

# 检查文件是否存在
if [ -f "$export_ipa_path/$ipa_name.ipa" ] ; then
echo "\033[32;1m导出 ${ipa_name}.ipa 包成功 🎉  🎉  🎉   \033[0m"
echo "\033[36;1m请选择打包方式(输入序号,按回车即可) \033[0m"
echo "\033[33;1m1. AdHoc包上传蒲公英       \033[0m"
echo "\033[33;1m2. 上传fir    \033[0m"
echo "\033[33;1m3. 上传APPStore    \033[0m"
echo "\033[33;1m4. 退出    \033[0m"
# 读取用户输入并存到变量里
read parameter
sleep 0.5
method="$parameter"

# 判读用户是否有输入
if [ -n "$method" ]
then
if [ "$method" = "1" ] ; then
echo "\033[33;1m1. AdHoc包上传蒲公英       \033[0m"
#通过api上传到蒲公英当中
pgyerUKey="2123d4c5eaccb481c776f6d5e"  # 这里替换蒲公英ukey
pgyerApiKey="8b82ed187299419708" # 这里替换蒲公英apiKey

RESULT=$(curl -F "file=@$export_ipa_path/$ipa_name.ipa" -F "uKey=$pgyerUKey" -F "_api_key=$pgyerApiKey" -F "publishRange=2" http://www.pgyer.com/apiv1/aPP/upload)
echo "$export_ipa_path/$ipa_name.ipa"
echo "完成上传"
echo $RESULT
echo 蒲公英网址 https://www.pgyer.com

elif [ "$method" = "2" ] ; then
echo "\033[33;1m上传fir中...    \033[0m"
# 替换成自己的Fir平台的token
fir login 1b5fd56265a834c66534cec
fir publish $export_ipa_path/$ipa_name.ipa
echo "完成上传"
elif [ "$method" = "3" ] ; then
echo "\033[33;1m2. 上传APPStore    \033[0m"
elif [ "$method" = "4" ] ; then
exit 1
open $export_path
else
echo "输入的参数无效!!!"
exit 1
fi
fi
else
echo "\033[31;1m导出 ${ipa_name}.ipa 包失败 😢 😢 😢     \033[0m"
exit 1
fi
# 输出打包总用时
echo "\033[36;1m使用LPAutoPackageScript打包总用时: ${SECONDS}s \033[0m"


