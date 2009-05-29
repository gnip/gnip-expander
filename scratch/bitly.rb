
  option('--bitly-username'){
    description 'you bitly username - default from ~/bitly.yml'
    argument :required
  }

  option('--bitly-apikey'){
    description 'you bitly apikey - default from ~/bitly.yml'
    argument :required
  }

  def initialize_bitly
    config =
      begin
        configpath = File.join(Program.home, '.bitly.yml')
        YAML.load(IO.read(configpath))
      rescue
        Hash.new
      end
    param = params['bitly-username']
    username = param.given ? param.value : config['username']
    param = params['bitly-apikey']
    apikey = param.given ? param.value : config['apikey']
    @bitly = Bitly.new(username, apikey)
    abort 'bad bitly config or severed network' unless ping_bitly
  end

  def ping_bitly
    begin
      @bitly.shorten('http://www.google.com')
      true
    rescue Object
      false
    end
  end

  begin
    require 'bitly'
  rescue LoadError
    abort "sudo gem install philnash-bitly --source=http://gems.github.com"
  end

require 'rubygems'
require 'bitly'

class BitlyCache
  Mb = 2*20
  Max = 1 * Mb

  def initialize bitly, options = {}
    @cache = Hash.new
    @bitly = bitly
    @max = Integer(options[:max]||options['max']||Max)
  end

  def expand uri
    uri = uri.to_s
    record = @cache[uri]
    if record
      record.hits += 1
      record.expanded
    else
      expanded = @bitly.expand(uri)
      @cache[uri] = Record[uri, expanded, hits=0, at=Time.now]
      expanded
    end
  ensure
    manage_cache
  end

  Record = Struct.new(:uri, :expanded, :hits, :at)

  def manage_cache
    if @cache.size > Max
      records = @cache.values.sort_by{|record| [record.hits, record.at]}
      until @cache.size < Max
        record = records.shift
        @cache.delete(record.uri)
      end
    end
  end
end

bitly = Bitly.new('drawohara', 'R_3c855a9c774b0503124ac66f6de70ad4')
shortened = bitly.shorten('http://google.com')
p shortened
p shortened.short_url
cache = BitlyCache.new(bitly)

url = shortened.short_url
p cache.expand(url).long_url
p cache.expand(url).long_url
p cache.expand(url).long_url
p cache.expand(url).long_url
