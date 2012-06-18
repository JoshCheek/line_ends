require 'open3'
require 'fileutils'

ENV['PATH'] = "#{File.expand_path '../../bin', __FILE__}:#{ENV['PATH']}"

describe 'line_ends binary' do
  def filename
    'some_file'
  end

  def cleanup_files
    FileUtils.rm_r proving_grounds_dir
  end

  def proving_grounds_dir
    File.expand_path '../proving_grounds', __FILE__
  end

  def in_proving_grounds
    FileUtils.mkdir_p proving_grounds_dir
    Dir.chdir(proving_grounds_dir) { yield }
  end

  def write_file(contents)
    in_proving_grounds { File.write filename, contents }
  end

  def execute
    return if @exit_status
    in_proving_grounds { @stdout, @stderr, @exit_status = Open3.capture3("line_ends #{filename}") }
    @exit_status = @exit_status.exitstatus
  end

  def expect_ends(*ends)
    execute
    @stdout.should == ends.map { |ending| "#{ending}\n" }.join
  end

  describe 'successful uses' do
    after { @exit_status.should be_zero }
    after { cleanup_files }

    it 'outputs nothing for an empty file' do
      write_file ""
      expect_ends #none
    end

    describe 'outputs each ending on its own line for a file with no empty lines' do
      example '\n' do
        write_file "abc\n"
        expect_ends '\n'
      end

      it '\r\n' do
        write_file "abc\r\n"
        expect_ends '\r\n'
      end

      it '\n\r' do
        write_file "abc\n\r"
        expect_ends '\n\r'
      end

      it '\r' do
        write_file "abc\r"
        expect_ends '\r'
      end

      it '\n \r\n \n\r \n \r' do
        write_file "abc\ndef\r\nghi\n\rjkl\nmno\r"
        expect_ends '\n', '\r\n', '\n\r', '\n', '\r'
      end
    end

    context 'outputs each ending on its own line for a file with empty lines' do
      example '\n' do
        write_file "\n\n"
        expect_ends '\n', '\n'
      end

      example '\r' do
        write_file "\r\r"
        expect_ends '\r', '\r'
      end

      example '\r\n' do
        write_file "\r\n\r\n"
        expect_ends '\r\n', '\r\n'
      end

      example '\n\r' do
        write_file "\n\r\n\r"
        expect_ends '\n\r', '\n\r'
      end
    end

  end
end
