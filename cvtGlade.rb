#!/usr/bin/env ruby
#
# This file is gererated by ruby-glade-create-template 1.1.4.
#
require 'libglade2'

class CvtGlade
  include GetText

  attr :glade
  
  def initialize(path_or_data, root = nil, domain = nil, localedir = nil, flag = GladeXML::FILE)
    bindtextdomain(domain, localedir, nil, "UTF-8")
    @glade = GladeXML.new(path_or_data, root, domain, localedir, flag) {|handler| method(handler)}
    
  end
  
  def on_open1_activate(widget)
    puts "on_open1_activate() is not implemented yet."
  end
  def on_save_dialog_save_button_activate(widget)
    puts "on_save_dialog_save_button_activate() is not implemented yet."
  end
  def on_delete_lesson_button_clicked(widget)
    puts "on_delete_lesson_button_clicked() is not implemented yet."
  end
  def on_paste1_activate(widget)
    puts "on_paste1_activate() is not implemented yet."
  end
  def on_button3_clicked(widget)
    puts "on_button3_clicked() is not implemented yet."
  end
  def on_previous_button_clicked(widget)
    puts "on_previous_button_clicked() is not implemented yet."
  end
  def on_save_as1_activate(widget)
    puts "on_save_as1_activate() is not implemented yet."
  end
  def on_about1_activate(widget)
    puts "on_about1_activate() is not implemented yet."
  end
  def on_copy1_activate(widget)
    puts "on_copy1_activate() is not implemented yet."
  end
  def on_reset_vocable_score_clicked(widget)
    puts "on_reset_vocable_score_clicked() is not implemented yet."
  end
  def on_main_window_delete_event(widget, arg0)
    puts "on_main_window_delete_event() is not implemented yet."
  end
  def on_new1_activate(widget)
    puts "on_new1_activate() is not implemented yet."
  end
  def on_delete1_activate(widget)
    puts "on_delete1_activate() is not implemented yet."
  end
  def on_new_lesson_button_clicked(widget)
    puts "on_new_lesson_button_clicked() is not implemented yet."
  end
  def on_cut1_activate(widget)
    puts "on_cut1_activate() is not implemented yet."
  end
  def on_ok_button_clicked(widget)
    puts "on_ok_button_clicked() is not implemented yet."
  end
  def on_lesson_view_cursor_changed(widget)
    puts "on_lesson_view_cursor_changed() is not implemented yet."
  end
  def on_save1_activate(widget)
    puts "on_save1_activate() is not implemented yet."
  end
  def on_skip_button_clicked(widget)
    puts "on_skip_button_clicked() is not implemented yet."
  end
  def on_quit1_activate(widget)
    puts "on_quit1_activate() is not implemented yet."
  end
  def on_delete_vocable_button_clicked(widget)
    puts "on_delete_vocable_button_clicked() is not implemented yet."
  end
  def on_new_vocable_button_clicked(widget)
    puts "on_new_vocable_button_clicked() is not implemented yet."
  end
  def on_next_button_clicked(widget)
    puts "on_next_button_clicked() is not implemented yet."
  end
  def on_notebook1_switch_page(widget, arg0, arg1)
    puts "on_notebook1_switch_page() is not implemented yet."
  end
end

# Main program
if __FILE__ == $0
  # Set values as your own application. 
  PROG_PATH = "cvt.glade"
  PROG_NAME = "YOUR_APPLICATION_NAME"
  CvtGlade.new(PROG_PATH, nil, PROG_NAME)
  Gtk.main
end
