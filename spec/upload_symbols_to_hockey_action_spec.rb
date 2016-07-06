describe Fastlane::Actions::UploadSymbolsToHockeyAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The upload_symbols_to_hockey plugin is working!")

      Fastlane::Actions::UploadSymbolsToHockeyAction.run(nil)
    end
  end
end
