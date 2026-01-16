# frozen_string_literal: true

task default: %w[setup]

task(:setup) do
  puts('➡️  Mint 🍃')
  sh('mint bootstrap')  
end

task(:lint) do
  sh('mint run swiftlint --fix --format')
end

task(:test) do
  sh('swift test --enable-code-coverage')
end

task :package do
  sh("xcrun swift build -c release --arch arm64 --arch x86_64")
  sh("mkdir -p bin")
  sh("cp ./.build/apple/Products/Release/poe ./bin/")
end
