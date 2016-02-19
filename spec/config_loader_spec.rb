require_relative '../spec/spec_helper'
require_relative '../lib/config_loader'

describe ConfigLoader do
  describe '#load_config' do
    let(:config) { ConfigLoader.new("#{File.dirname(__FILE__)}/fixtures/config.sample", ["ubuntu", :production]).config }

    it 'properly loads data from config file' do
      expect(config.common.paid_users_size_limit).to eq(2147483648)
      expect(config.http.params).to eq(["array", "of", "values"])
      expect(config.ftp.lastname).to be_nil
      expect(config.ftp.enabled).to eq(false)
      expect(config.ftp[:path]).to eq('/etc/var/uploads')
      expect(config.ftp).to eq({ name: 'hello there, ftp uploading', path: '/etc/var/uploads', enabled: false})
    end
  end
end
