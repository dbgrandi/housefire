#
# Lighthouse --> Campfire = housefire
#
# dbgrandi.in.2010
#
require 'rubygems'
require 'nokogiri'
require 'sanitize'
require 'broach'

class Housefire
  
  def initialize(*args)
    #
    # required config:
    #   lhuser: <your lh login>
    #   lhpass: <your lh password>
    #   account: <your campfire domain>
    #   token: <your campfire auth token>
    #   room: <the campfire room to talk to>
    #
    # optional config:
    #   ssl: <use ssl for campfire?>
    #   lhcache: <where to put the lighthouse event cache>
    #
    @conf = YAML.load(File.read(File.expand_path("~/.housefire")))
    @conf['ssl'] ||= false
    @conf['lhcache'] ||= File.expand_path("~/.housefire.tmp")
    
    Broach.settings = {
      'account' => @conf['account'],
      'token'   => @conf['token'],
      'use_ssl' => @conf['ssl'],
    }
    @room = Broach::Room.find_by_name(@conf['room'])
  end
  
  def run
    while true
      poll_lighthouse
      sleep 60
    end
  end

  def poll_lighthouse
    puts "running..."
    # check for a cached copy of the last feed pull
    recent_items = load_db(@conf['lhcache']) || {}

    doc = Nokogiri::XML(`curl -su "#{@conf['lhuser']}":#{@conf['lhpass']} https://#{@conf['lhdomain']}.lighthouseapp.com/events.atom`)

    # parse out events into things we recognize (changeset, ticket, etc.)
    doc.css("entry").each do |entry|
      begin
        id = entry.css("id")[0].content.split("Event/")[1].to_i

        # DON'T notify the same event more than once
        if !recent_items.key?(id)
          e = {}
          e[:id] = id

          # DON'T notify changesets, github already does that
          title = entry.css("title")[0].content
          if !title.include?("[Changeset] ")
            e[:title]   = title
            e[:content] = Sanitize.clean(entry.css("content")[0].content)
            e[:author]  = entry.css("author name")[0].content
            e[:link]    = entry.css("link")[0].attributes["href"].content
            e[:date]    = entry.css("published")[0].content

            message = "#{e[:author]}: #{e[:title]} -- #{e[:content]}".gsub(/[^[:print:]]/, '').gsub(/&amp;/,'&')
            puts message
            puts "\n\n\n"
            @room.speak(message)
          end
      #    recent_items = recent_items.sort.last 10
          recent_items[id] = e
          save_db(@conf['lhcache'], recent_items)
        end
      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
      end
    end
  end

  def save_db(file, object)
    f = File.open(file, "w")
    f.write Marshal.dump(object)
    f.close
    true
  end

  def load_db(file)
    if File.exists?(file)
      if marshalled_data = File.read(file)
        Marshal.load(marshalled_data)
      end
    end
  end

end #class
