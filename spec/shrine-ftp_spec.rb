require 'shrine/storage/ftp'
require 'vcr'

VCR.configure do |cfg|
  cfg.cassette_library_dir = 'spec/vcr'
  cfg.hook_into :webmock
end

class FakeIO
  def initialize(content, id)
    @content = content
    @id = id
  end

  def id
    @id
  end

  def content
    @content
  end
end

describe "#upload" do
  context "successful ftp upload" do
    it "returns" do
      fake_io = FakeIO.new(File.read("spec/spec_helper.rb"), "spec/spec_helper.rb")
      dir_name = 'directory'
      mock_ftp = instance_double(Net::FTP)
      expect(Net::FTP).to receive(:open).and_return(mock_ftp)
      expect(mock_ftp).to receive(:chdir).with(dir_name).and_return(true)
      expect(mock_ftp).to receive(:chdir).with("spec").and_return(true)
      expect(mock_ftp).to receive(:putbinaryfile).with(fake_io, "spec_helper.rb")

      storage = Shrine::Storage::Ftp.new(
          host: 'fakehost.com',
          user: 'fakeuser',
          password: 'password',
          dir: dir_name)

      storage.upload(fake_io, fake_io.id)
    end
  end

  context "unsuccessful ftp upload" do
    it "raises an error" do
      fake_io = FakeIO.new(File.read("spec/spec_helper.rb"), "spec/spec_helper.rb")
      dir_name = 'directory'
      mock_ftp = instance_double(Net::FTP)
      expect(Net::FTP).to receive(:open).and_return(mock_ftp)
      expect(mock_ftp).to receive(:chdir).with(dir_name).and_return(true)
      expect(mock_ftp).to receive(:chdir).with("spec").and_return(true)
      allow(mock_ftp).to receive(:putbinaryfile).with(fake_io, "spec_helper.rb").
          and_raise(Net::FTPPermError)

      storage = Shrine::Storage::Ftp.new(
          host: 'fakehost.com',
          user: 'fakeuser',
          password: 'password',
          dir: dir_name)

      expect { storage.upload(fake_io, fake_io.id) }.to raise_error(Net::FTPPermError)
    end
  end
end

describe "#url" do
  it "returns URL of the object" do
    fake_id = "123123"
    url_root = 'https://google.com'
    storage = Shrine::Storage::Ftp.new(
        host: 'fakehost.com',
        user: 'fakeuser',
        password: 'password',
        dir: 'dir',
        prefix: url_root)
    expect(storage.url(fake_id)).to eq("#{url_root}/dir/#{fake_id}")
  end
end

describe "#exists?" do
  context "file exists" do
    it "returns true" do
      VCR.use_cassette 'storage/exists_true_response' do
        storage = Shrine::Storage::Ftp.new(
            host: 'https://media.scpr.org',
            user: 'fakeuser',
            password: 'password',
            dir: 'podcasts/upload/2017/11/28')

        expect(storage.exists?('Nov_28_2017-dfdf58d8.mp3')).to be(true)
      end
    end
  end
  context "file doesn't exist" do
    it "returns false" do
      VCR.use_cassette 'storage/exists_false_response' do
        storage = Shrine::Storage::Ftp.new(
            host: 'https://media.scpr.org',
            user: 'fakeuser',
            password: 'password',
            dir: 'podcasts/upload/2017/11/28')

        expect(storage.exists?('doesntexistorelseiamlying.xxx.mp3')).to be(false)
      end
    end
  end
end

describe "#delete" do
  context "file exists" do
    it "returns true" do
      VCR.use_cassette 'storage/exists_true_response' do
        dir_name = 'podcasts/upload/2017/11/28'
        filename = 'Nov_28_2017-dfdf58d8.mp3'
        storage = Shrine::Storage::Ftp.new(
            host: 'https://media.scpr.org',
            user: 'fakeuser',
            password: 'password',
            dir: dir_name)

        mock_ftp = instance_double(Net::FTP)
        expect(Net::FTP).to receive(:open).and_return(mock_ftp)
        expect(mock_ftp).to receive(:chdir).with("podcasts").and_return(true)
        expect(mock_ftp).to receive(:chdir).with("upload").and_return(true)
        expect(mock_ftp).to receive(:chdir).with("2017").and_return(true)
        expect(mock_ftp).to receive(:chdir).with("11").and_return(true)
        expect(mock_ftp).to receive(:chdir).with("28").and_return(true)
        expect(mock_ftp).to receive(:delete).with(filename)
        expect(mock_ftp).to receive(:chdir).with("..").and_return(true)
        expect(mock_ftp).to receive(:rmdir).with("28").and_return(true)
        expect(mock_ftp).to receive(:chdir).with("..").and_return(true)
        expect(mock_ftp).to receive(:rmdir).with("11").and_return(true)
        expect(mock_ftp).to receive(:chdir).with("..").and_return(true)
        expect(mock_ftp).to receive(:rmdir).with("2017").and_return(true)
        expect(mock_ftp).to receive(:chdir).with("..").and_return(true)
        expect(mock_ftp).to receive(:rmdir).with("upload").and_return(true)
        expect(mock_ftp).to receive(:chdir).with("..").and_return(true)
        expect(mock_ftp).to receive(:rmdir).with("podcasts").and_return(true)
        expect(storage.delete(filename)).to be(true)
      end
    end
  end

  context "file doesn't exist" do
    it "returns false" do
      VCR.use_cassette 'storage/exists_false_response' do
        dir_name = 'podcasts/upload/2017/11/28'
        filename = 'doesntexistorelseiamlying.xxx.mp3'
        storage = Shrine::Storage::Ftp.new(
            host: 'https://media.scpr.org',
            user: 'fakeuser',
            password: 'password',
            dir: dir_name)

        expect(storage.delete(filename)).to be(false)
      end
    end
  end
end