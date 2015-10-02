#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require './cvtGlade.rb'
require 'yaml'


DEFAULT_FILENAME = File.expand_path "~/.vocables.voc"  

class Cvt < CvtGlade
  
  Lesson = Struct.new('Lesson', :id, :number, :name, :selected, :progress, :editable)
  Vocable = Struct.new('Vocable', :number, :hanzi, :pinyin, :english, :progress, :editable, :h_p, :h_e, :p_h, :p_e, :e_h, :e_p)
  L_COLUMN_ID, L_COLUMN_NUMBER, L_COLUMN_NAME, L_COLUMN_SELECTED, L_COLUMN_PROGRESS, L_COLUMN_EDITABLE, L_NUM_COLUMNS = *(0..7).to_a
  V_COLUMN_NUMBER, V_COLUMN_HANZI, V_COLUMN_PINYIN, V_COLUMN_ENGLISH, V_COLUMN_PROGRESS, V_COLUMN_EDITABLE, L_COLUMN_H_P, V_COLUMN_H_E, V_COLUMN_P_H, V_COLUMN_P_E, V_COLUMN_E_H, V_COLUMN_E_P, V_NUM_COLUMNS = *(0..13).to_a
  
  PAGE_OVERVIEW, PAGE_LEARN, PAGE_ASK = *(0..3).to_a
  
  MAX_SCORE = 5
  
  NO_COLOR_BG     = Gdk::Color.new(65535, 65535, 65535)
  NO_COLOR_FG     = Gdk::Color.new(    0,     0,     0)
  WHITE_COLOR_BG  = Gdk::Color.new(65535, 65535, 65535)
  WHITE_COLOR_FG  = Gdk::Color.new(    0,     0,     0)
  YELLOW_COLOR_BG = Gdk::Color.new(65535, 65535,     0)
  YELLOW_COLOR_FG = Gdk::Color.new(    0,     0,     0)
  GREEN_COLOR_BG  = Gdk::Color.new(    0, 49151,     0)
  GREEN_COLOR_FG  = Gdk::Color.new(    0,     0,     0)
  BLUE_COLOR_BG   = Gdk::Color.new(    0,     0, 49151)
  BLUE_COLOR_FG   = Gdk::Color.new(65535, 65535, 65535)
  RED_COLOR_BG    = Gdk::Color.new(49151,     0,     0)
  RED_COLOR_FG    = Gdk::Color.new(65535, 65535, 65535)
  BLACK_COLOR_BG  = Gdk::Color.new(16384, 16384, 16384)
  BLACK_COLOR_FG  = Gdk::Color.new(65535, 65535, 65535)
  
  
  Question = Struct.new('Question', :asked_word, :right_answer_a, :type_a, :right_answer_b, :type_b, :lesson_id, :vocable_id)
  
  def initialize(path_or_data, root = nil, domain = nil, localedir = nil, flag = GladeXML::FILE)
    GetText.bindtextdomain(domain, localedir, nil, "UTF-8")
    @glade = GladeXML.new(path_or_data, root, domain, localedir, flag) {|handler| method(handler)}
    
    @lesson_id = 0
    @current_lesson = -1
    
    # create tree view
    @lesson_view = @glade.get_widget("lesson_view")
    @lesson_view.selection.mode = Gtk::SELECTION_SINGLE
    @vocable_view = @glade.get_widget("vocable_view")
    @vocable_view.selection.mode = Gtk::SELECTION_SINGLE
    @hanzi_label = @glade.get_widget("hanzi_label");
    @pinyin_label = @glade.get_widget("pinyin_label");
    @english_label = @glade.get_widget("english_label");
    
    @asked_word_label = @glade.get_widget("asked_word_label");
    @answer_buttons_a = []
    0.upto(5) do |i|
      @answer_buttons_a[i] = @glade.get_widget("translationa#{i+1}");
    end
    @answer_buttons_a_label = []
    0.upto(5) do |i|
      @answer_buttons_a_label[i] = @glade.get_widget("translationa#{i+1}_label");
    end
    @answer_buttons_b = []
    0.upto(5) do |i|
      @answer_buttons_b[i] = @glade.get_widget("translationb#{i+1}");
    end
    @answer_buttons_c = []
    0.upto(5) do |i|
      @answer_buttons_c[i] = @glade.get_widget("translationc#{i+1}");
    end
    
    @anser_box_a = @glade.get_widget("answer_a_frame");
    @anser_box_b = @glade.get_widget("answer_b_frame");
    @anser_box_c = @glade.get_widget("answer_c_frame");
    
    @answer_button_a_none = @glade.get_widget("translationa_none");
    @answer_button_a_skip = @glade.get_widget("translationa_skip");
    @answer_button_b_none = @glade.get_widget("translationb_none");
    @answer_button_b_skip = @glade.get_widget("translationb_skip");
    @answer_button_c_none = @glade.get_widget("translationc_none");
    @answer_button_c_skip = @glade.get_widget("translationc_skip");
    
    @last_word_status_label_a = @glade.get_widget("last_word_status_label_a")
    @last_word_status_label_b = @glade.get_widget("last_word_status_label_b")
    @last_word_status_label_c = @glade.get_widget("last_word_status_label_c")
    @last_word = @glade.get_widget("last_word")
    
    @asking_progress = @glade.get_widget("asking_progress")
    
    
    @set_ask_hanzi = @glade.get_widget("set_ask_hanzi");
    @set_ask_pinyin = @glade.get_widget("set_ask_pinyin");
    @set_ask_english = @glade.get_widget("set_ask_english");
    @set_questions_per_session = @glade.get_widget("set_questions_per_session");
    
    # create model
    @lesson_view.model = create_lesson_model
    
    #    @vocable_view.model = create_vocable_model
    @vocable_view_models = []
    
    add_lesson_columns(@lesson_view)
    add_vocable_columns(@vocable_view)
    
    # some buttons
    
    @filename = DEFAULT_FILENAME
    
  end
  
  
  
  def create_lesson_model
    # create array
    @lessons = []
    
    # create array
    @vocables = []
    
    #    add_items
    
    # create list store
    lesson_model = Gtk::ListStore.new(Integer, Integer, String, TrueClass, String, TrueClass)
    
    return lesson_model
  end
  
  def create_vocable_model
    
    #    add_items
    
    # create list store
    vocable_model = Gtk::ListStore.new(Integer, String, String, String, String, TrueClass, Integer, Integer, Integer, Integer, Integer, Integer)
    
    # add items
    #    @vocables.each do |article|
    #      iter = vocable_model.append
    #      
    #      article.each_with_index do |value, index|
    #        iter.set_value(index, value)
    #      end
    #    end
    return vocable_model
  end
  
  def update_lesson_model
    @lessons.each do |article|
      iter = @lesson_view.model.append
      
      article.each_with_index do |value, index|
        iter.set_value(index, value)
      end
    end
    
  end
  
  def update_vocable_model
    @lessons.each do |lesson|
      if(@vocables[lesson.id])
        if(nil == @vocable_view_models[lesson.id])
          @vocable_view_models[lesson.id] = create_vocable_model
        end
        @vocables[lesson.id].each do |article|
          
          iter = @vocable_view_models[lesson.id].append
          
          article.each_with_index do |value, index|
            if(nil == value)
              iter.set_value(index, 1)
            else
              iter.set_value(index, value)
            end
          end            
          
        end
        
      end
    end
  end
  
  #  def add_items
  #    item = Item.new(3, 'bottles of coke', true)
  #    @articles.push(item)
  #    
  #    item = Item.new(5, 'packages of noodles', true)
  #    @articles.push(item)
  #    
  #    item = Item.new(2, 'packages of chocolate chip cookies', true)
  #    @articles.push(item)
  #    
  #    item = Item.new(1, 'can vanilla ice cream', true)
  #    @articles.push(item)
  #    
  #    item = Item.new(6, 'eggs', true)
  #    @articles.push(item)
  #  end
  
  def add_lesson_columns(treeview)
    model = treeview.model
    
    # number column
    renderer = Gtk::CellRendererText.new
    renderer.signal_connect('edited') do |*args|
      lesson_cell_edited(*args.push(model))
    end
    treeview.insert_column(-1, 'No', renderer,
    {
      :text => L_COLUMN_NUMBER,
      :editable => L_COLUMN_EDITABLE,
    })
    def renderer.column
      L_COLUMN_NUMBER
    end
    
    # name column
    renderer = Gtk::CellRendererText.new
    renderer.signal_connect('edited') do |*args|
      lesson_cell_edited(*args.push(model))
    end
    def renderer.column
      L_COLUMN_NAME
    end
    treeview.insert_column(-1, 'Name', renderer,
    {
      :text => L_COLUMN_NAME,
      :editable => L_COLUMN_EDITABLE,
    })
    
    # selected column
    renderer = Gtk::CellRendererToggle.new
    renderer.expander = true
    renderer.signal_connect('toggled') do |*args|
      lesson_cell_toggeled(*args.push(model))
    end
    def renderer.column
      L_COLUMN_SELECTED
    end
    treeview.insert_column(-1, 'Sel.', renderer,
    {
      :active => L_COLUMN_SELECTED,
      :activatable => L_COLUMN_EDITABLE,
    })
    
    # progress column
    renderer = Gtk::CellRendererText.new
    renderer.signal_connect('edited') do |*args|
      lesson_cell_edited(*args.push(model))
    end
    def renderer.column
      L_COLUMN_PROGRESS
    end
    col = Gtk::TreeViewColumn.new('Progress', renderer, :text => L_COLUMN_PROGRESS)
    treeview.append_column(col)
    
    col.set_cell_data_func(renderer) do |col, renderer, model, iter|
      value = iter[L_COLUMN_PROGRESS].to_i
      
      if (0 > value)
        renderer.cell_background_gdk = NO_COLOR_BG
        renderer.foreground_gdk = NO_COLOR_FG
        renderer.text = "N/A"
      elsif (0 == value)
        renderer.cell_background_gdk = NO_COLOR_BG
        renderer.foreground_gdk = NO_COLOR_FG
        renderer.text = "#{renderer.text}%"
      elsif (20 > value)
        renderer.cell_background_gdk = WHITE_COLOR_BG
        renderer.foreground_gdk = WHITE_COLOR_FG
        renderer.text = "#{renderer.text}%"
      elsif (40 > value)
        renderer.cell_background_gdk = YELLOW_COLOR_BG
        renderer.foreground_gdk = YELLOW_COLOR_FG
        renderer.text = "#{renderer.text}%"
      elsif (60 > value)
        renderer.cell_background_gdk = GREEN_COLOR_BG
        renderer.foreground_gdk = GREEN_COLOR_FG
        renderer.text = "#{renderer.text}%"
      elsif (80 > value)
        renderer.cell_background_gdk = BLUE_COLOR_BG
        renderer.foreground_gdk = BLUE_COLOR_FG
        renderer.text = "#{renderer.text}%"
      elsif (100 > value)
        renderer.cell_background_gdk = RED_COLOR_BG
        renderer.foreground_gdk = RED_COLOR_FG
        renderer.text = "#{renderer.text}%"
      elsif (100 == value)
        renderer.cell_background_gdk = BLACK_COLOR_BG
        renderer.foreground_gdk = BLACK_COLOR_FG
        renderer.text = "#{renderer.text}%"
      end
    end    
    
  end
  
  def add_vocable_columns(treeview)
    
    # number column
    renderer = Gtk::CellRendererText.new
    renderer.signal_connect('edited') do |*args|
      vocable_cell_edited(*args.push(treeview))
    end
    treeview.insert_column(-1, 'No', renderer,
    {
      :text => V_COLUMN_NUMBER,
      :editable => V_COLUMN_EDITABLE,
    })
    def renderer.column
      V_COLUMN_NUMBER
    end
    
    # hanzi column
    renderer = Gtk::CellRendererText.new
    renderer.signal_connect('edited') do |*args|
      vocable_cell_edited(*args.push(treeview))
    end
    def renderer.column
      V_COLUMN_HANZI
    end
    treeview.insert_column(-1, '汉字', renderer,
    {
      :text => V_COLUMN_HANZI,
      :editable => V_COLUMN_EDITABLE,
    })
    
    # pinyin column
    renderer = Gtk::CellRendererText.new
    renderer.signal_connect('edited') do |*args|
      vocable_cell_edited(*args.push(treeview))
    end
    def renderer.column
      V_COLUMN_PINYIN
    end
    treeview.insert_column(-1, 'Pinyin', renderer,
    {
      :text => V_COLUMN_PINYIN,
      :editable => V_COLUMN_EDITABLE,
    })
    
    # english column
    renderer = Gtk::CellRendererText.new
    renderer.signal_connect('edited') do |*args|
      vocable_cell_edited(*args.push(treeview))
    end
    def renderer.column
      V_COLUMN_ENGLISH
    end
    treeview.insert_column(-1, 'English', renderer,
    {
      :text => V_COLUMN_ENGLISH,
      :editable => V_COLUMN_EDITABLE,
    })
    
    # progress column
    renderer = Gtk::CellRendererText.new
    renderer.signal_connect('edited') do |*args|
      vocable_cell_edited(*args.push(treeview))
    end
    def renderer.column
      V_COLUMN_PROGRESS
    end
    col = Gtk::TreeViewColumn.new('Progress', renderer, :text => V_COLUMN_PROGRESS)
    treeview.append_column(col)
    
    col.set_cell_data_func(renderer) do |col, renderer, model, iter|
      value = iter[V_COLUMN_PROGRESS].to_i
      
      if (0 > value)
        renderer.cell_background_gdk = NO_COLOR_BG
        renderer.foreground_gdk = NO_COLOR_FG
        renderer.text = "N/A"
      elsif (0 == value)
        renderer.cell_background_gdk = NO_COLOR_BG
        renderer.foreground_gdk = NO_COLOR_FG
        renderer.text = "#{renderer.text}%"
      elsif (20 > value)
        renderer.cell_background_gdk = WHITE_COLOR_BG
        renderer.foreground_gdk = WHITE_COLOR_FG
        renderer.text = "#{renderer.text}%"
      elsif (40 > value)
        renderer.cell_background_gdk = YELLOW_COLOR_BG
        renderer.foreground_gdk = YELLOW_COLOR_FG
        renderer.text = "#{renderer.text}%"
      elsif (60 > value)
        renderer.cell_background_gdk = GREEN_COLOR_BG
        renderer.foreground_gdk = GREEN_COLOR_FG
        renderer.text = "#{renderer.text}%"
      elsif (80 > value)
        renderer.cell_background_gdk = BLUE_COLOR_BG
        renderer.foreground_gdk = BLUE_COLOR_FG
        renderer.text = "#{renderer.text}%"
      elsif (100 > value)
        renderer.cell_background_gdk = RED_COLOR_BG
        renderer.foreground_gdk = RED_COLOR_FG
        renderer.text = "#{renderer.text}%"
      elsif (100 == value)
        renderer.cell_background_gdk = BLACK_COLOR_BG
        renderer.foreground_gdk = BLACK_COLOR_FG
        renderer.text = "#{renderer.text}%"
      end
    end
  end
  
  def lesson_cell_edited(cell, path_string, new_text, model)
    path = Gtk::TreePath.new(path_string)
    column = cell.column
    
    
    iter = model.get_iter(path)
    case column
    when L_COLUMN_NUMBER
      i = iter.path.indices[0]
      @lessons[i].number = new_text.to_i
      iter.set_value(column, @lessons[i].number)
    when L_COLUMN_NAME
      i = iter.path.indices[0]
      @lessons[i].name = new_text
      iter.set_value(column, @lessons[i].name)
      #    when L_COLUMN_PROGRESS
      #      i = iter.path.indices[0]
      #      @articles[i].progress = new_text
      #      iter.set_value(column, @articles[i].progress)
      #    when L_COLUMN_SELECTED
      #      i = iter.path.indices[0]
      #      @lessons[i].selected = new_text
      #      iter.set_value(column, @lessons[i].selected)
    end
  end
  
  def lesson_cell_toggeled(cell, path_string, model)
    path = Gtk::TreePath.new(path_string)
    column = cell.column
    
    iter = model.get_iter(path)
    case column
    when L_COLUMN_SELECTED
      i = iter.path.indices[0]
      @lessons[i].selected = !@lessons[i].selected
      iter.set_value(column, @lessons[i].selected)
    end
  end
  
  def vocable_cell_edited(cell, path_string, new_text, treeview)
    path = Gtk::TreePath.new(path_string)
    model = treeview.model
    
    column = cell.column
    
    iter = model.get_iter(path)
    case column
    when V_COLUMN_NUMBER
      i = iter.path.indices[0]
      @vocables[@current_lesson][i].number = new_text.to_i
      iter.set_value(column, @vocables[@current_lesson][i].number)
    when V_COLUMN_HANZI
      i = iter.path.indices[0]
      @vocables[@current_lesson][i].hanzi = new_text
      iter.set_value(column, @vocables[@current_lesson][i].hanzi)
    when V_COLUMN_PINYIN
      i = iter.path.indices[0]
      @vocables[@current_lesson][i].pinyin = new_text
      iter.set_value(column, @vocables[@current_lesson][i].pinyin)
    when V_COLUMN_ENGLISH
      i = iter.path.indices[0]
      @vocables[@current_lesson][i].english = new_text
      iter.set_value(column, @vocables[@current_lesson][i].english)
    end
  end
  
  def add_lesson(lesson_model)
    @lesson_id = @lesson_id +1;
    foo = Lesson.new(@lesson_id, @lessons.length+1, 'New Lesson', false, '0%', true)
    @lessons.concat([foo])
    
    iter = lesson_model.append
    foo.each_with_index do |value, index|
      iter.set_value(index, value)
    end
  end
  
  def add_vocable(vocable_model)
    if(nil != vocable_model)
      foo = Vocable.new(@vocables[@current_lesson].length+1, '', '', '', '0%', true, 0, 0, 0, 0, 0, 0)
      @vocables[@current_lesson].concat([foo])
      
      iter = vocable_model.append
      foo.each_with_index do |value, index|
        iter.set_value(index, value)
      end
    end
  end
  
  def remove_lesson(treeview)
    model = treeview.model
    selection = treeview.selection
    
    if iter = selection.selected
      @lessons.delete_at(iter.path.indices[0])
      model.remove(iter)
    end
  end
  
  def remove_vocable(treeview)
    model = treeview.model
    selection = treeview.selection
    
    if iter = selection.selected
      @vocables[@current_lesson].delete_at(iter.path.indices[0])
      model.remove(iter)
    end
  end
  
  
  
  
  def on_main_window_delete_event(widget, arg0)
    Gtk.main_quit
  end
  
  
  def on_new_lesson_button_clicked(widget)
    add_lesson(@lesson_view.model)
    recalculate_progress
  end
  
  def on_new_vocable_button_clicked(widget)
    add_vocable(@vocable_view.model)
    recalculate_progress
  end
  
  def on_delete_lesson_button_clicked(widget)
    remove_lesson(@lesson_view)
    recalculate_progress
  end
  
  def on_delete_vocable_button_clicked(widget)
    remove_vocable(@vocable_view)
    recalculate_progress
  end
  
  def on_reset_vocable_score_clicked(widget)
    selection = @vocable_view.selection
    
    if iter = selection.selected
      i = iter.path.indices[0]
      @vocables[@current_lesson][i].h_p = 0
      @vocables[@current_lesson][i].h_e = 0
      @vocables[@current_lesson][i].p_h = 0
      @vocables[@current_lesson][i].p_e = 0
      @vocables[@current_lesson][i].e_h = 0
      @vocables[@current_lesson][i].e_p = 0
    end
    
    recalculate_progress
  end
  
  def on_lesson_view_cursor_changed(widget)
    i = widget.selection.selected[L_COLUMN_ID]
    if(nil == @vocables[i])
      @vocable_view_models[i] = create_vocable_model
      @vocables[i] = []
    end
    @vocable_view.model = @vocable_view_models[i]
    @current_lesson = i
  end
  
  def load(filename)
    if(File.file? filename)
      loaded = open(filename) {|f| YAML.load(f)}
      @lesson_id = loaded['lesson_id']
      @lessons = loaded['lessons']
      @vocables = loaded['vocables']
      update_lesson_model
      update_vocable_model
      recalculate_progress
    end
  end
  
  def save(filename)
    to_save = {'lesson_id' => @lesson_id, 'lessons' => @lessons, 'vocables' => @vocables}
    open(filename,'w'){|f| YAML.dump(to_save,f)}
  end
  
  def on_notebook1_switch_page(widget, arg0, arg1)  
    case arg1
    when PAGE_OVERVIEW
      recalculate_progress
    when PAGE_LEARN
      @current_learning = 0;
      @learning = []
      score = -1 * 6
      while (MAX_SCORE * 6 > score) do
        @lessons.each do |lesson|
          if(lesson.selected)
            @vocables[lesson.id].each_with_index do |vocable, id| 
              if score == (vocable.h_p + vocable.h_e + vocable.p_h + vocable.p_e + vocable.e_h + vocable.e_p)
                @learning.concat([vocable])
              end
            end
          end
        end
        score += 1
      end
      if(0 == @learning.length)
        @current_learning = -1
      end
      update_learn_view
    when PAGE_ASK
      @current_asking = 0;
      @asking = []
      @asking_also = []
      
      @last_word_status_label_a.markup = ""
      @last_word_status_label_b.markup = ""
      @last_word_status_label_c.markup = ""
      @last_word.markup = ""
      
      score = -1
      while (MAX_SCORE > score && @set_questions_per_session.text.to_i > @asking.length) do
        @lessons.each do |lesson|
          if(lesson.selected)
            @vocables[lesson.id].each_with_index do |vocable, id| 
              if ((score == vocable.h_p && vocable.h_p <= vocable.h_e) || (score == vocable.h_e  && vocable.h_e < vocable.h_p)) && @set_ask_hanzi.active?
                #              if (score == vocable.h_p) || (score == vocable.h_e)
                foo = Question.new(vocable.hanzi, vocable.pinyin, :h_p, vocable.english, :h_e, lesson.id, id)
                @asking_also.concat([foo])
              end
              if ((score == vocable.p_h && vocable.p_h <= vocable.p_e) || (score == vocable.p_e  && vocable.p_e < vocable.p_h)) && @set_ask_pinyin.active?
                #              if (score == vocable.p_h) || (score == vocable.p_e)
                foo = Question.new(vocable.pinyin, vocable.hanzi, :p_h, vocable.english, :p_e, lesson.id, id)
                @asking_also.concat([foo])
              end
              if ((score == vocable.e_h && vocable.e_h <= vocable.e_p) || (score == vocable.e_p  && vocable.e_p < vocable.e_h)) && @set_ask_english.active?
                #              if (score == vocable.e_h) || (score == vocable.e_p)
                foo = Question.new(vocable.english, vocable.hanzi, :e_h, vocable.pinyin, :e_p, lesson.id, id)
                @asking_also.concat([foo])
              end
            end
          end
        end
        score += 1
        no_to_add = (@set_questions_per_session.text.to_i - 1)-@asking.length
        no_to_add = no_to_add < 0 ? 0 : no_to_add 
        @asking.concat(@asking_also.sort_by{ rand }[0..no_to_add])
      end
      if(0 == @asking.length)
        @current_asking = -1
      else
        @asking = @asking.sort_by { rand }
      end
      update_ask_view
    end
  end    
  
  def update_learn_view
    if(-1 == @current_learning)
      @hanzi_label.markup="<span size='#{1024*30}'>Nothing\nSelected!</span>"
      @pinyin_label.markup=""
      @english_label.markup=""
    else
      @hanzi_label.markup="<span size='#{1024*100}'>#{@learning[@current_learning].hanzi}</span>"
      size = get_text_size(@learning[@current_learning].pinyin.length)
      @pinyin_label.markup="<span size='#{size}' font_family='serif'>#{@learning[@current_learning].pinyin}</span>"
      size = get_text_size(@learning[@current_learning].english.length)
      @english_label.markup="<span size='#{size}' font_family='serif'>#{@learning[@current_learning].english}</span>"      
    end
  end
  
  def get_text_size(characters)
    downscale = characters/10.to_i
    size = 1024*(50-downscale*8)
    size = size < 10240 ? 10240 : size
    return size
  end
  
  def get_character_size
    return 1024*100
  end
  
  def update_ask_view
    0.upto(5) do |i|
      @answer_buttons_a[i].label = ""
      @answer_buttons_a_label[i].text = ""
      @answer_buttons_b[i].label = ""
      @answer_buttons_c[i].label = ""
    end
    @answer_button_a_skip.set_active(true)
    @answer_button_b_skip.set_active(true)
    @answer_button_c_skip.set_active(true)
    
    if(-1 == @current_asking)
      @asked_word_label.markup="<span size='#{1024*30}'>Nothing\nSelected!</span>"
      @asking_progress.fraction = 0
      @asking_progress.text = ""
      
    elsif (@asking.length == @current_asking)
      @asked_word_label.markup="<span size='#{1024*30}'>Finished</span>"
      @asking_progress.fraction = @current_asking / @asking.length.to_f
      @asking_progress.text = "(#{@current_asking}/#{@asking.length})"
    else
      
      #update progressbar
      @asking_progress.fraction = @current_asking / @asking.length.to_f
      @asking_progress.text = "(#{@current_asking}/#{@asking.length})"
      
      #show new asked word
      if(:h_p == @asking[@current_asking].type_a || :h_e == @asking[@current_asking].type_a)
        @asked_word_label.markup="<span size='#{1024*100}'>#{@asking[@current_asking].asked_word}</span>"
      else
        size = get_text_size(@asking[@current_asking].asked_word.length)
        @asked_word_label.markup="<span size='#{size}' font_family='serif'>#{@asking[@current_asking].asked_word}</span>"
      end
      
      @anser_box_a.hide
      @anser_box_b.hide
      @anser_box_c.hide
      
      
      #show translaion options A
      if(:p_h == @asking[@current_asking].type_a || :e_h == @asking[@current_asking].type_a)
        hanzi = get_hanzi(@asking[@current_asking].lesson_id,@asking[@current_asking].right_answer_a, @asking[@current_asking].asked_word)
        0.upto(5) do |i|
          @answer_buttons_a_label[i].markup = "<span size='#{1024*30}'>#{hanzi[i]}</span>"
        end
        @anser_box_a.show
        
      elsif(:h_p == @asking[@current_asking].type_a || :e_p == @asking[@current_asking].type_a)
        pinyin = get_pinyin(@asking[@current_asking].lesson_id,@asking[@current_asking].right_answer_a, @asking[@current_asking].asked_word)
        0.upto(5) do |i|
          @answer_buttons_b[i].label=pinyin[i]
        end
        @anser_box_b.show
        
      elsif(:h_e == @asking[@current_asking].type_a || :p_e == @asking[@current_asking].type_a)
        english = get_english(@asking[@current_asking].lesson_id,@asking[@current_asking].right_answer_a, @asking[@current_asking].asked_word)
        0.upto(5) do |i|
          @answer_buttons_c[i].label=english[i]
        end
        @anser_box_c.show
        
      end    
      
      #show translaion options B
      if(:p_h == @asking[@current_asking].type_b || :e_h == @asking[@current_asking].type_b)
        hanzi = get_hanzi(@asking[@current_asking].lesson_id,@asking[@current_asking].right_answer_b, @asking[@current_asking].asked_word)
        0.upto(5) do |i|
          @answer_buttons_a[i].label=hanzi[i]
        end
        @anser_box_a.show
        
      elsif(:h_p == @asking[@current_asking].type_b || :e_p == @asking[@current_asking].type_b)
        pinyin = get_pinyin(@asking[@current_asking].lesson_id,@asking[@current_asking].right_answer_b, @asking[@current_asking].asked_word)
        0.upto(5) do |i|
          @answer_buttons_b[i].label=pinyin[i]
        end
        @anser_box_b.show
        
      elsif(:h_e == @asking[@current_asking].type_b || :p_e == @asking[@current_asking].type_b)
        english = get_english(@asking[@current_asking].lesson_id,@asking[@current_asking].right_answer_b, @asking[@current_asking].asked_word)
        0.upto(5) do |i|
          @answer_buttons_c[i].label=english[i]
        end
        @anser_box_c.show
        
      end    
      
      @current_right_answer_a = rand(8)-2
      if 0 > @current_right_answer_a
        @current_right_answer_a = -1
      else
        if(:p_h == @asking[@current_asking].type_a || :e_h == @asking[@current_asking].type_a)
          @answer_buttons_a_label[@current_right_answer_a].markup="<span size='#{1024*30}'>#{@asking[@current_asking].right_answer_a}</span>"
        elsif(:h_p == @asking[@current_asking].type_a || :e_p == @asking[@current_asking].type_a)
          @answer_buttons_b[@current_right_answer_a].label = @asking[@current_asking].right_answer_a
        else
          @answer_buttons_c[@current_right_answer_a].label = @asking[@current_asking].right_answer_a
        end
      end
      
      @current_right_answer_b = rand(8)-2
      if 0 > @current_right_answer_b
        @current_right_answer_b = -1
      else
        if(:h_e == @asking[@current_asking].type_b || :p_e == @asking[@current_asking].type_b)
          @answer_buttons_c[@current_right_answer_b].label = @asking[@current_asking].right_answer_b
        elsif(:h_p == @asking[@current_asking].type_b || :e_p == @asking[@current_asking].type_b)
          @answer_buttons_b[@current_right_answer_b].label = @asking[@current_asking].right_answer_b
        else
          @answer_buttons_a[@current_right_answer_b].label = @asking[@current_asking].right_answer_b        
        end
      end
    end
    
  end
  
  def get_hanzi(lesson_id, without1, without2)
    hanzi = []
    @vocables[lesson_id].each do |vocable| 
      if !(without1 == vocable.hanzi || without1 == vocable.pinyin || without1 == vocable.english ||
           without2 == vocable.hanzi || without2 == vocable.pinyin || without2 == vocable.english)
        hanzi.concat([vocable.hanzi])
      end
    end
    return hanzi.sort_by { rand }
  end
  
  def get_pinyin(lesson_id, without1, without2)
    pinyin = []
    @vocables[lesson_id].each do |vocable| 
      if !(without1 == vocable.hanzi || without1 == vocable.pinyin || without1 == vocable.english ||
           without2 == vocable.hanzi || without2 == vocable.pinyin || without2 == vocable.english)
        pinyin.concat([vocable.pinyin])
      end
    end
    return pinyin.sort_by { rand } 
  end
  
  def get_english(lesson_id, without1, without2)
    english = []
    @vocables[lesson_id].each do |vocable| 
      if !(without1 == vocable.hanzi || without1 == vocable.pinyin || without1 == vocable.english ||
           without2 == vocable.hanzi || without2 == vocable.pinyin || without2 == vocable.english)
        english.concat([vocable.english])
      end
    end
    return english.sort_by { rand }
  end
  
  
  def on_next_button_clicked(widget)
    if(-1 != @current_learning)
      @current_learning += 1
      if(@current_learning >= @learning.length)
        @current_learning = 0
      end
      update_learn_view
    end
  end
  
  def on_previous_button_clicked(widget)
    if(-1 != @current_learning)
      @current_learning -= 1
      if(@current_learning < 0)
        @current_learning = @learning.length-1
      end
      update_learn_view
    end
  end
  
  def on_ok_button_clicked(widget)
    if (@asking.length > @current_asking && 0 <= @current_asking)
      if(:h_p == @asking[@current_asking].type_a || :h_e == @asking[@current_asking].type_a)
        @last_word.markup = "Last: <b><span size='#{1024*30}'>#{@asking[@current_asking].asked_word}</span></b>"
      else
        @last_word.markup = "Last: <b>#{@asking[@current_asking].asked_word}</b>"
      end
      if find_answer_a == @current_right_answer_a
        if(:p_h == @asking[@current_asking].type_a || :e_h == @asking[@current_asking].type_a)
          @last_word_status_label_a.markup = "<span foreground='darkgreen'><b>A was right.</b></span> (was \"<b><span size='#{1024*30}'>#{@asking[@current_asking].right_answer_a}</span></b>\")"
        else
          @last_word_status_label_a.markup = "<span foreground='darkgreen'><b>A was right.</b></span> (was \"<b>#{@asking[@current_asking].right_answer_a}</b>\")"
        end
        if -1 != @current_right_answer_a
          lesson = @asking[@current_asking].lesson_id
          vocable = @asking[@current_asking].vocable_id
          case @asking[@current_asking].type_a
          when :h_p
            @vocables[lesson][vocable].h_p += 1
          when :h_e
            @vocables[lesson][vocable].h_e += 1
          when :p_h
            @vocables[lesson][vocable].p_h += 1
          when :p_e
            @vocables[lesson][vocable].p_e += 1
          when :e_h
            @vocables[lesson][vocable].e_h += 1
          when :e_p
            @vocables[lesson][vocable].e_p += 1
          end
        end
        #      elsif find_answer_a == nil
        #        @last_word_status_label_a.markup = "(was \"<b>#{@asking[@current_asking].right_answer_a}</b>\")"      
      else
        @last_word_status_label_a.markup = "<span foreground='darkred'><b>A was wrong.</b></span> (was \"<b>#{@asking[@current_asking].right_answer_a}</b>\")"
        lesson = @asking[@current_asking].lesson_id
        vocable = @asking[@current_asking].vocable_id
        case @asking[@current_asking].type_a
        when :h_p
          @vocables[lesson][vocable].h_p -= @vocables[lesson][vocable].h_p == 0 ? 0 : 1
        when :h_e
          @vocables[lesson][vocable].h_e -= @vocables[lesson][vocable].h_e == 0 ? 0 : 1
        when :p_h
          @vocables[lesson][vocable].p_h -= @vocables[lesson][vocable].p_h == 0 ? 0 : 1
        when :p_e
          @vocables[lesson][vocable].p_e -= @vocables[lesson][vocable].p_e == 0 ? 0 : 1
        when :e_h
          @vocables[lesson][vocable].e_h -= @vocables[lesson][vocable].e_h == 0 ? 0 : 1
        when :e_p
          @vocables[lesson][vocable].e_p -= @vocables[lesson][vocable].e_p == 0 ? 0 : 1
        end
      end
      if find_answer_b == @current_right_answer_b
        @last_word_status_label_b.markup = "<span foreground='darkgreen'><b>B was right.</b></span> (was \"<b>#{@asking[@current_asking].right_answer_b}</b>\")"
        if -1 != @current_right_answer_b
          lesson = @asking[@current_asking].lesson_id
          vocable = @asking[@current_asking].vocable_id
          case @asking[@current_asking].type_b
          when :h_p
            @vocables[lesson][vocable].h_p += 1
          when :h_e
            @vocables[lesson][vocable].h_e += 1
          when :p_h
            @vocables[lesson][vocable].p_h += 1
          when :p_e
            @vocables[lesson][vocable].p_e += 1
          when :e_h
            @vocables[lesson][vocable].e_h += 1
          when :e_p
            @vocables[lesson][vocable].e_p += 1
          end
        end
        #      elsif find_answer_b == nil
        #        @last_word_status_label_b.markup = "(was \"<b>#{@asking[@current_asking].right_answer_b}</b>\")"      
      else
        @last_word_status_label_b.markup = "<span foreground='darkred'><b>B was wrong.</b></span> (was \"<b>#{@asking[@current_asking].right_answer_b}</b>\")"
        lesson = @asking[@current_asking].lesson_id
        vocable = @asking[@current_asking].vocable_id
        case @asking[@current_asking].type_b
        when :h_p
          @vocables[lesson][vocable].h_p -= @vocables[lesson][vocable].h_p == 0 ? 0 : 1
        when :h_e
          @vocables[lesson][vocable].h_e -= @vocables[lesson][vocable].h_e == 0 ? 0 : 1
        when :p_h
          @vocables[lesson][vocable].p_h -= @vocables[lesson][vocable].p_h == 0 ? 0 : 1
        when :p_e
          @vocables[lesson][vocable].p_e -= @vocables[lesson][vocable].p_e == 0 ? 0 : 1
        when :e_h
          @vocables[lesson][vocable].e_h -= @vocables[lesson][vocable].e_h == 0 ? 0 : 1
        when :e_p
          @vocables[lesson][vocable].e_p -= @vocables[lesson][vocable].e_p == 0 ? 0 : 1
        end
      end
      next_question
      update_ask_view
    end
  end
  
  def find_answer_a
    puts "find a"
    case @asking[@current_asking].type_a
    when :p_h
      0.upto(5) do |i|
        if @answer_buttons_a[i].active?
          return i
        end
      end
      if @answer_button_a_none.active?
        return -1
      end
    when :e_h
      0.upto(5) do |i|
        if @answer_buttons_a[i].active?
          return i
        end
      end
      if @answer_button_a_none.active?
        return -1
      end
    when :h_p
      0.upto(5) do |i|
        if @answer_buttons_b[i].active?
          return i
        end
      end
      if @answer_button_b_none.active?
        return -1
      end
    when :e_p
      0.upto(5) do |i|
        if @answer_buttons_b[i].active?
          return i
        end
      end
      if @answer_button_b_none.active?
        return -1
      end
    when :h_e
      0.upto(5) do |i|
        if @answer_buttons_c[i].active?
          return i
        end
      end
      if @answer_button_c_none.active?
        return -1
      end
    when :p_e
      0.upto(5) do |i|
        if @answer_buttons_c[i].active?
          return i
        end
      end
      if @answer_button_c_none.active?
        return -1
      end
    end
    
    return nil
  end  
  
  def find_answer_b
    case @asking[@current_asking].type_b
    when :p_h
      0.upto(5) do |i|
        if @answer_buttons_a[i].active?
          return i
        end
      end
      if @answer_button_a_none.active?
        return -1
      end
    when :e_h
      0.upto(5) do |i|
        if @answer_buttons_a[i].active?
          return i
        end
      end
      if @answer_button_a_none.active?
        return -1
      end
    when :h_p
      0.upto(5) do |i|
        if @answer_buttons_b[i].active?
          return i
        end
      end
      if @answer_button_b_none.active?
        return -1
      end
    when :e_p
      0.upto(5) do |i|
        if @answer_buttons_b[i].active?
          return i
        end
      end
      if @answer_button_b_none.active?
        return -1
      end
    when :h_e
      0.upto(5) do |i|
        if @answer_buttons_c[i].active?
          return i
        end
      end
      if @answer_button_c_none.active?
        return -1
      end
    when :p_e
      0.upto(5) do |i|
        if @answer_buttons_c[i].active?
          return i
        end
      end
      if @answer_button_c_none.active?
        return -1
      end
    end
    
    return nil
  end  
  
  def next_question
    if(-1 != @current_asking)
      @current_asking += 1
      if(@current_asking >= @asking.length)
        @current_asking = @asking.length
      end
    end
  end
  
  def on_skip_button_clicked(widget)
    @answer_button_a_skip.set_active(true)
    @answer_button_b_skip.set_active(true)
    
    on_ok_button_clicked(widget)
    update_ask_view
  end
  
  def recalculate_progress
    @lesson_view.model.each{|l_model, l_path, l_iter|
      li = l_iter.path.indices[0]
      if(nil == @vocable_view_models[@lessons[li].id] || nil == @vocable_view_models[@lessons[li].id].iter_first)
        @lessons[li].progress = "-1"
        l_iter.set_value(L_COLUMN_PROGRESS, @lessons[li].progress)
      else
        total_sum = 0
        total_num = 0
        @vocable_view_models[@lessons[li].id].each{|v_model, v_path, v_iter|
          sum = 0
          vi = v_iter.path.indices[0]
          vocable = @vocables[@lessons[li].id][vi]
          sum += MAX_SCORE > vocable.h_p ? vocable.h_p : MAX_SCORE
          sum += MAX_SCORE > vocable.h_e ? vocable.h_e : MAX_SCORE
          sum += MAX_SCORE > vocable.p_h ? vocable.p_h : MAX_SCORE
          sum += MAX_SCORE > vocable.p_e ? vocable.p_e : MAX_SCORE
          sum += MAX_SCORE > vocable.e_h ? vocable.e_h : MAX_SCORE
          sum += MAX_SCORE > vocable.e_p ? vocable.e_p : MAX_SCORE
          total_sum += sum
          total_num += 1
          @vocables[@lessons[li].id][vi].progress = "#{(sum*100)/(MAX_SCORE*6)}"
          v_iter.set_value(V_COLUMN_PROGRESS, @vocables[@lessons[li].id][vi].progress)
          #          @lesson_view.get_background_area(v_path, V_COLUMN_PROGRESS)
        }
        if(0 == total_num)
          @lessons[li].progress = "N/A"
          l_iter.set_value(V_COLUMN_PROGRESS, @lessons[li].progress)
        else        
          @lessons[li].progress = "#{(total_sum*100)/(MAX_SCORE*6*total_num)}"
          l_iter.set_value(V_COLUMN_PROGRESS, @lessons[li].progress)
        end
      end
      
    }
    
    #    @lessons.each do |lesson|
    #      if(nil == @vocables[lesson.id] || 0 == @vocables[lesson.id].length)
    #        lesson.progress = "N/A"
    #      else
    #        total_sum = 0
    #        @vocables[lesson.id].each do |vocable|
    #          sum = 0
    #          sum += MAX_SCORE > vocable.h_p ? vocable.h_p : MAX_SCORE
    #          sum += MAX_SCORE > vocable.h_e ? vocable.h_e : MAX_SCORE
    #          sum += MAX_SCORE > vocable.p_h ? vocable.p_h : MAX_SCORE
    #          sum += MAX_SCORE > vocable.p_e ? vocable.p_e : MAX_SCORE
    #          sum += MAX_SCORE > vocable.e_h ? vocable.e_h : MAX_SCORE
    #          sum += MAX_SCORE > vocable.e_p ? vocable.e_p : MAX_SCORE
    #          total_sum += sum
    #          vocable.progress = "#{(sum*100)/(MAX_SCORE*6)}%"
    #        end
    #        lesson.progress = "#{(total_sum*100)/(MAX_SCORE*6*@vocables[lesson.id].length)}%"        
    #      end
    #    end
  end
  
  def on_save1_activate(widget)
    save(@filename)
  end
  
  def on_save_as1_activate(widget)
    puts "on_save_as1_activate() is not implemented yet."
  end
  
  def on_quit1_activate(widget)
    Gtk.main_quit
  end
  
  
  
end



# Main program
if __FILE__ == $0
  # Set values as your own application. 
  PROG_PATH = "cvt.glade"
  PROG_NAME = "YOUR_APPLICATION_NAME"
  Gtk.init
  cvt = Cvt.new(PROG_PATH, nil, PROG_NAME)
  cvt.load(DEFAULT_FILENAME)
  Gtk.main
  cvt.save(DEFAULT_FILENAME)
end
