#!/usr/bin/env ruby

require "fcgi"
require "json"
require "socket"
require "yaml"

@homedir = "/var/www/localhost/htdocs/frotz"
@port = 1982
@pid = nil
@game = nil
@socket = nil

def print_channel( text )
    string = { :response_type => 'in_channel',
               :text => text }.to_json
    puts string
end

def run_game( game )
    # Kill any existing game
    if ( @pid )
        Process.kill("KILL", @pid)
        puts "#{ @game } killed (PID: #{ @pid })"
        @socket.close
    end

    puts ":floppy_disk: Loading #{ game }"
    
    # Fork a new one and connect to it
    @pid = fork do
        exec "nc -l -p #{ @port } -c '/usr/games/bin/frotz #{ game }'"
    end
    Process.detach(@pid)

    puts "#{ game } loaded (PID: #{ @pid })"
    @socket = TCPSocket.new 'localhost', @port
    socket_handler( @socket )

    @game = game
end

def socket_handler( socket, text=nil )
    readfds, writefds, exceptfds = select([@socket], nil, nil, 1)
    
    if text
        socket.puts text
    end

    begin
        if readfds
            while out = socket.recvmsg_nonblock(10000)
                puts out
            end
        end
    rescue
    end

end

def load_game ( game )
    if !File.exists? "#{ Dir.pwd }/dat/#{ game }"
        puts "Game #{ game } not found}"
    end

    if ( @pid )
        # Save first
    end

    run_game ( game )
end

def get_games
    puts "*Games* :video_game:\n-----\n"
    Dir.chdir("dat")
    puts Dir.entries(".").select { |f| File.file? f }.sort
end

def help_text
    puts "Slack Frotz
-----
*Special Commands*
*help* - This page
*list* - List games
*load <game>* - Load a game from the list
*save* - Save the existing game
"
end

def command_handler( cmd )
    if @pid.nil?
        puts "No game loaded."
        exit
    end

    input( cmd )
end

FCGI.each_cgi {|cgi|
    puts cgi.header("application/json")
    
    if ( cgi['token'] != cgi.env_table["SLACK_TOKEN"] )
        puts 'Invalid token.'
        exit
    end

    case cgi['text'].downcase
    when 'help'
        help_text
    when 'list'
        get_games
    when 'status'
        if @game
            puts "Game: #{ @game } PID: #{ @pid }"
        else
            puts "No game loaded."
        end
    when 'save'
    when /load (\S+)/
        load_game($1)
    when 'read'
        socket_handler
    else
        command_handler( cgi['text'].downcase )
    end
}
