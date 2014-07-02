require 'open3'
require 'test_helper'

describe 'Start a server' do
  it 'starts the app' do
    with_running_server do
      output = `curl -I http://localhost:2300`
      puts output.inspect
    end
  end

  def with_running_server(&blk)
    Open3.popen3(Dir.pwd + '/bin/lotus', 'server', %(--config=#{ Dir.pwd }/test/fixtures/config.ru)) do |stdin, stdout, stderr, wait_thr|
      sleep 1
      puts stdout.read
      blk.call(stdin, stdout, stderr, wait_thr)
      puts stderr.read
      Process.kill('HUP', wait_thr[:pid])
    end
  end
end

