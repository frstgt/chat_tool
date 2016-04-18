# encoding: utf-8

# log = LogUtil.new("/tmp", "system")
# puts( log.rec("test") )

require "time"

class LogUtil

  def initialize(dir=nil, pre=nil, enable=true)
    @enable = enable
    if @enable then
      log_dir = (dir) ? dir + "/" : "./"
      file = ((pre) ? pre + "-" : "") + time_str + ".log"
      @log_file = File.open(log_dir + file, "w")
    end
  end

  def rec(str)
    @log_file.puts(str) if @enable
    str
  end
  def time_rec(str)
    @log_file.puts(time_str + " " + str) if @enable
    str
  end

  private
    def time_str
      Time.now.strftime("%Y%m%d-%H%M%S")
    end
end

