require 'bundler'
require "pry"
Bundler.require

module Concerns
  module Findable
    def find_by_name(obj_name)
        self.all.detect{|object|object.name == obj_name}
    end
    def find_or_create_by_name(name)
        self.find_by_name(name) ? self.find_by_name(name) : self.create(name)
    end
  end
end
class Artist
  extend Concerns::Findable
end
class Genre
  extend Concerns::Findable
end

class Song
  extend Concerns::Findable
end

require_all 'lib'

class Song
  @@all = []
  attr_accessor :name
  attr_reader :artist, :genre
  def initialize(name, artist = nil, genre = nil)
    @name = name
    self.artist = artist if artist
    self.genre = genre if genre
  end
  def self.all
    @@all
  end
  def self.destroy_all
    @@all.clear
  end
  def save
    @@all << self
  end
  def self.create(name)
    new_song = Song.new(name)
    new_song.save
    new_song
  end

  def artist=(artist)
    @artist = artist
    @artist.add_song(self)
  end

  def genre=(genre)
      @genre = genre
      genre.songs << self if not genre.songs.include?(self)
  end

  def self.new_from_filename(filename)
    names = filename.split(" - ")
    new_song = Song.find_or_create_by_name(names[1])
    new_song.artist = Artist.find_or_create_by_name(names[0])
    new_song.genre = Genre.find_or_create_by_name(names[2].split(".")[0])
    new_song
  end
  def self.create_from_filename(filename)
    self.new_from_filename(filename)
  end
end

class Artist
  @@all = []
  attr_accessor :name, :songs
  def initialize(name)
    @name = name
    @songs = []
  end
  def self.all
    @@all
  end
  def self.destroy_all
    @@all.clear
  end
  def save
    @@all << self
  end
  def self.create(name)
    new_artist = self.new(name)
    new_artist.save
    new_artist
  end
  def add_song(song)
    song.artist ? nil : song.artist = self
    self.songs.include?(song) ? nil : self.songs << song
  end

  def genres
    self.songs.collect{|song|song.genre}.uniq
  end
end

class Genre
  @@all = []
  attr_accessor :name
  attr_reader :songs
  def initialize(name)
    @name = name
    @songs = []
  end

  def self.all
    @@all
  end

  def self.destroy_all
    @@all.clear
  end

  def save
    @@all << self
  end

  def self.create(genre)
    new_genre = self.new(genre)
    new_genre.save
    new_genre
  end

  def artists
    self.songs.collect{|song|song.artist}.uniq
  end
end

class MusicImporter
  @@all = []
  def initialize(path)
    @path = path
  end
  def path
    @path
  end

  def files
    Dir.entries(path).select { |entries|  entries.size > 4}
    # binding.pry
  end
  def import
    files.map { |info|Song.create_from_filename(info)}
    # binding.pry
  end
end

class MusicLibraryController

  def initialize(path = './db/mp3s')
    @path = path
    @new_lib = MusicImporter.new(@path)
    @lib = @new_lib.import
  end
  def call
    input = nil
    until input == "exit"
      puts "Welcome to your music library!"
      puts "To list all of your songs, enter 'list songs'."
      puts "To list all of the artists in your library, enter 'list artists'."
      puts "To list all of the genres in your library, enter 'list genres'."
      puts "To list all of the songs by a particular artist, enter 'list artist'."
      puts "To list all of the songs of a particular genre, enter 'list genre'."
      puts "To play a song, enter 'play song'."
      puts "To quit, type 'exit'."
      puts "What would you like to do?"
      input = gets.chomp
    end
  end

  def list_songs
    list = Song.all.sort_by {|obj| obj.name}
    list.each_with_index{|v,i|puts "#{i+1}. #{v.artist.name} - #{v.name} - #{v.genre.name}"}
  end
  def list_artists
    list = Artist.all.sort_by {|obj| obj.name}
    list.each_with_index{|v,i|puts "#{i+1}. #{v.name}"}
  end

  def list_genres
    list = Genre.all.sort_by {|obj| obj.name}
    list.each_with_index{|v,i|puts "#{i+1}. #{v.name}"}
  end

  def list_songs_by_artist
    puts "Please enter the name of an artist:"
    choice = gets.chomp
    choice = choice.split.map(&:capitalize).join(' ')
    Artist.all.each_with_index do |val|
      if val.name == choice
        val.songs.sort_by {|obj| obj.name}.each_with_index do |value, index|
          puts "#{index+1}. #{value.name} - #{value.genre.name}"
        end
      end
    end
  end

  def list_songs_by_genre
    puts "Please enter the name of a genre:"
    choice = gets.chomp
    Genre.all.each_with_index do |val|
      if val.name == choice
        val.songs.each_with_index do |value, index|
          puts "#{index+1}. #{value.artist.name} - #{value.name}"
        end
      end
    end
  end

  def play_song
    puts "Which song number would you like to play?"
    choice = gets.chomp.to_i
    songs =  Song.all.sort_by {|obj| obj.name}
    # binding.pry
    if choice < songs.size+1 && choice > 0
      puts "Playing #{songs[choice-1].name} by #{songs[choice-1].artist.name}"
    end

  end


end
