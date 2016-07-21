class JsonPathV2
  class Proxy
    attr_reader :obj
    alias_method :to_hash, :obj

    def initialize(obj)
      @obj = obj
    end

    def gsub(path, replacement = nil, &replacement_block)
      _gsub(_deep_copy, path, replacement ? proc { replacement } : replacement_block)
    end

    def gsub!(path, replacement = nil, &replacement_block)
      _gsub(@obj, path, replacement ? proc { replacement } : replacement_block)
    end

    def delete(path = JsonPathV2::PATH_ALL)
      _delete(_deep_copy, path)
    end

    def delete!(path = JsonPathV2::PATH_ALL)
      _delete(@obj, path)
    end

    def compact(path = JsonPathV2::PATH_ALL)
      _compact(_deep_copy, path)
    end

    def compact!(path = JsonPathV2::PATH_ALL)
      _compact(@obj, path)
    end

    private

    def _deep_copy
      Marshal.load(Marshal.dump(@obj))
    end

    def _gsub(obj, path, replacement)
      JsonPathV2.new(path)[obj, :substitute].each(&replacement)
      Proxy.new(obj)
    end

    def _delete(obj, path)
      JsonPathV2.new(path)[obj, :delete].each
      Proxy.new(obj)
    end

    def _compact(obj, path)
      JsonPathV2.new(path)[obj, :compact].each
      Proxy.new(obj)
    end
  end
end
