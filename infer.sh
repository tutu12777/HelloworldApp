xcodebuild -target HelloWorldApp -sdk iphonesimulator clean build | tee xcodebuild.log | xcpretty -r json-compilation-database -o compile_commands.json
infer run --keep-going --skip-analysis-in-path Pods --compilation-database-escaped compile_commands.json


