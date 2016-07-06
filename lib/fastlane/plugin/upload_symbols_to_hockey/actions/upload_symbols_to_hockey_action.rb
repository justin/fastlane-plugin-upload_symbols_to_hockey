require 'faraday'
require 'faraday_middleware'
require 'json'

module Fastlane
  module Actions
    class UploadSymbolsToHockeyAction < Action
      HOST_NAME = 'https://rink.hockeyapp.net'

      def self.run(params)
        api_token = params[:api_token]
        build_number = params[:build_number]
        public_identifier = params[:public_identifier]
        dsym_path = params[:dsym].shellescape

        conn = Faraday.new(:url => HOST_NAME) do |faraday|
          faraday.request  :multipart
          faraday.request  :url_encoded             # form-encode POST params
          faraday.response :logger                  # log requests to STDOUT
          faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
          faraday.headers['X-HockeyAppToken'] = api_token
        end

        versions = conn.get do |req|
          req.url("/api/2/apps/#{public_identifier}/app_versions/")
        end

        versions_json = JSON.parse(versions.body)
        versions_json['app_versions'].each do |version|
            if version['version'] == build_number
              @version_id = version['id'].to_s
              break
            end
        end
        
        response = conn.put do |req|
          req.url "/api/2/apps/#{public_identifier}/app_versions/#{@version_id}"
          req.body = {  :file => Faraday::UploadIO.new(dsym_path, 'application/octet-stream') }
        end

        if response.status == 201
          UI.success '🏒 dSYM is successfully uploaded to Hockey 🏒'
        else
          UI.error "Something went wrong duricng Hockey dSYM upload. Status code is #{response.status}"
        end
      end

      def self.description
        "Upload dSYM symbolication files to Hockey"
      end

      def self.authors
        ["Justin Williams"]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                  env_name: "UPLOAD_SYMBOLS_TO_HOCKEY_API_TOKEN",
                               description: "API Token for Hockey Access",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                    UI.user_error!("No API token for Hockey given, pass using `api_token: 'token'`") if value.to_s.length == 0
                                  end),

          FastlaneCore::ConfigItem.new(key: :public_identifier,
                                  env_name: "UPLOAD_SYMBOLS_TO_HOCKEY_PUBLIC_IDENTIFIER",
                               description: "Public identifier of the app you are targeting",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                    UI.user_error!("No public identifier for Hockey given, pass using `public_identifier: 'public_identifier'`") if value.to_s.length == 0
                                  end),

          FastlaneCore::ConfigItem.new(key: :dsym,
                                  env_name: "UPLOAD_SYMBOLS_TO_HOCKEY_DSYM",
                               description: "Path to your symbols file",
                                  optional: false,
                                      type: String,
                             default_value: ENV[SharedValues::DSYM_OUTPUT_PATH.to_s] || (Dir["./**/*.dSYM"] + Dir["./**/*.dSYM.zip"]).first,
                              verify_block: proc do |value|
                                UI.user_error!("Couldn't find file at path '#{File.expand_path(value)}'") unless File.exist?(value)
                                UI.user_error!("Symbolication file needs to be dSYM or zip") unless value.end_with?(".zip", ".dSYM")
                                end),

          FastlaneCore::ConfigItem.new(key: :build_number,
                                  env_name: "UPLOAD_SYMBOLS_TO_HOCKEY_BUILD_NUMBER",
                               description: "The build number for the dSYMs you want to upload",
                                  optional: false,
                                      type: String)
        ]
      end

      def self.is_supported?(platform)
        [:ios, :tvos, :osx, :watchos].include?(platform)
      end
    end
  end
end
