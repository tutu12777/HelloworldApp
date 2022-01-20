# xcodebuild -target HelloWorldApp -sdk iphonesimulator clean build | tee xcodebuild.log | xcpretty -r json-compilation-database -o compile_commands.json
#xcodebuild -workspace "HelloWorldApp.xcworkspace" -scheme "HelloWorldApp" -sdk iphonesimulator COMPILER_INDEX_STORE_ENABLE=NO OTHER_CFLAGS="-DNS_FORMAT_ARGUMENT(A)= -D_Nullable_result=_Nullable" clean build | tee xcodebuild.log | xcpretty -r json-compilation-database -o compile_commands.json
# infer run --keep-going --skip-analysis-in-path Pods --compilation-database-escaped compile_commands.json

#!/bin/sh

#########################################################
######### 1. 脚本文件需要和 xcworkspace 在同一目录下 #########
######### 2. 可以在任意目录下执行脚本               ##########
######### 3. -h 可以查看参数说明                  ##########
#########################################################

# 配置
changed_file_name=index.txt
infer_run_out_name=infer-out

# 获取脚本所在目录
shell_path=$(cd `dirname $0`;pwd)

# 获取当前目录
current_path=$(pwd)

# 获取infer输出目录
infer_run_out_path=${shell_path}/${infer_run_out_name}

# 获取默认参数
source_branch=$(git name-rev --name-only HEAD)
target_branch=master

project_extension='xcworkspace'
project_full_name=`ls ${shell_path} | grep "\.${project_extension}"`
project_name=${project_full_name%.*}

# 获取输入参数
while getopts ":p:s:t:dh" opt
do
    case $opt in
        p)
        project_name="$OPTARG";;
        s)
        source_branch="$OPTARG";;
        t)
        target_branch"$OPTARG";;
        d)
        rm -rf ${infer_run_out_path}
        exit 1;;
        h)
        echo "################################################################"
        echo "############ help message                           ############"
        echo "############                                        ############"
        echo "############ -s source branch                       ############"
        echo "############    default is current branch           ############"
        echo "############                                        ############"
        echo "############ -t target branch                       ############"
        echo "############    default is master branch            ############"
        echo "############                                        ############"
        echo "############ -p project name                        ############"
        echo "############    default is current path xcworkspace ############"
        echo "############                                        ############"
        echo "############ -d delete infer out                    ############"
        echo "############    delete infer out file               ############"
        echo "############                                        ############"
        echo "############ -h help                                ############"
        echo "################################################################"
        exit 1;;
    esac
done

diff_parameter=${source_branch}..${target_branch}

# 获取差异文件的全路径
git_diff_full_path(){
    local path
    path=$(git rev-parse --show-toplevel) &&
    git diff --name-only $1 "$@" | sed "s,^,$path/,"
}

# 运行infer: build --> capture ---> analyze ---> report
infer_run () {
    local infer_run_project_path=$1
    local infer_run_scheme_name=$2
    local infer_run_changed_file=$3
    
    # 编译项目
    # xcodebuild -workspace ${infer_run_project_path}/${infer_run_scheme_name}.xcworkspace -scheme ${infer_run_scheme_name} -configuration Debug -UseModernBuildSystem=NO -sdk iphoneos
    xcodebuild -workspace "HelloWorldApp.xcworkspace" -scheme "HelloWorldApp" -sdk iphonesimulator COMPILER_INDEX_STORE_ENABLE=NO OTHER_CFLAGS="-DNS_FORMAT_ARGUMENT(A)= -D_Nullable_result=_Nullable" clean build | tee xcodebuild.log | xcpretty -r json-compilation-database -o compile_commands.json
    # 该命令等同于 (capture + analyze)
   # LD=/usr/bin/true infer --skip-analysis-in-path Pods --no-xcpretty -o ${infer_run_out_path} -- xcodebuild -workspace ${infer_run_project_path}/${infer_run_scheme_name}.xcworkspace -scheme ${infer_run_scheme_name} -configuration Debug -UseModernBuildSystem=NO -sdk iphoneos | xcpretty
    infer run --keep-going --skip-analysis-in-path Pods --compilation-database-escaped compile_commands.json
    # # infer 捕获源码, 翻译为中间代码格式
    # LD=/usr/bin/true infer capture --reactive --skip-analysis-in-path Pods --no-xcpretty -o ${infer_run_out_path} -- xcodebuild -workspace ${infer_run_project_path}/${infer_run_scheme_name}.xcworkspace -scheme ${infer_run_scheme_name} -configuration Debug -UseModernBuildSystem=NO -sdk iphoneos | xcpretty

    # # infer 分析翻译后的结果,并输出报告
    # LD=/usr/bin/true infer analyze --reactive --changed-files-index ${infer_run_changed_file} -o ${infer_run_out_path}
}

# 进入脚目录
cd ${shell_path}

# 把差异文件名称输入到指定文件内
changed_file_index=${shell_path}/${changed_file_name}
git_diff_full_path ${diff_parameter} > ${changed_file_index}

# 切换到源分支
git checkout ${source_branch}

# 运行infer
infer_run ${shell_path} ${project_name} ${changed_file_index}

# 源分支和目标分支不是同一分支时,执行比较分析逻辑
if [ "${source_branch}" != "${target_branch}" ]
then
    # 拷贝报告
    cp ${shell_path}/infer-out/report.json ${shell_path}/report-feature.json

    # 切换到目标分支
    git checkout ${target_branch}

    # 检测master分支上的bug
    infer_run ${shell_path} ${project_name} ${changed_file_index}

    # 对比两份检测报告
    infer reportdiff --report-current ${shell_path}/report-feature.json --report-previous ${shell_path}/infer-out/report.json
    
    # 删除copy的报告文件
    rm -rf ${shell_path}/report-feature.json
fi

# 删除临时文件
rm -rf ${changed_file_index}

# 回到执行脚本时的目录
cd ${current_path}


