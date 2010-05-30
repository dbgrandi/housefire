#
# Lighthouse --> Campfire = housefire
#
# dbgrandi.in.2010
#
#
require 'rubygems'
require 'nokogiri'
require 'sanitize'
require 'broach'

class Housefire
  
  def initialize(*args)
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

          title = entry.css("title")[0].content
          puts "title = #{title}"
          case
          when title.include?("[Changeset] ")
            # changeset = [Changeset] <projectname>: Changeset [<sha>] by <user>
            # we don't care about these, github already posts it for us
            puts "Discarding Changeset message..."
          when title.include?("[Page] ")
            # page = [Page] <projectname>: <title>
            #     content needs html un-escaping
            e[:title] = title
            e[:author]  = entry.css("author name")[0].content
            e[:link] = entry.css("link")[0].attributes["href"].content
            message = "#{e[:title]} - #{e[:author]} #{e[:link]}"
            puts message + "\n\n\n"
            @room.speak(message)
          when title.include?("New ")
            # member = New <projectname> Project Member
            #     like "New axislivewebsite Project Member"
            message = entry.css("content")[0].content
            puts message + "\n\n\n"
            @room.speak(message)
          when title.include?(" Bulk Edit: ")
            # bulk edit = <projectname> Bulk Edit: <ticketlist no commas>
            #     also, href link is like http://wgrids.lighthouseapp.com/projects/45964/bulk_edits/19926
            e[:title]   = title
            e[:content] = Sanitize.clean(entry.css("content")[0].content)
            e[:author]  = entry.css("author name")[0].content
            e[:link]    = entry.css("link")[0].attributes["href"].content
            message = "#{e[:title]} - #{e[:content].gsub(/[^[:print:]]/, '').gsub(/&amp;/,'&')} #{e[:author]} #{e[:link]}"
            puts message + "\n\n\n"
            @room.speak(message)
          when title.include?("[Milestone] ")
            # milestone = [Milestone] <projectname>: <title>
            e[:title]   = title
            e[:content] = Sanitize.clean(entry.css("content")[0].content)
            e[:author]  = entry.css("author name")[0].content
            e[:link]    = entry.css("link")[0].attributes["href"].content
            message = "#{e[:title]} -- #{e[:content].gsub(/[^[:print:]]/, '').gsub(/&amp;/,'&')} - #{e[:author]} #{e[:link]}"
            puts message + "\n\n\n"
            @room.speak(message)
          when title[/\s\[#\d+\]$/] != nil
            # ticket takes the form <projectname>: comment...blah [#<num>]
            # e.g. <title type="html">weheartradio: It's possible to have multiple xmppclients trying to reconnect [#418]</title>
            e[:title]   = title
            #
            # tickets that were just created may not have any content
            #
            if entry.css("content").empty?
              e[:content] = "NEW"
            else
              content = Sanitize.clean(entry.css("content")[0].content)
              e[:content] =  (content.length > 200) ? content[0..200] + "..." : content
            end
            e[:author]  = entry.css("author name")[0].content
            e[:link]    = entry.css("link")[0].attributes["href"].content
            message = "#{e[:title]} -- #{e[:content]} - #{e[:author]} #{e[:link]}"
            puts message + "\n\n\n"
            @room.speak(message)
          else
            puts "Not a valid message...or perhaps a new format."
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
