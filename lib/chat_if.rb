# encoding: utf-8

require "tk"

require "./lib/util"

class ChatIf

  def initialize(title, enable=true)
    @enable = enable
    if @enable then
      @root = TkRoot.new {
        title title
      }

      yscrollbar = TkScrollbar.new(@root) {
        orient "vertical"
        width 16
        grid(row: 0, column: 1, sticky: "news")
      }
      @chatline = TkText.new(@root) {
        state "disabled"
        width 80
        height 24
        yscrollbar yscrollbar
        yscrollcommand proc{ |first,last|
           first = (1 - (last.to_f - first.to_f)).to_s
           last = "1"
           yscrollbar.set(first,last)
        }
        grid(row: 0, column: 0, sticky: "news")
      }

      @member = TkText.new(@root) {
        state "disabled"
        width 10
        # height (Don't set a fix value here.)
        grid(row: 0, column: 2, rowspan: 2, sticky: "news")
      }

      @input = TkEntry.new(@root) {
        grid(row: 1, column: 0, columnspan: 2, sticky: "news")
      }
    end
  end

  def title_update(title)
    if @enable then
      @root.title = title
    else
      p "title: " + title
    end
  end
  def member_update(member_ary)
    if @enable then
      @member.state = "normal"
      @member.value = ""
      for id in member_ary do
        @member.value += id + "\n"
      end
      @member.state = "disabled"
    else
      p "member: " + member_ary.to_s
    end
  end

  def gets
    if @enable then
      str = @input.value.encode("UTF-8", "Windows-31J")
      @input.value = ""
      str
    else
      Kernel::gets
    end
  end
  def puts(str)
    if @enable then
      @chatline.state = "normal"
      @chatline.value += (str + "\n").encode("Windows-31J", "UTF-8")
      @chatline.state = "disabled"
    else
      Kernel::puts(str)
    end
  end

  def mainloop(sender, receiver)
    if @enable then
      @input.bind("Return", sender)
      receiver_t = Thread.new do
        receiver.call
      end
      Tk.mainloop
      receiver_t.exit
    else
      nop while true
    end
  end

end

# for debug
=begin
begin
  cif = ChatIf.new("ChatClient")
  sender = Proc.new {
    buf = cif.gets
    str = buf.chomp
    if str != "" then
      cif.puts(str)
    end
  }
  receiver = Proc.new {
    p "receive"
    loop do
    end
  }
  cif.mainloop(sender, receiver)
rescue => e
  puts "#$!#$@"
ensure
  loop do
  end
end
=end

# end of file
