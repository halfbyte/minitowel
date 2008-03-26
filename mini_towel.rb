require 'rubygems'
require "camping"
require 'camping/session'
require 'RedCloth'

Camping.goes :MiniTowel

module MiniTowel
  include Camping::Session
end

module MiniTowel::Models
  
  class Entity < Base
    validates_presence_of :title, :description
  end
  
  class CreateMiniTowel < V 0.1
    def self.up
      create_table :minitowel_entities, :force => true do |t|
        t.string :title
        t.text :description
        t.timestamps
      end
    end
    def self.down
      drop_table :minitowel_entities
    end
  end

  class AddMetaData < V 0.2
    def self.up
      add_column :minitowel_entities, :effort, :string
    end
    def self.down
      remove_column :minitowel_entities, :effort
    end
  end
  class AddPositioning < V 0.3
    def self.up
      add_column :minitowel_entities, :position, :integer
    end
    def self.down
      remove_column :minitowel_entities, :position
    end
  end
end
  
module MiniTowel::Controllers
  class Index < R '/'
    def get
      @entities = Entity.find(:all, :order => 'position ASC')
      @title = "All Cards"
      render :list
    end
  end
  class New < R '/new'
    def get
      @entity = Entity.new
      render :new
    end
    def post
      @entity = Entity.new(@input.entity)
      if @entity.save
        redirect Index
      else
        render :new
      end
    end
  end

  class Edit < R '/edit/(\d+)'
    def get(id)
      @entity = Entity.find(id)
      render :edit
    end
    def post(id)
      @entity = Entity.find(id)
      if @entity.update_attributes(@input.entity)
        redirect Index
      else
        render :edit
      end
    end
  end

  class Order < R '/order'
    def post
      ids = @input.cardList
      ids.each_with_index do |id, i|
        Entity.find(id).update_attribute(:position, i)
      end
      "all is well"
    end
  end

  class Zoom < R '/zoom'
    def post
      zoom = @input.zl.to_i
      @state[:zoom_level] = zoom
      "all is well"
    end
  end

  class Static < R '/static/(.+)'
    MIME_TYPES = {'.css' => 'text/css', '.js' => 'text/javascript', '.jpg' => 'image/jpeg', '.png' => 'image/png', '.gif' => 'image/gif'}
    PATH = File.expand_path(File.dirname(__FILE__))
    def get(path)
      @headers['Content-Type'] = MIME_TYPES[path[/\.\w+$/, 0]] || "text/plain"
      unless path.include? ".." # prevent directory traversal attacks
        @headers['X-Sendfile'] = "#{PATH}/static/#{path}"
      else
        @status = "403"
        "403 - Invalid path"
      end
    end
  end
end

module MiniTowel::Views
  # this tewtally suckz
  ########################## layout ##############################
  def layout
    html do
      head do
        title((@title ? @title : "" ) + " - miniTowel")
        link :rel => "stylesheet", 
              :href => R(Static, 'stylesheets/style.css'), 
              :type => "text/css", 
              :media => 'screen'
        script :src => R(Static, "javascripts/prototype.js"), 
                :type => 'text/javascript'
        script :src => R(Static, "javascripts/scriptaculous.js"), 
                :type => 'text/javascript'          
        script :src => R(Static, "javascripts/application.js"), 
                :type => 'text/javascript'          
        script :type => 'text/javascript' do
          self << <<-END
          // configuring some dynamic stuff
          var oldSize = "#{@state[:zoom_level] ||'1'}"
          var zoomURL = "#{URL(Zoom)}"
          var orderURL = "#{URL(Order)}"
          END
        end
      end
      body do
        div.header! do
          h1 do
            a "miniTowel", :href => R(Index)
          end
          p "a UI prototyping environment - hässlich by design"
          img :src => R(Static, 'images/spinner.gif'), 
              :id => 'spinner', 
              :style => 'display:none'
        end
        div.content! do
          self << yield
        end
        div.footer! do
          "&copy; 2008 jan krutisch - camping ftw! - inspired by the 42 towel dudes"
        end
      end
    end
  end

  ########################## action templates ##############################

  def list      
    ul.localNavigation.clearfix do
      li do
        a :href => R(New) do 
          img :src => R(Static, "images/new.png"), 
              :alt => 'New', 
              :title => 'New', 
              :class => 'imageButton'
        end
      end
      li "Zoom:", :style => 'margin-top:10px;'
      li do
        div.zoomSlider!.track :style => "width:10em;" do
          div.zoomSliderHandle!.handle "", :style => 'width:0.5em;' 
        end
      end
    end      
    ul :class => "cards clearfix corkboard size#{@state[:zoom_level]||1}", 
        :id => 'cardList' do
      @entities.each do |entity|
        _card(entity)
      end
    end
  end

  def new
    div.corkboard do
      h2 "Create new Card"
      div.hugeCard do
        errors_for(@entity)
        form :action => R(New), :method => 'POST' do
          _form
          p do
            input :type => "submit", :value => "Create"
            self << " or "
            a "Cancel", :href => R(Index) 
          end
        end
      end
    end
  end

  def edit
    div.corkboard do
      h2 "Edit Card"
      div.hugeCard do
        errors_for(@entity)
        form :action => R(Edit, @entity), :method => 'POST' do
          _form
          p do
            input :type => "submit", :value => "Save"
            self << " or "
            a "Cancel", :href => R(Index) 
          end
        end
      end
    end
  end
  
  ################################# partials ############################### 

  def _card(entity)
    li :id => "card_#{entity.id}", :class => 'card' do
      h2 "#{entity.title}"
      div.description do 
        textilize(entity.description)
      end
      div.effort entity.effort
      table.metadata do
        tr do
          th :colspan => 2 do
            "Metadata"
          end
        end
        tr do
          th "Created at:"
          td entity.created_at.to_s(:long)
        end
        tr do
          th "Last Update at:"
          td entity.updated_at.to_s(:long)
        end
        tr do
          th "Estimated Effort:"
          td entity.effort
        end
      end
      ul.cardTools do
        li do
          a :href => R(Edit, entity.id), :class => 'editLink' do
            img :src => R(Static, "images/edit.png"), 
                :alt => 'Edit', 
                :title => 'Edit', 
                :class => 'imageButton'
          end
        end
        li do
          a :href => R(Edit, entity.id) do
            img :src => R(Static, "images/delete.png"), 
                :alt => 'Delete', 
                :title => 'Delete', 
                :class => 'imageButton'
          end
        end
      end
    end
  end

  def _form      
    p do
      label :for => 'entity_title' do
        self << "Title "
      end
      input :type => 'text', 
            :name => 'entity[title]', 
            :value => @entity.title, 
            :size => 40, 
            :class => 'huge', 
            :id => 'entity_title'
    end
    p do
      label :for => 'entity_description' do
        self << "Description "
      end
      textarea :name => 'entity[description]', 
                :cols => 70, 
                :rows => 10, 
                :id => 'entity_description' do
        @entity.description
      end
    end   
    p do
      label :for => 'entity_effort' do
        self << "Effort "
      end
      input :type => 'text', 
            :name => 'entity[effort]', 
            :value => @entity.effort, 
            :size => 5, 
            :id => 'entity_effort'
    end
  end
end


module MiniTowel::Helpers
  def textilize(text)
    RedCloth.new(text).to_html
  end
end

def MiniTowel.create
  Camping::Models::Session.create_schema
  MiniTowel::Models.create_schema
end