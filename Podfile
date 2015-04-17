platform :ios, "7.0"


target "AZSocketIO" do
    pod 'SocketRocket', '~> 0.x'
end

target "AZSocketIOTests" do
    pod 'Kiwi', '~> 2.3'
end


post_install do |installer|
    installer.project.targets.each do |target|
        puts "Processing target: #{target.name}..."
        target.build_configurations.each do |config|
            config.build_settings['ARCHS'] = "$(ARCHS_STANDARD)"
        end
    end
end