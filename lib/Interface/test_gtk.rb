require 'rubygems'
require 'gtk2'

#!/usr/bin/env ruby
require 'gtk2'

def another_tab; puts "Switching"; end
def report_press(w); puts "Somebody pressed gumbek (button) w=#{w}"; end

window = Gtk::Window.new(Gtk::Window::TOPLEVEL)
window.set_title  "Notebook with 3 tabs"
window.border_width = 10
window.set_size_request(300, -1)
# The delete_event is only needed if you plan to
# intercept the destroy / quit with a dialog box.
#
# window.signal_connect('delete_event') { false }
# Normally you'd catch the destroy signal, however
# as the following code shows delete-event can do
# anything you want also quit for that matter:
# window.signal_connect('destroy') { Gtk.main_quit }
window.signal_connect('delete_event') { Gtk.main_quit }

nb = Gtk::Notebook.new
label1 = Gtk::Label.new("1st Pg")
label2 = Gtk::Label.new("2st Pg")
label3 = Gtk::Label.new("3rd Pg")
note1  = Gtk::Label.new("Page -1-.\nCan switch to ...")
note2  = Gtk::Label.new("-2- page.\nSwitch to ...")
button = Gtk::Button.new("Gumbek")

# In Ruby Notebook works without {{ signal_connect }}.
# -----------------------------------------------------------------------
# In Ruby the following doesn't work (Label does not respond to 'clicked'
# note1.signal_connect('clicked') { another_tab }
# note2.signal_connect('clicked') { another_tab }

# However you can place a button into a notebook and klick away.
button.signal_connect( "clicked" ) {|w| report_press(w) }

nb.signal_connect('change-current-page') { another_tab }

nb.append_page(note1, label1)
nb.append_page(note2, label2)
nb.append_page(button,  label3)

window.add(nb)
window.show_all
Gtk.main
