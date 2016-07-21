require 'strscan'
require 'multi_json'
require 'jsonpathv2/proxy'
require 'jsonpathv2/enumerable'
require 'jsonpathv2/version'

class JsonPathV2
  PATH_ALL = '$..*'.freeze

  attr_accessor :path

  def initialize(path, opts = nil)
    @opts = opts
    scanner = StringScanner.new(path)
    @path = []
    until scanner.eos?
      if token = scanner.scan(/\$|@|\*|\.\./)
        @path << token
      elsif token = scanner.scan(/[a-zA-Z0-9_-]+/)
        @path << "['#{token}']"
      elsif token = scanner.scan(/'(.*?)'/)
        @path << "[#{token}]"
      elsif token = scanner.scan(/\[/)
        @path << find_matching_brackets(token, scanner)
      elsif token = scanner.scan(/\]/)
        raise ArgumentError, 'unmatched closing bracket'
      elsif scanner.scan(/\./)
        nil
      elsif token = scanner.scan(/[><=] \d+/)
        @path.last << token
      elsif token = scanner.scan(/./)
        @path.last << token
      end
    end
  end

  def find_matching_brackets(token, scanner)
    count = 1
    until count.zero?
      if t = scanner.scan(/\[/)
        token << t
        count += 1
      elsif t = scanner.scan(/\]/)
        token << t
        count -= 1
      elsif t = scanner.scan(/[^\[\]]+/)
        token << t
      elsif scanner.eos?
        raise ArgumentError, 'unclosed bracket'
      end
    end
    token
  end

  def join(join_path)
    res = deep_clone
    res.path += JsonPathV2.new(join_path).path
    res
  end

  def on(obj_or_str)
    enum_on(obj_or_str).to_a
  end

  def first(obj_or_str, *args)
    enum_on(obj_or_str).first(*args)
  end

  def enum_on(obj_or_str, mode = nil)
    JsonPathV2::Enumerable.new(self, self.class.process_object(obj_or_str), mode,
                             @opts)
  end
  alias_method :[], :enum_on

  def self.on(obj_or_str, path, opts = nil)
    new(path, opts).on(process_object(obj_or_str))
  end

  def self.for(obj_or_str)
    Proxy.new(process_object(obj_or_str))
  end

  private

  def self.process_object(obj_or_str)
    obj_or_str.is_a?(String) ? MultiJson.decode(obj_or_str) : obj_or_str
  end

  def deep_clone
    Marshal.load Marshal.dump(self)
  end
end
