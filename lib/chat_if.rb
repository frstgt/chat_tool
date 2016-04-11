# encoding: utf-8

require "curses"

class ChatIf

  def initialize(title, enable=true)
    @enable = enable
    if @enable then
      Curses.init_screen
      @title = Curses::Window.new(1,Curses.cols,0,0)
      title_update(title)
      @member = Curses::Window.new(Curses.lines-1,10,1,Curses.cols-10)
      member_update([])
      @chatline = Curses::Window.new(Curses.lines-3,Curses.cols-10,1,0)
      @chatline.scrollok(true)
      @chatline.refresh
      @input = Curses::Window.new(2,Curses.cols-10,Curses.lines-2,0)
      @input.refresh
    end
  end

  def title_update(title)
    if @enable then
      @title.setpos(0, Curses.cols/2 - (title.length/2))
      @title.addstr(title)
      @title.refresh
    else
      p "title: " + title
    end
  end
  def member_update(member_ary)
    if @enable then
      @member.clear
      for id in member_ary do
        @member.addstr(id + "\n")
      end
      @member.refresh
    else
      p "member: " + member_ary.to_s
    end
  end
  def puts(str)
    if @enable then
      @chatline.addstr(str + "\n")
      @chatline.refresh
    else
      Kernel::puts(str)
    end
  end
  def gets
    if @enable then
      @input.clear
      @input.addstr("> ")
      @input.refresh
      @input.getstr
    else
      Kernel::gets
    end
  end

  def finarize
    if @enable then
      @input.close
      @chatline.close
      @member.close
      @title.close
      Curses.close_screen
    end
  end
end
