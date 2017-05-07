if not String.method_defined? :force_encoding
  class String
    def force_encoding(*args)
    end
  end
end

class Array
  if ![].respond_to? :to_h
    def to_h
      Hash[*self.flatten(1)]
    end
  end

  def to_sym
    collect { |v| v.to_sym }
  end

  def to_sym!
    self.replace(to_sym())
  end

  def to_frontend(arg = nil)
    collect { |a| a.to_frontend(arg) }.sort { |a, b| a[1]<=>b[1] }
  end

  def to_s
    "[#{join(',')}]"
  end
end

class Object
  def to_frontend(_ = nil)
    to_s
  end
end

# Converts all keys of a hash to syms recursively
class Hash
  def to_sym
    ret = {}
    each { |k, v|
      ret[k.to_sym] = v.class == Hash ? v.to_sym : v
    }
    ret
  end

  def to_sym!
    self.replace(to_sym())
  end

  def method_missing(s, *args)
    dputs(4) { "Method is missing: #{s.inspect}" }

    case s.to_s
      when 'to_ary'
        super(s, args)
      when /^_.*[^=]$/
        key = s.to_s.sub(/^_{1,2}/, '').to_sym
        dputs(4) { "Searching for #{s.inspect} -> #{key}" }
        self.class.class_eval <<-RUBY
          def _#{key}(ret = nil)
          self.has_key? :#{key} and return self[:#{key}]
            self.has_key? '#{key}' and return self['#{key}']
            ret ? (self[:#{key}] = {}) : nil
          end

          def __#{key}
            _#{key}(true)
          end
        RUBY
        self.send(s)
      when /^_.*=$/
        key = /^_{1,2}(.*)=$/.match(s.to_s)[1].to_sym
        dputs(4) { "Setting #{s.inspect} -> #{key} to #{args.inspect}" }
        self.has_key? key and return self[key] = args[0]
        self.has_key? key.to_s and return self[key.to_s] = args[0]
        return self[key] = args[0]
      else
        super(s, args)
    end
  end

  #  def to_s
  #    "{#{each{|k,v| k.to_s + ':' + v.to_s + ' '}}}"
  #  end
end


class String
  def pluralize_simple
    case self
      when /y$/
        return self.sub(/y$/, 'ies')
      when /us$/
        return self.sub(/us$/, 'i')
      when /ss$/
        return "#{self}es"
      when /s$/
        return self
      when /man$/
        return self.sub(/an$/, 'men')
      else
        return "#{self}s"
    end
  end

  def to_a
    [self]
  end

  def date_from_web
    Date.from_web(self)
  end

  def cut(reg)
    sub(reg, '')
  end

  def nonempty
    length > 0 ? self : nil
  end
end

class Date
  def to_web
    strftime('%d.%m.%Y')
  end

  def self.from_web(d)
    Date.strptime(d, '%d.%m.%Y')
  end

  def self.from_db(d)
    (d.class == String) ? Date.strptime(d, '%Y-%m-%d') : d
  end
end

class Integer
  def separator(sep = ' ')
    self.to_s.tap do |s|
      :go while s.gsub!(/^([^.]*)(\d)(?=(\d{3})+)/, "\\1\\2#{sep}")
    end
  end

  def to_MB(label = 'MB')
    "#{(self / 1_000_000).separator} #{label}"
  end
end
