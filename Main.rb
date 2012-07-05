require 'rubygems'
require 'gtk2'
require 'Tortilla'

class MainWindow
  attr :glade
  attr_reader :builder

  def initialize
    if __FILE__ == $0
      Gtk.init
      @builder = Gtk::Builder::new
      @builder.add_from_file("main.glade")
      @builder.connect_signals{ |handler| method(handler) }  # (I don't have any handlers yet, but I will have eventually)
      @tortilla = Harness.new('Testconfig')
    end
  end

  def on_list_projects_clicked
    puts 'fofoo'
    buf = @builder.get_object("combobox1")
    res = @tortilla.list_projects
    res.each do |project_hash|
      buf.append_text(project_hash[:name])
    end
    buf.set_active(0)
  end

  def on_list_testplans_clicked
    puts 'fofoo'
    buf = @builder.get_object("textbuffer1")
    text = @tortilla.list_testplans
    buf.set_text("loading")
    buf.set_text(text)

  end


  def show(object)
    to_show = @builder.get_object(object)
    to_show.show()
  end

  def gtk_main_quit
    Gtk.main_quit()
  end
end

hello = MainWindow.new
hello.show("window1")
Gtk.main