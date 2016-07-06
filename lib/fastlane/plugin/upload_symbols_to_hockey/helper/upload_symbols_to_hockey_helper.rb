module Fastlane
  module Helper
    class UploadSymbolsToHockeyHelper
      # class methods that you define here become available in your action
      # as `Helper::UploadSymbolsToHockeyHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the upload_symbols_to_hockey plugin helper!")
      end
    end
  end
end
